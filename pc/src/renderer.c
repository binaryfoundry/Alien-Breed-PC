/*
 * Alien Breed 3D I - PC Port
 * renderer.c - Software 3D renderer (chunky buffer)
 *
 * Translated from: AB3DI.s DrawDisplay (lines 3395-3693),
 *                  WallRoutine3.ChipMem.s, ObjDraw3.ChipRam.s
 *
 * The renderer draws into a flat 8-bit indexed pixel buffer.
 * The buffer is RENDER_STRIDE bytes wide and RENDER_HEIGHT lines tall.
 * Each byte is a palette index (0-31 for game colors).
 *
 * The rendering pipeline:
 *   1. Clear framebuffer
 *   2. Compute view transform (sin/cos from angpos)
 *   3. RotateLevelPts: transform level vertices to view space
 *   4. RotateObjectPts: transform object positions to view space
 *   5. For each zone (back-to-front from OrderZones):
 *      a. Set left/right clip from LEVELCLIPS
 *      b. Determine split (upper/lower room)
 *      c. DoThisRoom: iterate zone graph data, dispatch:
 *         - Walls  -> column-by-column textured drawing
 *         - Floors -> span-based textured drawing
 *         - Objects -> scaled sprite drawing
 *   6. Draw gun overlay
 *   7. Swap buffers
 */

#include "renderer.h"
#include "math_tables.h"
#include "game_data.h"
#include "visibility.h"
#include "stub_audio.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h>

/* -----------------------------------------------------------------------
 * Global renderer state
 * ----------------------------------------------------------------------- */
RendererState g_renderer;

/* -----------------------------------------------------------------------
 * Big-endian read helpers (level data is Amiga big-endian)
 * ----------------------------------------------------------------------- */
static inline int16_t rd16(const uint8_t *p) {
    return (int16_t)((p[0] << 8) | p[1]);
}
static inline int32_t rd32(const uint8_t *p) {
    return (int32_t)((p[0] << 24) | (p[1] << 16) | (p[2] << 8) | p[3]);
}

/* -----------------------------------------------------------------------
 * SCALE table (from Macros.i)
 *
 * Maps Amiga dimming index d6 (0-32) to byte offset into the per-texture
 * 2048-byte brightness LUT.  Each brightness block is 64 bytes (32 words).
 *   d6=0 → offset 0 (dimmest)
 *   d6=32 → offset 1024 (brightest for typical walls)
 * ----------------------------------------------------------------------- */
static const uint16_t wall_scale_table[33] = {
    64*0,  64*1,  64*1,  64*2,  64*2,  64*3,  64*3,  64*4,
    64*4,  64*5,  64*5,  64*6,  64*6,  64*7,  64*7,  64*8,
    64*8,  64*9,  64*9,  64*10, 64*10, 64*11, 64*11, 64*12,
    64*12, 64*13, 64*13, 64*14, 64*14, 64*15, 64*15, 64*16,
    64*16
};

/* -----------------------------------------------------------------------
 * Convert a 12-bit Amiga color word (0x0RGB) to ARGB8888.
 * ----------------------------------------------------------------------- */
static inline uint32_t amiga12_to_argb(uint16_t w)
{
    uint32_t r4 = (w >> 8) & 0xF;
    uint32_t g4 = (w >> 4) & 0xF;
    uint32_t b4 = w & 0xF;
    return 0xFF000000u | (r4 * 0x11u << 16) | (g4 * 0x11u << 8) | (b4 * 0x11u);
}

/* -----------------------------------------------------------------------
 * Initialization / Shutdown
 * ----------------------------------------------------------------------- */
void renderer_init(void)
{
    memset(&g_renderer, 0, sizeof(g_renderer));

    g_renderer.buffer = (uint8_t*)calloc(1, RENDER_BUF_SIZE);
    g_renderer.back_buffer = (uint8_t*)calloc(1, RENDER_BUF_SIZE);

    size_t rgb_size = (size_t)RENDER_WIDTH * RENDER_HEIGHT * sizeof(uint32_t);
    g_renderer.rgb_buffer = (uint32_t*)calloc(1, rgb_size);
    g_renderer.rgb_back_buffer = (uint32_t*)calloc(1, rgb_size);

    /* Default clip region = full screen */
    g_renderer.top_clip = 0;
    g_renderer.bot_clip = RENDER_HEIGHT - 1;
    g_renderer.left_clip = 0;
    g_renderer.right_clip = RENDER_WIDTH;

    printf("[RENDERER] Initialized: %dx%d, stride=%d, buffer=%zuB, rgb=%zuB\n",
           RENDER_WIDTH, RENDER_HEIGHT, RENDER_STRIDE,
           (size_t)RENDER_BUF_SIZE, rgb_size);
}

void renderer_shutdown(void)
{
    free(g_renderer.buffer);
    free(g_renderer.back_buffer);
    free(g_renderer.rgb_buffer);
    free(g_renderer.rgb_back_buffer);
    g_renderer.buffer = NULL;
    g_renderer.back_buffer = NULL;
    g_renderer.rgb_buffer = NULL;
    g_renderer.rgb_back_buffer = NULL;
    printf("[RENDERER] Shutdown\n");
}

void renderer_clear(uint8_t color)
{
    if (g_renderer.buffer) {
        memset(g_renderer.buffer, color, RENDER_BUF_SIZE);
    }
    /* Clear rgb_buffer to opaque black */
    if (g_renderer.rgb_buffer) {
        size_t n = (size_t)RENDER_WIDTH * RENDER_HEIGHT;
        uint32_t *p = g_renderer.rgb_buffer;
        for (size_t i = 0; i < n; i++) p[i] = 0xFF000000u;
    }
}

void renderer_swap(void)
{
    uint8_t *tmp = g_renderer.buffer;
    g_renderer.buffer = g_renderer.back_buffer;
    g_renderer.back_buffer = tmp;

    uint32_t *tmp2 = g_renderer.rgb_buffer;
    g_renderer.rgb_buffer = g_renderer.rgb_back_buffer;
    g_renderer.rgb_back_buffer = tmp2;
}

const uint8_t *renderer_get_buffer(void)
{
    return g_renderer.back_buffer; /* The just-drawn frame */
}

const uint32_t *renderer_get_rgb_buffer(void)
{
    return g_renderer.rgb_back_buffer; /* The just-drawn RGB frame */
}

int renderer_get_width(void)  { return RENDER_WIDTH; }
int renderer_get_height(void) { return RENDER_HEIGHT; }
int renderer_get_stride(void) { return RENDER_STRIDE; }

/* -----------------------------------------------------------------------
 * Pixel writing helpers
 * ----------------------------------------------------------------------- */
static inline void put_pixel(uint8_t *buf, int x, int y, uint8_t color)
{
    if (x >= 0 && x < RENDER_WIDTH && y >= 0 && y < RENDER_HEIGHT) {
        buf[y * RENDER_STRIDE + x] = color;
    }
}

static inline void draw_vline(uint8_t *buf, int x, int y_top, int y_bot,
                               uint8_t color)
{
    if (x < 0 || x >= RENDER_WIDTH) return;
    if (y_top < 0) y_top = 0;
    if (y_bot >= RENDER_HEIGHT) y_bot = RENDER_HEIGHT - 1;
    for (int y = y_top; y <= y_bot; y++) {
        buf[y * RENDER_STRIDE + x] = color;
    }
}

/* -----------------------------------------------------------------------
 * Rotate a single level point
 *
 * Translated from AB3DI.s RotateLevelPts (lines 4087-4166).
 *
 * For each point:
 *   dx = point.x - xoff
 *   dz = point.z - zoff
 *   rotated.x = dx * cos - dz * sin  (scaled, with xwobble added)
 *   rotated.z = dx * sin + dz * cos  (depth)
 *   on_screen.x = rotated.x / rotated.z  (perspective divide)
 * ----------------------------------------------------------------------- */
static void rotate_one_point(RendererState *r, const uint8_t *pts, int idx)
{
    int16_t sin_v = r->sinval;
    int16_t cos_v = r->cosval;
    int16_t cam_x = r->xoff;
    int16_t cam_z = r->zoff;

    int16_t px = rd16(pts + idx * 4);
    int16_t pz = rd16(pts + idx * 4 + 2);

    int16_t dx = (int16_t)(px - cam_x);
    int16_t dz = (int16_t)(pz - cam_z);

    /* Rotation (from ASM):
     * view_x = dx * cos - dz * sin    (d2 = d0*d6 - d1*d6_swapped)
     * view_z = dx * sin + dz * cos    (d1 = d0*d6_swapped + d1*d6) */
    int32_t vx = (int32_t)dx * cos_v - (int32_t)dz * sin_v;
    vx <<= 1;              /* add.l d2,d2 in ASM */
    int16_t vx16 = (int16_t)(vx >> 16);  /* swap d2 */
    int32_t vx_fine = (int32_t)vx16 << 7; /* asl.l #7 */
    vx_fine += r->xwobble;

    int32_t vz = (int32_t)dx * sin_v + (int32_t)dz * cos_v;
    vz <<= 2;              /* asl.l #2 in ASM */
    int16_t vz16 = (int16_t)(vz >> 16);  /* swap d1 */

    r->rotated[idx].x = vx_fine;
    r->rotated[idx].z = (int32_t)vz16;

    /* Project to screen column */
    if (vz16 > 0) {
        int32_t screen_x = (vx_fine / vz16) + (RENDER_WIDTH / 2);
        r->on_screen[idx].screen_x = (int16_t)screen_x;
        r->on_screen[idx].flags = 0;
    } else {
        /* Behind camera */
        r->on_screen[idx].screen_x = (vx_fine > 0) ? RENDER_WIDTH + 100 : -100;
        r->on_screen[idx].flags = 1;
    }
}

/* -----------------------------------------------------------------------
 * RotateLevelPts
 *
 * Translated from AB3DI.s RotateLevelPts (lines 4087-4166).
 *
 * Uses PointsToRotatePtr: a list of 16-bit indices into the Points array,
 * terminated by a negative value. Only the listed points are transformed.
 * This list comes from the current zone data at offset ToZonePts (34).
 * ----------------------------------------------------------------------- */
#define TO_ZONE_PTS_OFFSET 34

void renderer_rotate_level_pts(GameState *state)
{
    RendererState *r = &g_renderer;

    if (!state->level.points) return;
    const uint8_t *pts = state->level.points;

    /* Get the PointsToRotatePtr from the current player's zone data.
     * It's stored as an offset from the room pointer into level data. */
    PlayerState *plr = (state->mode == MODE_SLAVE) ? &state->plr2 : &state->plr1;

    if (plr->roompt > 0 && state->level.data) {
        /* The zone data at roompt+34 (ToZonePts) contains a word offset.
         * Adding that to roompt gives the points-to-rotate list location. */
        const uint8_t *room = state->level.data + plr->roompt;
        int16_t ptr_off = rd16(room + TO_ZONE_PTS_OFFSET);
        const uint8_t *pt_list = room + ptr_off;

        /* Iterate the list of point indices */
        int safety = MAX_POINTS;
        while (safety-- > 0) {
            int16_t idx = rd16(pt_list);
            if (idx < 0) break;
            pt_list += 2;

            if (idx < MAX_POINTS) {
                rotate_one_point(r, pts, idx);
            }
        }
    } else {
        /* Fallback: no room data loaded yet - rotate all points */
        int num_pts = state->level.num_object_points;
        if (num_pts <= 0) return;
        if (num_pts > MAX_POINTS) num_pts = MAX_POINTS;

        for (int i = 0; i < num_pts; i++) {
            rotate_one_point(r, pts, i);
        }
    }
}

/* -----------------------------------------------------------------------
 * RotateObjectPts
 *
 * Translated from AB3DI.s RotateObjectPts (lines 4308-4362).
 *
 * Rotates object (enemy/pickup/bullet) positions from world space
 * to view space for sprite rendering.
 * ----------------------------------------------------------------------- */
void renderer_rotate_object_pts(GameState *state)
{
    RendererState *r = &g_renderer;

    if (!state->level.object_points || !state->level.object_data) return;

    int16_t sin_v = r->sinval;
    int16_t cos_v = r->cosval;
    int16_t cam_x = r->xoff;
    int16_t cam_z = r->zoff;

    int num_pts = state->level.num_object_points;
    if (num_pts <= 0) return;
    if (num_pts > MAX_OBJ_POINTS) num_pts = MAX_OBJ_POINTS;

    const uint8_t *pts = state->level.object_points;
    const uint8_t *obj_data = state->level.object_data;

    for (int i = 0; i < num_pts; i++) {
        /* Check if object exists (zone >= 0) */
        const uint8_t *obj = obj_data + i * OBJECT_SIZE;
        int16_t zone = rd16(obj + 12);
        if (zone < 0) {
            r->obj_rotated[i].x = 0;
            r->obj_rotated[i].z = 0;
            r->obj_rotated[i].x_fine = 0;
            continue;
        }

        int16_t px = rd16(pts + i * 8);
        int16_t pz = rd16(pts + i * 8 + 4);

        int16_t dx = (int16_t)(px - cam_x);
        int16_t dz = (int16_t)(pz - cam_z);

        /* Same rotation as level points */
        int32_t vx = (int32_t)dx * cos_v - (int32_t)dz * sin_v;
        vx <<= 1;
        int16_t vx16 = (int16_t)(vx >> 16);

        int32_t vz = (int32_t)dx * sin_v + (int32_t)dz * cos_v;
        vz <<= 2;
        int16_t vz16 = (int16_t)(vz >> 16);

        int32_t vx_fine = (int32_t)vx16 << 7;
        vx_fine += r->xwobble;

        r->obj_rotated[i].x = vx16;
        r->obj_rotated[i].z = vz16;
        r->obj_rotated[i].x_fine = vx_fine;
    }
}

/* -----------------------------------------------------------------------
 * Wall rendering (column-by-column)
 *
 * Translated from WallRoutine3.ChipMem.s ScreenWallstripdraw.
 *
 * Draws a vertical strip of a textured wall.
 * Parameters:
 *   x         - screen column
 *   y_top     - top of wall on screen
 *   y_bot     - bottom of wall on screen
 *   tex_col   - texture column to sample (0-127)
 *   texture   - pointer to wall pixel data (past 2048-byte LUT header)
 *   amiga_d6  - Amiga dimming index (0-32): 0=dimmest, 32=brightest
 *
 * Uses g_renderer.cur_wall_pal as the per-texture 2048-byte LUT.
 * ----------------------------------------------------------------------- */
static void draw_wall_column(int x, int y_top, int y_bot,
                             int tex_col, const uint8_t *texture,
                             int amiga_d6,
                             uint8_t valand, uint8_t valshift)
{
    uint8_t *buf = g_renderer.buffer;
    uint32_t *rgb = g_renderer.rgb_buffer;
    if (!buf || !rgb) return;
    if (x < g_renderer.left_clip || x >= g_renderer.right_clip) return;

    /* Clip to screen */
    int ct = (y_top < g_renderer.top_clip) ? g_renderer.top_clip : y_top;
    int cb = (y_bot > g_renderer.bot_clip) ? g_renderer.bot_clip : y_bot;
    if (ct > cb) return;

    int wall_height = y_bot - y_top;
    if (wall_height <= 0) return;

    /* Clamp d6 to SCALE table range */
    if (amiga_d6 < 0) amiga_d6 = 0;
    if (amiga_d6 > 32) amiga_d6 = 32;

    /* Get the brightness block offset from the SCALE table */
    uint16_t lut_block_off = wall_scale_table[amiga_d6];

    /* Pointer to the per-texture LUT (NULL if no palette loaded) */
    const uint8_t *pal = g_renderer.cur_wall_pal;

    /* --- Packed texture addressing ---
     *
     * Amiga wall textures pack 3 five-bit texels per 16-bit word:
     *   bits [4:0]   = texel A (PACK 0)
     *   bits [9:5]   = texel B (PACK 1)
     *   bits [14:10] = texel C (PACK 2)
     *
     * The texture data is arranged in vertical strips.  Each strip
     * covers 3 adjacent columns and has (1 << valshift) rows, with
     * 2 bytes per row (one 16-bit packed word).
     *
     *   strip_index  = tex_col / 3
     *   pack_mode    = tex_col % 3
     *   strip_offset = strip_index << (valshift + 1)
     *   row_word     = data[strip_offset + (ty & valand) * 2 .. +1]
     *
     * (Derived from WallRoutine3.ChipMem.s ScreenWallstripdraw)   */
    int strip_index = tex_col / 3;
    int pack_mode   = tex_col % 3;
    /* strip_offset = strip_index * 2 << valshift  =  strip_index << (valshift+1) */
    int strip_offset = strip_index << (valshift + 1);

    /* Texture height = VALAND + 1 (number of distinct rows) */
    int tex_height = (int)valand + 1;
    int32_t tex_step = (tex_height << 16) / wall_height;
    int32_t tex_y = (ct - y_top) * tex_step;

    for (int y = ct; y <= cb; y++) {
        int ty = (int)(tex_y >> 16) & valand;
        uint32_t argb;

        if (texture && pal) {
            /* Read the packed 16-bit word (big-endian) */
            int byte_off = strip_offset + ty * 2;
            uint16_t word = ((uint16_t)texture[byte_off] << 8)
                          | (uint16_t)texture[byte_off + 1];

            /* Unpack the 5-bit texel based on pack mode */
            uint8_t texel5;
            switch (pack_mode) {
            case 0:  texel5 = (uint8_t)(word & 31);         break;  /* bits [4:0]   */
            case 1:  texel5 = (uint8_t)((word >> 5) & 31);  break;  /* bits [9:5]   */
            default: texel5 = (uint8_t)((word >> 10) & 31); break;  /* bits [14:10] */
            }

            /* Look up 16-bit Amiga color word from the LUT.
             * LUT layout: 17 brightness blocks × 32 word entries.
             * Offset: block_offset + texel * 2 (big-endian word). */
            int lut_off = lut_block_off + texel5 * 2;
            uint16_t color_word = ((uint16_t)pal[lut_off] << 8) | pal[lut_off + 1];

            argb = amiga12_to_argb(color_word);
        } else {
            /* No texture or no LUT - fallback gray based on brightness */
            int gray = amiga_d6 * 255 / 32;
            argb = 0xFF000000u | ((uint32_t)gray << 16) | ((uint32_t)gray << 8) | (uint32_t)gray;
        }

        buf[y * RENDER_STRIDE + x] = 1; /* non-zero for legacy checks */
        rgb[y * RENDER_WIDTH + x] = argb;
        tex_y += tex_step;
    }

    /* Update column clip (walls occlude floor/ceiling/sprites behind) */
    if (y_top > g_renderer.clip.top[x]) {
        g_renderer.clip.top[x] = (int16_t)y_top;
    }
    if (y_bot < g_renderer.clip.bot[x]) {
        g_renderer.clip.bot[x] = (int16_t)y_bot;
    }
}

/* -----------------------------------------------------------------------
 * Draw a wall segment between two rotated endpoints
 *
 * Translated from WallRoutine3.ChipMem.s walldraw/screendivide.
 *
 * Takes two endpoints in view space, projects them, and draws
 * columns from left to right with perspective-correct texturing.
 * ----------------------------------------------------------------------- */
void renderer_draw_wall(int16_t x1, int16_t z1, int16_t x2, int16_t z2,
                        int16_t top, int16_t bot,
                        const uint8_t *texture, int16_t tex_start,
                        int16_t tex_end, int16_t brightness,
                        uint8_t valand, uint8_t valshift, int16_t horand)
{
    RendererState *r = &g_renderer;

    /* Both behind camera - skip */
    if (z1 <= 0 && z2 <= 0) return;

    /* Clip to near plane */
    int16_t cx1 = x1, cz1 = z1;
    int16_t cx2 = x2, cz2 = z2;
    int16_t ct1 = tex_start, ct2 = tex_end;

    if (cz1 <= 0) {
        /* Clip left endpoint to near plane (z=1) */
        int32_t dz = cz2 - cz1;
        if (dz == 0) return;
        int32_t t = (1 - cz1) * 65536 / dz;
        cx1 = (int16_t)(cx1 + (int32_t)(cx2 - cx1) * t / 65536);
        cz1 = 1;
        ct1 = (int16_t)(ct1 + (int32_t)(ct2 - ct1) * t / 65536);
    }
    if (cz2 <= 0) {
        int32_t dz = cz1 - cz2;
        if (dz == 0) return;
        int32_t t = (1 - cz2) * 65536 / dz;
        cx2 = (int16_t)(cx2 + (int32_t)(cx1 - cx2) * t / 65536);
        cz2 = 1;
        ct2 = (int16_t)(ct2 + (int32_t)(ct1 - ct2) * t / 65536);
    }

    /* Project to screen */
    int half_w = RENDER_WIDTH / 2;
    int scr_x1 = (int)(((int32_t)cx1 << 7) / cz1) + half_w;
    int scr_x2 = (int)(((int32_t)cx2 << 7) / cz2) + half_w;

    if (scr_x1 > scr_x2) {
        /* Swap so we draw left to right */
        int tmp;
        tmp = scr_x1; scr_x1 = scr_x2; scr_x2 = tmp;
        tmp = cz1; cz1 = (int16_t)cz2; cz2 = (int16_t)tmp;
        tmp = ct1; ct1 = (int16_t)ct2; ct2 = (int16_t)tmp;
    }

    if (scr_x2 < r->left_clip || scr_x1 >= r->right_clip) return;

    int num_cols = scr_x2 - scr_x1;
    if (num_cols <= 0) return;

    /* Draw columns left to right with perspective-correct interpolation */
    for (int col = 0; col < num_cols; col++) {
        int screen_x = scr_x1 + col;
        if (screen_x < r->left_clip || screen_x >= r->right_clip) continue;

        /* Interpolate depth for this column */
        int32_t t = (num_cols > 1) ? (col * 65536 / num_cols) : 0;
        /* Perspective-correct interpolation of 1/z */
        int32_t inv_z1 = 65536 / (cz1 > 0 ? cz1 : 1);
        int32_t inv_z2 = 65536 / (cz2 > 0 ? cz2 : 1);
        int32_t inv_z = inv_z1 + (inv_z2 - inv_z1) * t / 65536;
        if (inv_z <= 0) inv_z = 1;
        int32_t col_z = 65536 / inv_z;
        if (col_z < 1) col_z = 1;

        /* Project wall top/bottom at this depth.
         *
         * Amiga ASM (screendivide): screen_y = topofwall / z + 39
         * Our 'top' = topofwall >> 8, so we must: (top * 256) / col_z + 39
         * where 39 = RENDER_HEIGHT/2 - 1 (screen center on Amiga). */
        int y_top = (int)((int32_t)top * 256 / col_z) + (RENDER_HEIGHT / 2 - 1);
        int y_bot = (int)((int32_t)bot * 256 / col_z) + (RENDER_HEIGHT / 2 - 1);

        /* Texture column (ASM: and.w HORAND,d6) */
        int32_t tex_t = ct1 + (int32_t)(ct2 - ct1) * t / 65536;
        int tex_col = (int)(tex_t) & horand;

        /* Distance-based brightness (Amiga convention).
         *
         * d6 = (z >> 7) + angbright, clamped to [0, 32].
         * SCALE[d6] maps to palette LUT block offsets.
         * d6=0 → dimmest, d6=32 → brightest (normal lit walls). */
        int amiga_d6 = brightness + (int)(col_z >> 7);
        if (amiga_d6 < 0) amiga_d6 = 0;
        if (amiga_d6 > 32) amiga_d6 = 32;

        draw_wall_column(screen_x, y_top, y_bot, tex_col, texture,
                         amiga_d6, valand, valshift);
    }
}

/* -----------------------------------------------------------------------
 * Floor/ceiling span rendering
 *
 * Translated from BumpMap.s / AB3DI.s itsafloordraw.
 *
 * Draws a horizontal span of floor or ceiling at a given height.
 * ----------------------------------------------------------------------- */
void renderer_draw_floor_span(int16_t y, int16_t x_left, int16_t x_right,
                              int32_t floor_height, const uint8_t *texture,
                              int16_t brightness)
{
    uint8_t *buf = g_renderer.buffer;
    uint32_t *rgb = g_renderer.rgb_buffer;
    (void)texture; /* TODO: use floor texture + FloorPalScaled LUT when loaded */
    if (!buf || !rgb) return;
    if (y < 0 || y >= RENDER_HEIGHT) return;

    int xl = (x_left < g_renderer.left_clip) ? g_renderer.left_clip : x_left;
    int xr = (x_right >= g_renderer.right_clip) ? g_renderer.right_clip - 1 : x_right;
    if (xl > xr) return;

    int center = RENDER_HEIGHT / 2 - 1;   /* 39, matches wall projection centre */
    int row_dist = y - center;
    if (row_dist == 0) row_dist = (y < center) ? -1 : 1;

    /* Distance to this floor row (perspective).
     * floor_height is (floor_world - camera_y), a full 32-bit value.
     * Dividing by (screen_row - centre) recovers the world-space distance,
     * analogous to inverting the wall projection formula:
     *   screen_y = (height * 256) / depth + centre          */
    int32_t dist = floor_height / row_dist;
    if (dist < 0) dist = -dist;

    /* Brightness based on distance (Amiga convention).
     * d6 = (dist >> 7) + brightness, clamped to [0, 32].
     * d6 = 0 → brightest, d6 = 32 → dimmest.               */
    int amiga_d6 = brightness + (int)(dist >> 7);
    if (amiga_d6 < 0) amiga_d6 = 0;
    if (amiga_d6 > 32) amiga_d6 = 32;

    /* Convert d6 to a 0-255 brightness value for direct ARGB rendering.
     * d6=0 → brightest (gray=255), d6=32 → dimmest (gray=0). */
    int gray = (32 - amiga_d6) * 255 / 32;

    /* Floor color: dark gray-brown (Alien Breed metal/concrete aesthetic) */
    uint32_t floor_argb = 0xFF000000u
        | ((uint32_t)(gray * 3 / 8) << 16)  /* R - warm */
        | ((uint32_t)(gray * 3 / 10) << 8)  /* G - slightly less */
        | ((uint32_t)(gray * 1 / 5));        /* B - subdued */

    uint8_t *row8 = buf + y * RENDER_STRIDE;
    uint32_t *row32 = rgb + y * RENDER_WIDTH;
    for (int x = xl; x <= xr; x++) {
        /* Only draw floor where nothing has been drawn yet (still black).
         * Walls are drawn before floors in the graphics stream, so this
         * prevents floors from overdrawing wall bases. */
        if (row32[x] != 0xFF000000u) continue;
        row8[x] = 1;
        row32[x] = floor_argb;
    }
}

/* -----------------------------------------------------------------------
 * Sprite rendering
 *
 * Translated from ObjDraw3.ChipRam.s BitMapObj.
 *
 * Draws a scaled sprite at a given screen position.
 * Uses painter's algorithm (drawn back-to-front by zone order).
 * ----------------------------------------------------------------------- */
void renderer_draw_sprite(int16_t screen_x, int16_t screen_y,
                          int16_t width, int16_t height, int16_t z,
                          const uint8_t *graphic, int16_t brightness)
{
    uint8_t *buf = g_renderer.buffer;
    uint32_t *rgb = g_renderer.rgb_buffer;
    if (!buf || !rgb || !graphic) return;
    if (z <= 0) return;

    int16_t half_w = width / 2;
    int sx = screen_x - half_w;
    int sy = screen_y - height;

    /* Brightness from distance */
    int bright = brightness - (z >> 7);
    if (bright < 0) bright = 0;
    if (bright > 15) bright = 15;
    int gray = bright * 17; /* 0-255 */

    /* Draw the sprite pixel by pixel with scaling */
    int src_w = 32;
    int src_h = 32;

    for (int dy = 0; dy < height; dy++) {
        int screen_row = sy + dy;
        if (screen_row < 0 || screen_row >= RENDER_HEIGHT) continue;

        int src_row = dy * src_h / height;
        if (src_row >= src_h) src_row = src_h - 1;

        uint8_t *row8 = buf + screen_row * RENDER_STRIDE;
        uint32_t *row32 = rgb + screen_row * RENDER_WIDTH;

        for (int dx = 0; dx < width; dx++) {
            int screen_col = sx + dx;
            if (screen_col < g_renderer.left_clip ||
                screen_col >= g_renderer.right_clip) continue;

            if (screen_row < g_renderer.clip.top[screen_col] ||
                screen_row > g_renderer.clip.bot[screen_col]) continue;

            int src_col = dx * src_w / width;
            if (src_col >= src_w) src_col = src_w - 1;

            uint8_t texel = graphic[src_row * src_w + src_col];
            if (texel == 0) continue; /* Transparent */

            row8[screen_col] = texel;
            /* Without loaded sprite palettes, use a placeholder orange/red */
            row32[screen_col] = 0xFF000000u
                | ((uint32_t)gray << 16) | ((uint32_t)(gray/3) << 8) | 0;
        }
    }
}

/* -----------------------------------------------------------------------
 * Draw gun overlay
 *
 * Translated from AB3DI.s DrawInGun (lines 2426-2535).
 * Draws the current weapon sprite at the bottom of the screen.
 * ----------------------------------------------------------------------- */
void renderer_draw_gun(GameState *state)
{
    /* The gun is drawn from pre-rendered frames in the LEVELCLIPS data.
     * For now, draw a simple placeholder until graphics data is loaded. */
    uint8_t *buf = g_renderer.buffer;
    uint32_t *rgb = g_renderer.rgb_buffer;
    if (!buf || !rgb) return;

    /* Draw a simple gun outline at the bottom center */
    int gun_w = 24;
    int gun_h = 16;
    int gx = (RENDER_WIDTH - gun_w) / 2;
    int gy = RENDER_HEIGHT - gun_h - 2;

    /* Only draw if player has a gun and isn't looking behind */
    PlayerState *plr = (state->mode == MODE_SLAVE) ? &state->plr2 : &state->plr1;
    if (plr->gun_selected < 0) return;

    /* Draw gun silhouette */
    for (int y = gy; y < gy + gun_h; y++) {
        for (int x = gx; x < gx + gun_w; x++) {
            if (x >= 0 && x < RENDER_WIDTH && y >= 0 && y < RENDER_HEIGHT) {
                int local_x = x - gx;
                int local_y = y - gy;
                if (local_y < gun_h / 2) {
                    if (local_x >= gun_w / 2 - 2 && local_x <= gun_w / 2 + 1) {
                        buf[y * RENDER_STRIDE + x] = 15;
                        rgb[y * RENDER_WIDTH + x] = 0xFFCCCCCC; /* light gray */
                    }
                } else {
                    if (local_x >= gun_w / 3 && local_x <= gun_w * 2 / 3) {
                        buf[y * RENDER_STRIDE + x] = 12;
                        rgb[y * RENDER_WIDTH + x] = 0xFF666666; /* dark gray */
                    }
                }
            }
        }
    }

    (void)plr;
}

/* -----------------------------------------------------------------------
 * Draw objects in the current zone
 *
 * Translated from ObjDraw3.ChipRam.s ObjDraw (lines 38-137).
 *
 * Iterates all objects in ObjectData, finds those in the current zone,
 * sorts by depth, and draws them back-to-front.
 * ----------------------------------------------------------------------- */
static void draw_zone_objects(GameState *state, int16_t zone_id,
                              int32_t top_of_room, int32_t bot_of_room)
{
    RendererState *r = &g_renderer;
    LevelState *level = &state->level;
    if (!level->object_data || !level->object_points) return;

    int32_t y_off = r->yoff;

    /* Build depth-sorted list of objects in this zone */
    typedef struct { int idx; int16_t z; } ObjEntry;
    ObjEntry objs[80];
    int obj_count = 0;

    int num = level->num_object_points;
    if (num > MAX_OBJ_POINTS) num = MAX_OBJ_POINTS;

    for (int i = 0; i < num && obj_count < 80; i++) {
        const uint8_t *obj = level->object_data + i * OBJECT_SIZE;
        int16_t obj_type = rd16(obj);
        if (obj_type < 0) break; /* End of list */

        int16_t graphic_room = rd16(obj + 14); /* GraphicRoom */
        if (graphic_room != zone_id) continue;

        ObjRotatedPoint *orp = &r->obj_rotated[i];
        if (orp->z <= 0) continue; /* Behind camera */

        objs[obj_count].idx = i;
        objs[obj_count].z = orp->z;
        obj_count++;
    }

    /* Sort by Z (farthest first - painter's algorithm) */
    for (int i = 0; i < obj_count - 1; i++) {
        for (int j = i + 1; j < obj_count; j++) {
            if (objs[j].z > objs[i].z) {
                ObjEntry tmp = objs[i];
                objs[i] = objs[j];
                objs[j] = tmp;
            }
        }
    }

    /* Draw each object (back-to-front, painter's algorithm)
     * Translated from ObjDraw3.ChipRam.s BitMapObj (lines 527-626).
     *
     * For each object, the data layout (from Defs.i):
     *   Offset 0:  object type (word)
     *   Offset 2:  brightness (objVectBright, word)
     *   Offset 4:  Y position (word, in ObjectPoints offset 2)
     *   Offset 8:  vector number (objVectNumber, word)
     *   Offset 10: frame number (objVectFrameNumber, word)
     *   Offset 26: GraphicRoom (word)
     */
    for (int oi = 0; oi < obj_count; oi++) {
        int i = objs[oi].idx;
        ObjRotatedPoint *orp = &r->obj_rotated[i];

        if (orp->z < 50) continue; /* Too close / behind (ASM: cmp.w #50,d1) */

        /* Project Y boundaries from room top/bottom
         * ASM: ty3d (top) / by3d (bottom) divided by depth + 40 */
        int32_t clip_top_y = (top_of_room - y_off) / orp->z + (RENDER_HEIGHT / 2);
        int32_t clip_bot_y = (bot_of_room - y_off) / orp->z + (RENDER_HEIGHT / 2);
        if (clip_top_y >= clip_bot_y) continue;

        /* Project to screen X:
         * ASM: divs d1,d0 ; add.w #47,d0 (47 = RENDER_WIDTH/2 - 1) */
        int32_t obj_vx_fine = orp->x_fine;
        int scr_x = (int)(obj_vx_fine / orp->z) + (RENDER_WIDTH / 2);

        /* Get brightness + distance attenuation
         * ASM: asr.w #7,d6 ; add.w (a0)+,d6 (distance>>7 + obj brightness) */
        const uint8_t *obj = level->object_data + i * OBJECT_SIZE;
        int16_t obj_bright = rd16(obj + 2);  /* objVectBright */
        int bright = (orp->z >> 7) + obj_bright;
        if (bright < 0) bright = 0;
        if (bright > 15) bright = 15;

        /* Get Y position from object data
         * ASM: move.w (a0)+,d2 ; ext.l d2 ; asl.l #7,d2 ; sub.l yoff,d2 ;
         *      divs d1,d2 ; add.w #39,d2 */
        int16_t obj_height_raw = rd16(level->object_points + i * 8 + 2);
        int32_t obj_y_view = ((int32_t)obj_height_raw << 7) - y_off;
        int scr_y = (int)(obj_y_view / orp->z) + (RENDER_HEIGHT / 2 - 1);

        /* Sprite dimensions - source is typically a small graphic.
         * ASM reads width/height bytes from graphic data, shifts <<7,
         * divides by depth.  Without loaded graphics, estimate from distance. */
        int sprite_w = 32 * 128 / orp->z;
        int sprite_h = 32 * 128 / orp->z;
        if (sprite_w < 1) sprite_w = 1;
        if (sprite_h < 1) sprite_h = 1;
        if (sprite_w > RENDER_WIDTH) sprite_w = RENDER_WIDTH;
        if (sprite_h > RENDER_HEIGHT) sprite_h = RENDER_HEIGHT;

        /* Frame selection:
         * objVectNumber (offset 8) = sprite graphic index
         * objVectFrameNumber (offset 10) = animation frame
         * These would index into loaded sprite data; NULL until graphics load. */
        /* int16_t vect_num = rd16(obj + 8); */
        /* int16_t frame_num = rd16(obj + 10); */

        renderer_draw_sprite((int16_t)scr_x, (int16_t)scr_y,
                             (int16_t)sprite_w, (int16_t)sprite_h,
                             orp->z, NULL, (int16_t)bright);
    }
}

/* -----------------------------------------------------------------------
 * Draw a single zone
 *
 * Translated from AB3DI.s DoThisRoom (lines 3814-3925) and polyloop.
 *
 * The zone graphics data (from LEVELGRAPHICS) is a stream of entries:
 *   - First word: zone number (consumed before polyloop)
 *   - Then type words followed by type-specific data
 *
 * Type dispatch (from polyloop, lines 3828-3852):
 *   0  = wall        -> itsawalldraw (26 bytes of data after type)
 *   1  = floor       -> itsafloordraw (variable: ypos + sides + points + extra)
 *   2  = roof        -> itsafloordraw (same format)
 *   3  = clip setter -> no data (clipping done separately via ListOfGraphRooms)
 *   4  = object      -> ObjDraw (1 word: draw mode)
 *   5  = arc         -> CurveDraw (variable)
 *   6  = light beam  -> LightDraw (variable)
 *   7  = water       -> itsafloordraw (same as floor)
 *   8  = chunky floor-> itsafloordraw
 *   9  = bumpy floor -> itsafloordraw
 *  12  = backdrop    -> putinbackdrop (no extra data)
 *  13  = see-wall    -> itsawalldraw (same 26 bytes)
 *  <0  = end of list
 *
 * Wall entry (26 bytes after type word):
 *   +0: point1 (word)       - index into Points/Rotated array
 *   +2: point2 (word)       - index into Points/Rotated array
 *   +4: strip_start (word)  - leftend texture column
 *   +6: strip_end (word)    - rightend texture column
 *   +8: texture_tile (word) - tile offset (*16)
 *  +10: totalyoff (word)    - vertical texture offset
 *  +12: texture_id (word)   - index into walltiles[] array
 *  +14: VALAND (byte)       - vertical texture AND mask
 *  +15: VALSHIFT (byte)     - vertical texture shift
 *  +16: HORAND (word)       - horizontal texture AND mask
 *  +18: topofwall (long)    - wall top height (world coords)
 *  +22: botofwall (long)    - wall bottom height (world coords)
 *  +26: wallbrightoff (word)- brightness offset
 *  Total: 28 bytes after type word
 *
 * Floor/Roof entry (variable bytes after type word):
 *   +0: ypos (word)        - floor/ceiling height (>>6 for world)
 *   +2: num_sides-1 (word) - polygon sides minus 1
 *   +4: point indices (2 bytes * (sides))
 *   +4+2*sides: 4 bytes padding + 6 bytes extra data = 10 bytes
 *  Total: 2+2+2*sides+10 bytes after type word
 *
 * Object entry (2 bytes after type word):
 *   +0: draw_mode (word) - 0=before water, 1=after water, 2=full room
 * ----------------------------------------------------------------------- */
void renderer_draw_zone(GameState *state, int16_t zone_id)
{
    RendererState *r = &g_renderer;
    LevelState *level = &state->level;

    if (!level->data || !level->zone_adds || !level->zone_graph_adds) return;

    /* Get zone data */
    int32_t zone_off = rd32(level->zone_adds + zone_id * 4);
    const uint8_t *zone_data = level->data + zone_off;

    /* Get zone graphics data (the polygon list for this zone) */
    const uint8_t *zgraph = level->zone_graph_adds + zone_id * 8;
    int32_t gfx_off = rd32(zgraph);
    if (gfx_off == 0 || !level->graphics) return;

    const uint8_t *gfx_data = level->graphics + gfx_off;

    /* Zone heights */
    int32_t zone_floor = rd32(zone_data + 2);   /* ToZoneFloor */
    int32_t zone_roof  = rd32(zone_data + 6);   /* ToZoneRoof */
    int32_t zone_water = rd32(zone_data + 18);  /* ToZoneWater */
    (void)zone_water; /* Used by water-type floors when entry_type==7 */

    int32_t y_off = r->yoff;
    int half_h = RENDER_HEIGHT / 2;

    /* Read zone number from graphics data (consumed before polyloop) */
    const uint8_t *ptr = gfx_data;
    /* int16_t gfx_zone = rd16(ptr); */
    ptr += 2;

    /* Brightness for this zone (from ZoneBrightTable if available).
     * Table layout: byte per zone, upper floor at [zone + num_zones]. */
    int16_t zone_bright = 8; /* default mid brightness */
    if (level->zone_bright_table && zone_id >= 0 && zone_id < level->num_zones) {
        zone_bright = (int16_t)level->zone_bright_table[zone_id];
    }

    int max_iter = 500; /* Safety limit */

    while (max_iter-- > 0) {
        int16_t entry_type = rd16(ptr);
        ptr += 2; /* Consume type word (matches ASM (a0)+) */

        if (entry_type < 0) break; /* End of list */

        switch (entry_type) {
        case 0:  /* Wall */
        case 13: /* See-through wall */
        {
            /* Wall entry: 28 bytes of data
             * Translated from WallRoutine3.ChipMem.s itsawalldraw (line 1761) */
            int16_t p1       = rd16(ptr + 0);   /* point1 index */
            int16_t p2       = rd16(ptr + 2);   /* point2 index */
            int16_t leftend  = rd16(ptr + 4);   /* strip start */
            int16_t rightend = rd16(ptr + 6);   /* strip end */
            /* int16_t tex_tile = rd16(ptr + 8); */  /* texture tile offset */
            /* int16_t tot_yoff = rd16(ptr + 10); */ /* vertical tex offset */
            /* int16_t tex_id   = rd16(ptr + 12); */ /* walltiles index */
            uint8_t  valand    = ptr[14];             /* vert AND mask (e.g. 127 for 128-row texture) */
            uint8_t  valshift  = ptr[15];             /* vert shift (strip stride = 2 << valshift) */
            int16_t  horand    = rd16(ptr + 16);      /* horiz AND mask (e.g. 127 for 128-col texture) */
            int32_t topwall  = rd32(ptr + 18);  /* wall top height */
            int32_t botwall  = rd32(ptr + 22);  /* wall bottom height */
            /* int16_t wallbrightoff = rd16(ptr + 26); */ /* brightness offset (used by per-column interp) */

            /* Subtract camera Y (ASM: sub.l d6,topofwall / sub.l d6,botofwall) */
            topwall -= y_off;
            botwall -= y_off;

            /* Skip if wall faces away (top >= bot after Y subtract) */
            if (topwall < botwall &&
                p1 >= 0 && p1 < MAX_POINTS && p2 >= 0 && p2 < MAX_POINTS)
            {
                int16_t rx1 = (int16_t)(r->rotated[p1].x >> 7);
                int16_t rz1 = (int16_t)r->rotated[p1].z;
                int16_t rx2 = (int16_t)(r->rotated[p2].x >> 7);
                int16_t rz2 = (int16_t)r->rotated[p2].z;

                /* Brightness: Amiga-style angbright.
                 * ASM (WallRoutine3 line 1908-1916):
                 *   leftwallbright = pointBright[pt] + 300 + wallbrightoff
                 *   angbright = (left + right) / 2
                 * ZoneBright is overridden (set before walldraw call but
                 * replaced by averaged wall brightness inside walldraw).
                 * Higher angbright = brighter (SCALE[d6] maps to higher blocks).
                 *
                 * d6 = (z >> 7) + angbright, clamped to [0, 32].
                 * Our brightness = d6 / 2, clamped to [0, 15]. */
                /* Brightness: use ZoneBright as the base.
                 *
                 * Amiga ASM (WallRoutine3 line 1789):
                 *   move.w ZoneBright,angbright
                 * The per-point brightness interpolation refines this
                 * per-column, but as a first approximation ZoneBright
                 * gives the right range for d6 = (z>>7) + angbright. */
                int wall_bright = (int)zone_bright;

                /* Look up wall texture + palette from walltiles table */
                const uint8_t *wall_tex = NULL;
                int16_t tex_id = rd16(ptr + 12);
                if (tex_id >= 0 && tex_id < MAX_WALL_TILES) {
                    wall_tex = r->walltiles[tex_id];
                    r->cur_wall_pal = r->wall_palettes[tex_id];
                } else {
                    r->cur_wall_pal = NULL;
                }

                renderer_draw_wall(rx1, rz1, rx2, rz2,
                                   (int16_t)(topwall >> 8),
                                   (int16_t)(botwall >> 8),
                                   wall_tex, leftend, rightend,
                                   (int16_t)wall_bright,
                                   valand, valshift, horand);
            }
            ptr += 28;
            break;
        }

        case 1:  /* Floor */
        case 2:  /* Roof */
        case 7:  /* Water */
        case 8:  /* Chunky floor */
        case 9:  /* Bumpy floor */
        case 10: /* Bumpy floor variant */
        case 11: /* Bumpy floor variant */
        {
            /* Floor/Roof/Water polygon entry (variable size)
             * Translated from AB3DI.s itsafloordraw (line 5066).
             *
             * Format after type word:
             *   ypos (word): floor height
             *   num_sides-1 (word): number of polygon sides minus 1
             *   point_indices (word * (sides)): vertex indices
             *   extra_data (10 bytes): skip over
             */
            int16_t ypos = rd16(ptr);
            ptr += 2;
            int16_t num_sides_m1 = rd16(ptr);
            ptr += 2;

            /* Skip point indices (2 bytes each) */
            int sides = num_sides_m1 + 1;
            if (sides < 0) sides = 0;
            if (sides > 100) sides = 100; /* safety */

            /* We need these point indices for proper polygon rendering.
             * For now, collect them for the fill algorithm. */
            int16_t pt_indices[100];
            for (int s = 0; s < sides; s++) {
                pt_indices[s] = rd16(ptr);
                ptr += 2;
            }

            /* Skip 4 bytes padding + 6 bytes extra data = 10 bytes
             * (matches ASM: lea 4+6(a0),a0) */
            ptr += 10;

            /* Determine floor height in world coords */
            int32_t floor_h_world = (int32_t)ypos << 6; /* ASM: asl.l #6,d7 */
            int32_t rel_h = floor_h_world - y_off; /* Relative to camera */

            /* Floor Y offset (from flooryoff) */
            int16_t floor_y_dist = (int16_t)(ypos - r->flooryoff);

            if (floor_y_dist == 0) {
                /* At eye level - skip */
                continue;
            }

            /* Determine screen coverage from polygon vertices.
             * Find the left/right screen extents from rotated points. */
            int min_sx = RENDER_WIDTH;
            int max_sx = 0;
            for (int s = 0; s < sides; s++) {
                int pi = pt_indices[s];
                if (pi < 0 || pi >= MAX_POINTS) continue;
                int sx = r->on_screen[pi].screen_x;
                if (sx < min_sx) min_sx = sx;
                if (sx > max_sx) max_sx = sx;
            }

            if (min_sx < r->left_clip) min_sx = r->left_clip;
            if (max_sx >= r->right_clip) max_sx = r->right_clip - 1;
            if (min_sx > max_sx) continue;

            /* For floor: draw from center down. For roof: center up. */
            int16_t bright = zone_bright;
            if (floor_y_dist > 0) {
                /* Floor is below us */
                for (int row = half_h; row < RENDER_HEIGHT; row++) {
                    renderer_draw_floor_span((int16_t)row,
                        (int16_t)min_sx, (int16_t)max_sx,
                        rel_h, NULL, bright);
                }
            } else {
                /* Ceiling is above us */
                for (int row = 0; row < half_h; row++) {
                    renderer_draw_floor_span((int16_t)row,
                        (int16_t)min_sx, (int16_t)max_sx,
                        rel_h, NULL, bright);
                }
            }
            break;
        }

        case 3: /* Clip setter */
            /* No additional data consumed in polyloop
             * (clipping is done from ListOfGraphRooms, not here) */
            break;

        case 4: /* Object (sprite) */
        {
            /* ObjDraw reads 1 word: draw mode (0=before water, 1=after, 2=full)
             * Then iterates ALL objects in ObjectData for this zone.
             * Translated from ObjDraw3.ChipRam.s ObjDraw (line 38). */
            /* int16_t draw_mode = rd16(ptr); */
            ptr += 2;

            /* Draw all objects in this zone */
            draw_zone_objects(state, zone_id, zone_roof, zone_floor);
            break;
        }

        case 5: /* Arc (curved wall) */
        {
            /* Arc entry: 28 bytes of data after type word.
             * Translated from WallRoutine3.ChipMem.s CurveDraw (lines 498-538):
             *   point1(2) + point2(2) + bitmap_start(2) + bitmap_end(2) +
             *   angle(2) + subdivide(2) + walltiles_offset(4) +
             *   basebright(2) + brightmult(2) + topofwall(4) + botofwall(4) = 28
             * Skip for now - arcs are relatively uncommon. */
            ptr += 28;
            break;
        }

        case 6: /* Light beam */
        {
            /* Light beams: 4 bytes of data after type word.
             * Translated from AB3DI.s LightDraw (lines 4364-4365):
             *   point1(2) + point2(2) = 4 bytes */
            ptr += 4;
            break;
        }

        case 12: /* Backdrop */
        {
            /* putinbackdrop - no additional data in the graphics stream */
            /* Would fill the background with sky texture */
            break;
        }

        default:
            /* Unknown type - skip nothing (type word already consumed) */
            break;
        }
    }
}

/* -----------------------------------------------------------------------
 * DrawDisplay - Main rendering entry point
 *
 * Translated from AB3DI.s DrawDisplay (lines 3395-3693).
 *
 * This is called once per frame to render the entire 3D scene.
 * ----------------------------------------------------------------------- */
void renderer_draw_display(GameState *state)
{
    RendererState *r = &g_renderer;
    if (!r->buffer) return;

    /* 1. Clear framebuffer */
    renderer_clear(0);

    /* 2. Setup view transform (from AB3DI.s DrawDisplay lines 3399-3438) */
    PlayerState *plr = (state->mode == MODE_SLAVE) ? &state->plr2 : &state->plr1;

    int16_t ang = (int16_t)(plr->angpos & 0x3FFF); /* 14-bit angle */
    r->sinval = sin_lookup(ang);
    r->cosval = cos_lookup(ang);

    /* Extract integer part of 16.16 fixed-point position for rendering.
     * On Amiga: .w operations on big-endian 32-bit values read the high word. */
    r->xoff = (int16_t)(plr->xoff >> 16);
    r->zoff = (int16_t)(plr->zoff >> 16);
    r->yoff = plr->yoff;

    /* wallyoff = (yoff >> 8) + 224, masked to 0-255 */
    int32_t y_shifted = r->yoff >> 8;
    r->wallyoff = (int16_t)((y_shifted + 256 - 32) & 255);
    r->flooryoff = (int16_t)(y_shifted << 2);

    /* xoff34 = xoff * 3/4, zoff34 = zoff * 3/4 */
    r->xoff34 = (int16_t)((r->xoff * 3) >> 2);
    r->zoff34 = (int16_t)((r->zoff * 3) >> 2);

    /* xwobble from head bob */
    r->xwobble = 0; /* Would be set from plr->bob_frame */

    /* 3. Initialize column clipping */
    for (int i = 0; i < RENDER_WIDTH; i++) {
        r->clip.top[i] = 0;
        r->clip.bot[i] = RENDER_HEIGHT - 1;
    }

    /* 4. Rotate geometry */
    renderer_rotate_level_pts(state);
    renderer_rotate_object_pts(state);

    /* 5. Iterate zones back-to-front (from OrderZones output)
     *
     * Translated from AB3DI.s subroomloop (lines 3456-3643).
     *
     * For each zone:
     *   a) Find it in ListOfGraphRooms to get clip data offset
     *   b) Apply clipping from LEVELCLIPS using NEWsetlclip/NEWsetrclip
     *   c) Skip if fully clipped
     *   d) Render the zone
     */
    for (int i = state->zone_order_count - 1; i >= 0; i--) {
        int16_t zone_id = state->zone_order_zones[i];
        if (zone_id < 0) continue;

        /* Reset clip to full screen for each zone */
        r->left_clip = 0;
        r->right_clip = RENDER_WIDTH;

        /* Apply zone clipping from ListOfGraphRooms + LEVELCLIPS.
         * ListOfGraphRooms entries are 8 bytes:
         *   +0: zone_id (word)
         *   +2: clip_offset (word) - offset into LEVELCLIPS (* 2)
         *   +4: reserved (4 bytes)
         * LEVELCLIPS is an array of word-sized point indices.
         * First section: left clips (terminated by -1)
         * Second section: right clips (terminated by -1) */
        if (state->level.list_of_graph_rooms && state->level.clips) {
            const uint8_t *lgr = state->level.list_of_graph_rooms;
            /* Find this zone's entry in ListOfGraphRooms */
            int found = 0;
            while (rd16(lgr) >= 0) {
                if (rd16(lgr) == zone_id) {
                    found = 1;
                    break;
                }
                lgr += 8;
            }

            if (found) {
                int16_t clip_off = rd16(lgr + 2);
                if (clip_off >= 0) {
                    const uint8_t *clip_ptr = state->level.clips + clip_off * 2;

                    /* Left clips: tighten leftclip.
                     * Each entry is a point index.
                     * If point is in front, use its OnScreen X as left clip. */
                    while (rd16(clip_ptr) >= 0) {
                        int16_t pt = rd16(clip_ptr);
                        clip_ptr += 2;
                        if (pt >= 0 && pt < MAX_POINTS) {
                            if (r->rotated[pt].z > 0) {
                                int16_t sx = r->on_screen[pt].screen_x;
                                if (sx > r->left_clip) {
                                    r->left_clip = sx;
                                }
                            }
                        }
                    }
                    clip_ptr += 2; /* Skip -1 terminator */

                    /* Right clips: tighten rightclip */
                    while (rd16(clip_ptr) >= 0) {
                        int16_t pt = rd16(clip_ptr);
                        clip_ptr += 2;
                        if (pt >= 0 && pt < MAX_POINTS) {
                            if (r->rotated[pt].z > 0) {
                                int16_t sx = r->on_screen[pt].screen_x;
                                if (sx < r->right_clip) {
                                    r->right_clip = sx;
                                }
                            }
                        }
                    }
                }
            }

            /* Skip if fully clipped */
            if (r->left_clip >= RENDER_WIDTH) continue;
            if (r->right_clip <= 0) continue;
            if (r->left_clip >= r->right_clip) continue;
        }

        renderer_draw_zone(state, zone_id);
    }

    /* Debug: count visible non-zero pixels + histogram */
    {
        static int dbg_frame = 0;
        if (dbg_frame < 3) {
            int nonzero = 0;
            int histo[16] = {0}; /* buckets for value ranges 0-15, 16-31, etc */
            for (int y = 0; y < RENDER_HEIGHT; y++) {
                for (int x = 0; x < RENDER_WIDTH; x++) {
                    uint8_t v = r->buffer[y * RENDER_STRIDE + x];
                    if (v) { nonzero++; histo[v >> 4]++; }
                }
            }
            printf("[RENDER] Frame %d: %d zones, %d/%d visible non-zero px\n",
                   dbg_frame, state->zone_order_count, nonzero, RENDER_WIDTH*RENDER_HEIGHT);
            printf("[RENDER] Histo: ");
            for (int i = 0; i < 16; i++) {
                if (histo[i]) printf("[%d-%d]=%d ", i*16, i*16+15, histo[i]);
            }
            printf("\n");
            fflush(stdout);
        }
        dbg_frame++;
    }

    /* 6. Draw gun overlay */
    renderer_draw_gun(state);

    /* 7. Swap buffers (the just-drawn buffer becomes the display buffer) */
    renderer_swap();
}
