/*
 * Alien Breed 3D I - PC Port
 * movement.c - Object movement, collision, and physics (full implementation)
 *
 * Translated from: ObjectMove.s, Fall.s
 */

#include "movement.h"
#include "game_data.h"
#include "math_tables.h"
#include <string.h>
#include <stdlib.h>
#include <math.h>

/* -----------------------------------------------------------------------
 * Constants from the original code
 * ----------------------------------------------------------------------- */
#define GRAVITY_ACCEL       256     /* gravity per frame (Fall.s: add.l #256,d2) */
#define GRAVITY_DECEL       512     /* ground decel (Fall.s: sub.l #512,d2) */
#define WATER_MAX_VELOCITY  512     /* max fall speed in water */

/* Floor line structure offsets (from Defs.i / raw data analysis):
 * 0:  int16  x1         - start X
 * 2:  int16  z1         - start Z
 * 4:  int16  xlen       - X length (direction * scale)
 * 6:  int16  zlen       - Z length (direction * scale)
 * 8:  int16  connected_zone  - zone on other side (-1 = solid wall)
 * 10: int16  line_length     - magnitude of direction vector
 * 12: int16  normal_or_angle - precomputed value
 * 14: int8   awayfromwall_shift
 * 15: int8   reserved
 * Total: 16 bytes per floor line
 */
#define FLINE_SIZE      16
#define FLINE_X         0
#define FLINE_Z         2
#define FLINE_XLEN      4
#define FLINE_ZLEN      6
#define FLINE_CONNECT   8
#define FLINE_LENGTH    10
#define FLINE_NORMAL    12
#define FLINE_AWAY      14

/* Zone data offsets */
#define ZONE_FLOOR_HEIGHT       2
#define ZONE_ROOF_HEIGHT        6
#define ZONE_UPPER_FLOOR        10
#define ZONE_UPPER_ROOF         14
#define ZONE_EXIT_LIST          32
#define ZONE_WALL_LIST          28

/* -----------------------------------------------------------------------
 * Helper: read big-endian int16 from level data
 * ----------------------------------------------------------------------- */
static int16_t read_be16(const uint8_t *p)
{
    return (int16_t)((p[0] << 8) | p[1]);
}

static int32_t read_be32(const uint8_t *p)
{
    return (int32_t)((p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3]);
}

/* -----------------------------------------------------------------------
 * Helper: Newton-Raphson square root (from ObjectMove.s CalcDist)
 *
 * The original uses 3 iterations of Newton-Raphson:
 *   guess = (dx+dz)/2  (initial)
 *   guess = (guess + (dx*dx + dz*dz)/guess) / 2  (iterate 3x)
 * ----------------------------------------------------------------------- */
static int32_t newton_sqrt(int32_t dx, int32_t dz)
{
    if (dx < 0) dx = -dx;
    if (dz < 0) dz = -dz;

    if (dx == 0 && dz == 0) return 0;

    /* Initial guess */
    int32_t guess = (dx + dz) / 2;
    if (guess == 0) guess = 1;

    /* Sum of squares */
    int64_t sum_sq = (int64_t)dx * dx + (int64_t)dz * dz;

    /* 3 iterations */
    for (int i = 0; i < 3; i++) {
        if (guess == 0) break;
        guess = (int32_t)((guess + sum_sq / guess) / 2);
    }

    return guess;
}

/* -----------------------------------------------------------------------
 * move_context_init
 * ----------------------------------------------------------------------- */
void move_context_init(MoveContext *ctx)
{
    memset(ctx, 0, sizeof(*ctx));
    ctx->extlen = 40;
    ctx->step_up_val = 40 * 256;
    ctx->step_down_val = 0x1000000;
    ctx->coll_id = -1;
}

/* -----------------------------------------------------------------------
 * player_fall - Gravity physics
 *
 * Translated directly from Fall.s Plr1Fall.
 * ----------------------------------------------------------------------- */
void player_fall(int32_t *yoff, int32_t *yvel, int32_t tyoff,
                 int32_t water_level, bool in_water)
{
    int32_t d0 = tyoff - *yoff;
    int32_t d1 = *yoff;
    int32_t d2 = *yvel;

    if (d0 > 0) {
        /* Above ground - falling */
        d1 += d2;
        d2 += GRAVITY_ACCEL;

        if (in_water && d1 >= water_level) {
            if (d2 > WATER_MAX_VELOCITY) {
                d2 = WATER_MAX_VELOCITY;
            }
        }
    } else {
        /* At or below ground */
        d2 -= GRAVITY_DECEL;
        if (d2 < 0) {
            d2 = 0;
        }

        d1 += d2;
        d0 = tyoff - d1;

        if (d0 > 0) {
            d2 = 0;
            d1 += d0;
        }
    }

    *yvel = d2;
    *yoff = d1;
}

/* -----------------------------------------------------------------------
 * move_object - Move object through level geometry
 *
 * Translated from ObjectMove.s MoveObject (line ~21-998).
 *
 * Full algorithm:
 * 1. Get current room's wall list and exit list
 * 2. Check movement against each wall line (cross product test)
 * 3. For exit lines: check if passable, transition rooms
 * 4. For wall lines: collision response (slide along wall)
 * 5. Handle step-up/step-down at room transitions
 * ----------------------------------------------------------------------- */
/* -----------------------------------------------------------------------
 * Wall slide + bounds check
 *
 * Translated from ObjectMove.s:
 *   calcalong  (lines ~300-317) - slide computation
 *   othercheck (lines ~357-448) - segment bounds validation
 *   hitthewall (lines ~450-457) - accept and write result
 *
 * The Amiga ONLY writes the wall-slid position if the slide point falls
 * within the wall segment (±4 unit tolerance on the dominant axis).
 * Without this bounds check, crossings at the virtual extension of wall
 * lines cause false wall hits that eat up player movement ("treacle").
 *
 * Returns true if wall hit accepted, false if slide was outside segment.
 * ----------------------------------------------------------------------- */
static bool do_wall_slide(MoveContext *ctx, const uint8_t *fline,
                           int16_t lxlen, int16_t lzlen,
                           int32_t xdiff, int32_t zdiff,
                           int64_t new_cross, int ps)
{
    int32_t lx = (int32_t)(int16_t)read_be16(fline + FLINE_X) << ps;
    int32_t lz = (int32_t)(int16_t)read_be16(fline + FLINE_Z) << ps;

    if (ctx->wallbounce) {
        ctx->newx = ctx->oldx;
        ctx->newz = ctx->oldz;
        return true;
    }

    /* Compute slide position: project movement onto wall direction.
     * Result: old position + component of movement parallel to wall. */
    int32_t slide_x, slide_z;
    int32_t wall_len_sq = (int32_t)lxlen * lxlen + (int32_t)lzlen * lzlen;
    if (wall_len_sq > 0) {
        int64_t dot = (int64_t)xdiff * lxlen + (int64_t)zdiff * lzlen;
        slide_x = ctx->oldx + (int32_t)((dot * lxlen) / wall_len_sq);
        slide_z = ctx->oldz + (int32_t)((dot * lzlen) / wall_len_sq);
    } else {
        slide_x = ctx->oldx;
        slide_z = ctx->oldz;
    }

    /* Push away from wall (only for AI/objects, player has awayfromwall=0) */
    if (ctx->awayfromwall > 0) {
        int8_t away = *(int8_t*)(fline + FLINE_AWAY);
        int32_t push_x, push_z;
        if (ps > away) {
            push_x = (int32_t)lzlen << (ps - away);
            push_z = (int32_t)lxlen << (ps - away);
        } else {
            push_x = (int32_t)lzlen >> (away - ps);
            push_z = (int32_t)lxlen >> (away - ps);
        }
        if (new_cross > 0) {
            slide_x -= push_x;
            slide_z += push_z;
        } else {
            slide_x += push_x;
            slide_z -= push_z;
        }
    }

    /* ---- Segment bounds check (Amiga othercheck, lines ~387-448) ----
     * Verify the slide position is within the wall line segment.
     * Compare on the dominant axis with ±4 integer-unit tolerance.
     * If outside, the wall crossing is spurious (at the virtual extension
     * of the line) and should be SKIPPED. */
    {
        int16_t rel_x = (int16_t)((slide_x - lx) >> ps);
        int16_t rel_z = (int16_t)((slide_z - lz) >> ps);
        int16_t ax = lxlen >= 0 ? lxlen : -lxlen;
        int16_t az = lzlen >= 0 ? lzlen : -lzlen;

        if (az > ax) {
            /* Z is the dominant axis */
            if (rel_z > 0) {
                if (lzlen < -4)          return false;
                if (rel_z > lzlen + 4)   return false;
            } else {
                if (lzlen > 4)           return false;
                if (rel_z < lzlen - 4)   return false;
            }
        } else {
            /* X is the dominant axis */
            if (rel_x > 0) {
                if (lxlen < -4)          return false;
                if (rel_x > lxlen + 4)   return false;
            } else {
                if (lxlen > 4)           return false;
                if (rel_x < lxlen - 4)   return false;
            }
        }
    }

    /* Bounds check passed - accept the slide */
    ctx->newx = slide_x;
    ctx->newz = slide_z;
    return true;
}

void move_object(MoveContext *ctx, LevelState *level)
{
    if (!level->data || !level->floor_lines || !level->zone_adds) {
        ctx->hitwall = 0;
        return;
    }

    ctx->hitwall = 0;

    if (!ctx->objroom) return;

    const uint8_t *zone_data = ctx->objroom;

    /* pos_shift: 0 = integer positions (AI/objects), 16 = 16.16 fixed-point (player).
     * Floor line coordinates are 16-bit integers; shift them up to match. */
    int ps = ctx->pos_shift;

    int32_t xdiff = ctx->newx - ctx->oldx;
    int32_t zdiff = ctx->newz - ctx->oldz;

    if (xdiff == 0 && zdiff == 0) return;

    /* The Amiga MoveObject checks exit lines then wall lines, restarting
     * from the new zone's lists after each successful transition.
     * After a wall slide, the Amiga CONTINUES checking remaining walls
     * (bra checkwalls) rather than returning.  This is critical for
     * handling wall corners and preventing position ping-pong. */
    int total_iterations = 0;
    const int max_total = 200;

restart_check:
    if (total_iterations >= max_total) goto done;

    /* --- Check EXIT list (lines with connected zones) --- */
    {
        int16_t exit_rel = read_be16(zone_data + ZONE_EXIT_LIST);
        if (exit_rel != 0) {
            const uint8_t *exit_list = zone_data + exit_rel;
            for (int i = 0; i < 100; i++, total_iterations++) {
                int16_t line_idx = read_be16(exit_list + i * 2);
                if (line_idx < 0) break;

                const uint8_t *fline = level->floor_lines + line_idx * FLINE_SIZE;

                int32_t lx = (int32_t)(int16_t)read_be16(fline + FLINE_X) << ps;
                int32_t lz = (int32_t)(int16_t)read_be16(fline + FLINE_Z) << ps;
                int16_t lxlen = (int16_t)read_be16(fline + FLINE_XLEN);
                int16_t lzlen = (int16_t)read_be16(fline + FLINE_ZLEN);
                int16_t connect = (int16_t)read_be16(fline + FLINE_CONNECT);

                int64_t new_cross = (int64_t)(ctx->newx - lx) * lzlen -
                                    (int64_t)(ctx->newz - lz) * lxlen;
                int64_t old_cross = (int64_t)(ctx->oldx - lx) * lzlen -
                                    (int64_t)(ctx->oldz - lz) * lxlen;

                if ((new_cross ^ old_cross) < 0) {
                    /* Crossed this exit line */

                    if (connect >= 0) {
                        int32_t target_zone_off = read_be32(level->zone_adds + connect * 4);
                        const uint8_t *target_zone = level->data + target_zone_off;

                        int32_t target_floor = read_be32(target_zone + ZONE_FLOOR_HEIGHT);
                        int32_t target_roof  = read_be32(target_zone + ZONE_ROOF_HEIGHT);
                        int32_t our_floor    = read_be32(zone_data + ZONE_FLOOR_HEIGHT);

                        /* Step-up check */
                        int32_t floor_diff = target_floor - our_floor;
                        if (floor_diff < 0) floor_diff = -floor_diff;

                        if (floor_diff <= ctx->step_up_val) {
                            /* Height clearance check.
                             * Y-down coordinate system: floor > roof numerically.
                             * Clearance = floor - roof (positive value). */
                            int32_t clearance = target_floor - target_roof;
                            if (clearance >= ctx->thing_height || ctx->thing_height == 0) {
                                /* Passable - transition to new room */
                                ctx->objroom = (uint8_t*)(level->data + target_zone_off);

                                /* Amiga ObjectMove.s line ~972:
                                 *   cmp.l  LowerRoofHeight,d4
                                 *   slt    StoodInTop
                                 * If the player's Y at the crossing point is ABOVE
                                 * (more negative than) the target zone's roof, they
                                 * are in the upper section of a split-level room. */
                                ctx->stood_in_top = (ctx->newy < target_roof) ? 1 : 0;

                                /* Restart with the NEW zone's exit/wall lists
                                 * (Amiga: branches back to .notalinemove) */
                                zone_data = target_zone;
                                goto restart_check;
                            }
                        }

                        /* Can't pass through - treat as wall and slide */
                    }

                    /* Wall collision - slide along the line.
                     * do_wall_slide returns false if the slide point falls
                     * outside the wall segment (Amiga othercheck).
                     * After sliding, CONTINUE checking remaining walls
                     * (Amiga: hitthewall -> bra checkwalls). */
                    if (do_wall_slide(ctx, fline, lxlen, lzlen, xdiff, zdiff,
                                      new_cross, ps)) {
                        ctx->hitwall = 1;
                        xdiff = ctx->newx - ctx->oldx;
                        zdiff = ctx->newz - ctx->oldz;
                    }
                    continue;
                }
            }
        }
    }

    /* --- Check WALL list (solid walls, no connected zone) --- */
    {
        int16_t wall_rel = read_be16(zone_data + ZONE_WALL_LIST);
        if (wall_rel != 0) {
            const uint8_t *wall_list = zone_data + wall_rel;
            for (int i = 0; i < 100; i++, total_iterations++) {
                int16_t line_idx = read_be16(wall_list + i * 2);
                if (line_idx < 0) break;

                const uint8_t *fline = level->floor_lines + line_idx * FLINE_SIZE;

                int32_t lx = (int32_t)(int16_t)read_be16(fline + FLINE_X) << ps;
                int32_t lz = (int32_t)(int16_t)read_be16(fline + FLINE_Z) << ps;
                int16_t lxlen = (int16_t)read_be16(fline + FLINE_XLEN);
                int16_t lzlen = (int16_t)read_be16(fline + FLINE_ZLEN);

                int64_t new_cross = (int64_t)(ctx->newx - lx) * lzlen -
                                    (int64_t)(ctx->newz - lz) * lxlen;
                int64_t old_cross = (int64_t)(ctx->oldx - lx) * lzlen -
                                    (int64_t)(ctx->oldz - lz) * lxlen;

                if ((new_cross ^ old_cross) < 0) {
                    /* Crossed a solid wall - slide, then continue checking.
                     * (Amiga: hitthewall -> bra checkwalls) */
                    if (do_wall_slide(ctx, fline, lxlen, lzlen, xdiff, zdiff,
                                      new_cross, ps)) {
                        ctx->hitwall = 1;
                        xdiff = ctx->newx - ctx->oldx;
                        zdiff = ctx->newz - ctx->oldz;
                    }
                    continue;
                }
            }
        }
    }

done:
    return; /* No collision, or wall slide already applied */
}

/* -----------------------------------------------------------------------
 * collision_check - Object-to-object collision
 *
 * Translated from ObjectMove.s Collision (line ~1839-1943).
 * ----------------------------------------------------------------------- */
void collision_check(MoveContext *ctx, LevelState *level)
{
    ctx->hitwall = 0;

    if (!level->object_data) return;

    int obj_index = 0;
    while (1) {
        GameObject *obj = (GameObject *)(level->object_data + obj_index * OBJECT_SIZE);

        /* End of list */
        if (OBJ_CID(obj) < 0) break;

        /* Skip self */
        if (OBJ_CID(obj) == ctx->coll_id && ctx->coll_id >= 0) {
            obj_index++;
            continue;
        }

        /* Skip dead/inactive objects */
        if (OBJ_ZONE(obj) < 0) {
            obj_index++;
            continue;
        }

        /* Check collide flags bitmask */
        int obj_type = obj->obj.number;
        if (obj_type < 0 || obj_type > 20) {
            obj_index++;
            continue;
        }

        uint32_t type_bit = 1u << obj_type;
        if (!(ctx->collide_flags & type_bit)) {
            obj_index++;
            continue;
        }

        /* Check same floor layer */
        if (ctx->stood_in_top != obj->obj.in_top) {
            obj_index++;
            continue;
        }

        /* Get object position */
        int16_t ox = 0, oz = 0;
        if (level->object_points) {
            const uint8_t *p = level->object_points + obj_index * 8;
            ox = obj_w(p);
            oz = obj_w(p + 4);
        }

        /* Get collision box */
        const CollisionBox *box = &col_box_table[obj_type];

        /* Manhattan distance check first (fast reject) */
        int32_t dx = ctx->newx - ox;
        int32_t dz = ctx->newz - oz;
        if (dx < 0) dx = -dx;
        if (dz < 0) dz = -dz;

        /* Y-axis height check (ObjectMove.s lines ~1887-1893):
         * Uses the mover's full vertical extent [newy, newy+thingheight]
         * and the object's vertical extent [obj_y - half_h, obj_y + half_h].
         * Collision only if these ranges overlap. */
        {
            int16_t obj_y = (int16_t)((obj->raw[4] << 8) | obj->raw[5]);
            int16_t mover_bot = (int16_t)(ctx->newy >> 7);
            int16_t mover_top = (int16_t)((ctx->newy + ctx->thing_height) >> 7);

            int16_t obj_bot = obj_y - box->half_height;
            int16_t obj_top = obj_y + box->half_height;

            if (mover_top < obj_bot || mover_bot > obj_top) {
                obj_index++;
                continue;
            }
        }

        /* Manhattan / box distance check (ObjectMove.s lines ~1895-1918).
         * The Amiga checks max(|dx|,|dz|) against target box width. */
        if (dx < box->width && dz < box->width) {

            /* "Moving closer" check (ObjectMove.s lines ~1920-1935):
             * Only trigger collision if the mover is getting closer to
             * (or maintaining distance from) the object.  This is critical:
             * without it the player gets permanently trapped inside any
             * collision box because the position reverts every frame. */
            int32_t new_dx = (int32_t)ox - ctx->newx;
            int32_t new_dz = (int32_t)oz - ctx->newz;
            int32_t new_dist_sq = new_dx * new_dx + new_dz * new_dz;

            int32_t old_dx = (int32_t)ox - ctx->oldx;
            int32_t old_dz = (int32_t)oz - ctx->oldz;
            int32_t old_dist_sq = old_dx * old_dx + old_dz * old_dz;

            if (new_dist_sq > old_dist_sq) {
                /* Moving away from this object - allow the movement */
                obj_index++;
                continue;
            }

            ctx->hitwall = 1;
            return;
        }

        obj_index++;
    }
}

/* -----------------------------------------------------------------------
 * head_towards - Move toward a target point
 *
 * Translated from ObjectMove.s HeadTowards (line ~1044-1135).
 * Uses Newton-Raphson sqrt for distance calculation.
 * ----------------------------------------------------------------------- */
void head_towards(MoveContext *ctx, int32_t target_x, int32_t target_z,
                  int16_t speed)
{
    int32_t dx = target_x - ctx->oldx;
    int32_t dz = target_z - ctx->oldz;
    int32_t dist = newton_sqrt(dx, dz);

    if (dist == 0) {
        ctx->newx = ctx->oldx;
        ctx->newz = ctx->oldz;
        return;
    }

    /* Check if within range */
    if (dist <= speed) {
        ctx->newx = target_x;
        ctx->newz = target_z;
        return;
    }

    /* Scale movement vector to speed */
    ctx->newx = ctx->oldx + (dx * speed) / dist;
    ctx->newz = ctx->oldz + (dz * speed) / dist;
}

/* -----------------------------------------------------------------------
 * head_towards_angle - Steer facing toward target and move forward
 *
 * Translated from ObjectMove.s HeadTowardsAng (line ~1199-1366).
 *
 * 1. Calculate distance to target using Newton-Raphson
 * 2. Calculate desired angle using binary search on SineTable
 * 3. Steer facing toward desired angle (limited by turn_speed)
 * 4. Move forward in facing direction at speed
 * 5. Apply player push forces (shove system)
 * ----------------------------------------------------------------------- */
void head_towards_angle(MoveContext *ctx, int16_t *facing,
                        int32_t target_x, int32_t target_z,
                        int16_t speed, int16_t turn_speed)
{
    int32_t dx = target_x - ctx->oldx;
    int32_t dz = target_z - ctx->oldz;

    if (dx == 0 && dz == 0) return;

    /* Calculate target angle using atan2 approximation
     * Original uses binary search on SineTable, but atan2 is equivalent */
    double angle_rad = atan2((double)-dx, (double)-dz);
    int16_t target_angle = (int16_t)(angle_rad * (4096.0 / (2.0 * 3.14159265)));
    target_angle = (target_angle * 2) & ANGLE_MASK; /* Convert to byte index */

    /* Calculate angle difference */
    int16_t current = *facing;
    int16_t diff = target_angle - current;

    /* Normalize to [-4096, 4096] */
    while (diff > 4096) diff -= 8192;
    while (diff < -4096) diff += 8192;

    /* Apply turn speed limit */
    if (diff > turn_speed) diff = turn_speed;
    if (diff < -turn_speed) diff = -turn_speed;

    current += diff;
    current &= ANGLE_MASK;
    *facing = current;

    /* Move forward at speed in the facing direction */
    int16_t sin_val = sin_lookup(current);
    int16_t cos_val = cos_lookup(current);

    ctx->newx = ctx->oldx - ((int32_t)sin_val * speed) / 16384;
    ctx->newz = ctx->oldz - ((int32_t)cos_val * speed) / 16384;
}

/* -----------------------------------------------------------------------
 * check_teleport - Zone teleporter check
 *
 * Translated from ObjectMove.s CheckTeleport (line ~2002-2043).
 *
 * Algorithm:
 * 1. Check if zone has ToTelZone >= 0
 * 2. If yes, get destination coordinates (ToTelX, ToTelZ)
 * 3. Adjust Y for floor height difference between zones
 * 4. Check collision at destination
 * 5. If no collision, teleport; update objroom
 * ----------------------------------------------------------------------- */
bool check_teleport(MoveContext *ctx, LevelState *level, int16_t zone_id)
{
    if (!level->data || !level->zone_adds) return false;

    /* Get zone data */
    int32_t zone_off = read_be32(level->zone_adds + zone_id * 4);
    const uint8_t *zone_data = level->data + zone_off;

    /* Check ToTelZone (offset 38 in zone data) */
    int16_t tel_zone = read_be16(zone_data + 38); /* ZONE_OFF_TEL_ZONE */
    if (tel_zone < 0) return false;

    /* Get destination coordinates */
    int16_t tel_x = read_be16(zone_data + 40); /* ZONE_OFF_TEL_X */
    int16_t tel_z = read_be16(zone_data + 42); /* ZONE_OFF_TEL_Z */

    /* Get floor height difference */
    int32_t src_floor = read_be32(zone_data + ZONE_FLOOR_HEIGHT);

    int32_t dest_zone_off = read_be32(level->zone_adds + tel_zone * 4);
    const uint8_t *dest_zone = level->data + dest_zone_off;
    int32_t dest_floor = read_be32(dest_zone + ZONE_FLOOR_HEIGHT);

    int32_t floor_diff = dest_floor - src_floor;

    /* Set new position */
    ctx->newx = tel_x;
    ctx->newz = tel_z;
    ctx->newy += floor_diff;

    /* Check collision at destination */
    uint32_t old_flags = ctx->collide_flags;
    ctx->collide_flags = 0x7FFFF; /* All types */
    collision_check(ctx, level);
    ctx->collide_flags = old_flags;

    if (ctx->hitwall) {
        /* Can't teleport - destination blocked */
        ctx->newy -= floor_diff;
        ctx->hitwall = 0;
        return false;
    }

    /* Teleport successful - update room */
    ctx->objroom = (uint8_t*)(level->data + dest_zone_off);
    return true;
}

/* -----------------------------------------------------------------------
 * find_close_room - Locate the room nearest to a target point
 *
 * Translated from ObjectMove.s FindCloseRoom (line ~2045-2080).
 * Used when an enemy needs to know which room to spawn/die in.
 * ----------------------------------------------------------------------- */
void find_close_room(MoveContext *ctx, LevelState *level, int16_t distance)
{
    /* This function uses HeadTowards to move toward the target,
     * then MoveObject to find which room that point is in.
     * The 'distance' parameter limits how far to search.
     */
    if (!level->data || !level->zone_adds) return;

    /* Just use MoveObject to resolve the room - simplified version */
    ctx->step_up_val = 0x1000000;
    ctx->step_down_val = 0x1000000;
    ctx->thing_height = 0;
    ctx->extlen = 0;
    ctx->exitfirst = 1;

    move_object(ctx, level);

    (void)distance;
}
