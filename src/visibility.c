/*
 * Alien Breed 3D I - PC Port
 * visibility.c - Zone ordering and line-of-sight (full implementation)
 *
 * Translated from: OrderZones.s, AB3DI.s (CanItBeSeen)
 */

#include "visibility.h"
#include "math_tables.h"
#include <string.h>
#include <stdio.h>

/* -----------------------------------------------------------------------
 * Helper: read big-endian values from level data
 * ----------------------------------------------------------------------- */
static int16_t read_be16(const uint8_t *p)
{
    return (int16_t)((p[0] << 8) | p[1]);
}

static int32_t read_be32(const uint8_t *p)
{
    return (int32_t)((p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3]);
}

/* Floor line offsets */
#define FLINE_SIZE  16
#define FLINE_X     0
#define FLINE_Z     2
#define FLINE_XLEN  4
#define FLINE_ZLEN  6
#define FLINE_CONNECT  8   /* connected zone (other side of line) */

/* Zone data offsets */
#define ZONE_FLOOR_HEIGHT   2
#define ZONE_ROOF_HEIGHT    6
#define ZONE_UPPER_FLOOR    10
#define ZONE_UPPER_ROOF     14
#define ZONE_OFF_UPPER_FLOOR 10
#define ZONE_OFF_UPPER_ROOF 14
#define ZONE_EXIT_LIST      32
#define ZONE_LIST_OF_GRAPH  48

/* -----------------------------------------------------------------------
 * order_zones - Traverse ListOfGraphRooms then sort by depth (back-to-front)
 *
 * 1. Traverse: walk ListOfGraphRooms, build list of zone ids to draw (same as Amiga).
 * 2. Sort: assign each zone a depth (max view-space depth over its exit line midpoints),
 *    sort by depth descending so farthest zones are drawn first (painter's).
 * ----------------------------------------------------------------------- */
void order_zones(ZoneOrder *out, const LevelState *level,
                 int32_t viewer_x, int32_t viewer_z,
                 int viewer_angle,
                 const uint8_t *list_of_graph_rooms)
{
    out->count = 0;

    if (!level->data || !level->zone_adds || !level->floor_lines) {
        return;
    }

    uint8_t to_draw_tab[256];
    memset(to_draw_tab, 0, sizeof(to_draw_tab));

    /* Step 1: Traverse ListOfGraphRooms – build zone list (8 bytes per entry: zone_id word, then long) */
    int16_t zone_list[256];
    int num_zones = 0;

    if (list_of_graph_rooms) {
        const uint8_t *lgr = list_of_graph_rooms;
        while (num_zones < MAX_ORDER_ENTRIES) {
            int16_t zone_id = read_be16(lgr);
            if (zone_id < 0) break;
            if (zone_id < 256) {
                to_draw_tab[zone_id] = 1;
                zone_list[num_zones++] = zone_id;
            }
            lgr += 8;
        }
    }
    if (num_zones == 0 && level->num_zones > 0) {
        int n = level->num_zones;
        if (n > 256) n = 256;
        for (int z = 0; z < n; z++) {
            to_draw_tab[z] = 1;
            zone_list[num_zones++] = (int16_t)z;
            if (num_zones >= MAX_ORDER_ENTRIES) break;
        }
    }
    if (num_zones == 0) return;

    /* Step 2: View-space depth per zone = max over exit line midpoints.
     * Depth = (mid_x - viewer_x)*sin + (mid_z - viewer_z)*cos; larger = farther from camera. */
    int16_t sin_v = sin_lookup(viewer_angle);
    int16_t cos_v = cos_lookup(viewer_angle);
    int32_t depths[256];

    for (int i = 0; i < num_zones; i++) {
        int16_t z = zone_list[i];
        int32_t zone_off = read_be32(level->zone_adds + (int)z * 4);
        int32_t max_d = (int32_t)0x80000000;

        if (zone_off == 0) {
            depths[i] = 0;
            continue;
        }
        const uint8_t *zone_data = level->data + zone_off;
        int16_t exit_rel = read_be16(zone_data + ZONE_EXIT_LIST);
        if (exit_rel == 0) {
            depths[i] = 0;
            continue;
        }
        const uint8_t *exit_list = zone_data + exit_rel;

        for (int ei = 0; ei < 64; ei++) {
            int16_t line_idx = read_be16(exit_list + ei * 2);
            if (line_idx < 0) break;

            const uint8_t *fline = level->floor_lines + (int)line_idx * FLINE_SIZE;
            int16_t lx = read_be16(fline + FLINE_X);
            int16_t lz = read_be16(fline + FLINE_Z);
            int16_t lxlen = read_be16(fline + FLINE_XLEN);
            int16_t lzlen = read_be16(fline + FLINE_ZLEN);
            int32_t mid_x = (int32_t)lx + (int32_t)lxlen / 2;
            int32_t mid_z = (int32_t)lz + (int32_t)lzlen / 2;
            int32_t dx = mid_x - viewer_x;
            int32_t dz = mid_z - viewer_z;
            int32_t d = (int32_t)dx * sin_v + (int32_t)dz * cos_v;
            if (d > max_d) max_d = d;
        }
        depths[i] = (max_d == (int32_t)0x80000000) ? 0 : max_d;
    }

    /* Step 3: Sort towards the camera = far to near. Farthest zone first (index 0), nearest last.
     * So sort by depth descending: larger depth = farther = earlier in list = drawn first. */
    for (int i = 1; i < num_zones; i++) {
        int32_t d = depths[i];
        int16_t z = zone_list[i];
        int j = i - 1;
        while (j >= 0 && depths[j] < d) {
            depths[j + 1] = depths[j];
            zone_list[j + 1] = zone_list[j];
            j--;
        }
        depths[j + 1] = d;
        zone_list[j + 1] = z;
    }

    /* Step 4: Output (far to near) */
    for (int i = 0; i < num_zones && i < MAX_ORDER_ENTRIES; i++)
        out->zones[i] = zone_list[i];
    out->count = num_zones;
}

/* -----------------------------------------------------------------------
 * can_it_be_seen - Line-of-sight check
 *
 * Translated from AB3DI.s CanItBeSeen.
 *
 * Algorithm:
 * 1. If same room -> visible
 * 2. Trace line from viewer to target through room graph
 * 3. At each room boundary, check:
 *    a. Does the line cross an exit line?
 *    b. Is there floor/ceiling clearance at the crossing point?
 * 4. If we reach the target's room -> visible
 * 5. If we run out of rooms to check -> not visible
 * ----------------------------------------------------------------------- */
uint8_t can_it_be_seen(const LevelState *level,
                       const uint8_t *from_room, const uint8_t *to_room,
                       int16_t viewer_x, int16_t viewer_z, int16_t viewer_y,
                       int16_t target_x, int16_t target_z, int16_t target_y,
                       int8_t viewer_top, int8_t target_top)
{
    if (!level->data || !level->floor_lines) {
        return 0;
    }

    /* Same room = always visible */
    if (from_room == to_room) {
        return 0x03; /* Both bits set */
    }

    /* Trace through rooms */
    int32_t dy = target_y - viewer_y;

    const uint8_t *current_room = from_room;
    int max_depth = 20; /* Prevent infinite loops */

    for (int depth = 0; depth < max_depth; depth++) {
        if (!current_room) break;

        /* Get exit list for current room (16-bit relative offset) */
        int16_t exit_rel = read_be16(current_room + ZONE_EXIT_LIST);
        if (exit_rel == 0) break;

        const uint8_t *exit_list = current_room + exit_rel;
        bool found_next = false;

        /* Check each exit line */
        for (int i = 0; i < 50; i++) {
            int16_t line_idx = read_be16(exit_list + i * 2);
            if (line_idx < 0) break;

            const uint8_t *fline = level->floor_lines + line_idx * FLINE_SIZE;

            int16_t lx = read_be16(fline + FLINE_X);
            int16_t lz = read_be16(fline + FLINE_Z);
            int16_t lxlen = read_be16(fline + FLINE_XLEN);
            int16_t lzlen = read_be16(fline + FLINE_ZLEN);
            int16_t connect = read_be16(fline + FLINE_CONNECT);

            if (connect < 0) continue;

            /* Check if line from viewer to target crosses this exit */
            int32_t view_cross = (int32_t)((int32_t)viewer_x - lx) * lzlen -
                                 (int32_t)((int32_t)viewer_z - lz) * lxlen;
            int32_t targ_cross = (int32_t)((int32_t)target_x - lx) * lzlen -
                                 (int32_t)((int32_t)target_z - lz) * lxlen;

            /* Signs differ = line crosses */
            if ((view_cross ^ targ_cross) < 0) {
                /* Calculate crossing height */
                int32_t total_cross = view_cross - targ_cross;
                if (total_cross == 0) continue;

                int32_t t = (view_cross * 256) / total_cross; /* 0-256 = 0.0-1.0 */
                int32_t cross_y = viewer_y + (dy * t) / 256;

                /* Get connected zone */
                int32_t zone_off = read_be32(level->zone_adds + connect * 4);
                const uint8_t *next_zone = level->data + zone_off;

                /* Check height clearance (using upper floor if in_top) */
                int32_t floor_h, roof_h;
                if (viewer_top || target_top) {
                    /* Check upper floor */
                    floor_h = read_be32(next_zone + ZONE_OFF_UPPER_FLOOR);
                    roof_h = read_be32(next_zone + ZONE_OFF_UPPER_ROOF);
                } else {
                    floor_h = read_be32(next_zone + ZONE_FLOOR_HEIGHT);
                    roof_h = read_be32(next_zone + ZONE_ROOF_HEIGHT);
                }

                if (cross_y >= floor_h && cross_y <= roof_h) {
                    /* Can pass through */
                    if (next_zone == to_room) {
                        return 0x03; /* Visible! */
                    }
                    current_room = next_zone;
                    found_next = true;
                    break;
                }
            }
        }

        if (!found_next) break;
    }

    return 0; /* Not visible */
}
