/*
 * Alien Breed 3D I - PC Port
 * stub_io.c - File I/O with procedural test level fallback
 *
 * Attempts to load original Amiga level data from disk.
 * If not found, generates a simple procedural test level
 * so the renderer and movement can be tested.
 */

#include "stub_io.h"
#include "sb_decompress.h"
#include "renderer.h"
#include "game_types.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* -----------------------------------------------------------------------
 * Data path resolution
 *
 * Game data lives in pc/data/ relative to the project root.
 * We try several paths to find it.
 * ----------------------------------------------------------------------- */
static char g_data_base[512] = "";

static const char *data_base_path(void)
{
    if (g_data_base[0]) return g_data_base;

    /* Try paths relative to the working directory */
    static const char *candidates[] = {
        "data/",                     /* if CWD = pc/ */
        "../data/",                  /* if CWD = pc/build/ */
        "../../data/",              /* if CWD = pc/build/Release/ */
        "../../../data/",           /* if CWD = pc/build/Debug/ (nested) */
        "pc/data/",                 /* if CWD = project root */
        NULL
    };

    for (int i = 0; candidates[i]; i++) {
        char test[512];
        snprintf(test, sizeof(test), "%slevels/level_a/twolev.bin",
                 candidates[i]);
        FILE *f = fopen(test, "rb");
        if (f) {
            fclose(f);
            snprintf(g_data_base, sizeof(g_data_base), "%s", candidates[i]);
            printf("[IO] Found data at: %s\n", g_data_base);
            return g_data_base;
        }
    }

    printf("[IO] WARNING: Could not locate data/ directory\n");
    return "";
}

static void make_data_path(char *buf, size_t bufsize, const char *subpath)
{
    snprintf(buf, bufsize, "%s%s", data_base_path(), subpath);
}

/* -----------------------------------------------------------------------
 * Big-endian write helpers (level data is Amiga format)
 * ----------------------------------------------------------------------- */
static inline void wr16(uint8_t *p, int16_t v) {
    p[0] = (uint8_t)(v >> 8);
    p[1] = (uint8_t)(v);
}
static inline void wr32(uint8_t *p, int32_t v) {
    p[0] = (uint8_t)(v >> 24);
    p[1] = (uint8_t)(v >> 16);
    p[2] = (uint8_t)(v >> 8);
    p[3] = (uint8_t)(v);
}

/* -----------------------------------------------------------------------
 * Procedural test level
 *
 * Creates a small multi-room level with walls, floor, and ceiling
 * so we can test the renderer and navigation.
 *
 * Layout: 4 rooms in a 2x2 grid, connected by doorways
 *
 *   Room 0 (NW)  |  Room 1 (NE)
 *  ──────────────┼──────────────
 *   Room 2 (SW)  |  Room 3 (SE)
 *
 * Each room is 512x512 units, total level is 1024x1024.
 * Floor at y=0 (world), ceiling at y=4096 (64<<6).
 * Player starts in room 0 at (256, 256).
 * ----------------------------------------------------------------------- */

/* Zone data offsets -- matching includes/Defs.i and C code expectations.
 * The C code in movement.c/visibility.c reads WallList/ExitList as be32.
 * We write them as 32-bit absolute offsets so the C code works. */
#define ZD_ZONE_NUM       0    /* word */
#define ZD_FLOOR          2    /* long */
#define ZD_ROOF           6    /* long */
#define ZD_UPPER_FLOOR   10    /* long */
#define ZD_UPPER_ROOF    14    /* long */
#define ZD_WATER         18    /* long */
#define ZD_BRIGHTNESS    22    /* word */
#define ZD_UPPER_BRIGHT  24    /* word */
#define ZD_CPT           26    /* word */
#define ZD_WALL_LIST     28    /* long: absolute offset to wall list in level data */
#define ZD_EXIT_LIST     32    /* long: absolute offset to exit list in level data */
/* renderer.c reads byte 34 as a WORD relative offset (ToZonePts).
 * We write it as a word at byte 34 relative to zone start. */
#define ZD_PTS_REL       34    /* word: RELATIVE offset from zone data to pts list */
#define ZD_BACK          36    /* word */
#define ZD_TEL_ZONE      38    /* word: teleport destination zone (-1 = none) */
#define ZD_TEL_X         40    /* word */
#define ZD_TEL_Z         42    /* word */
#define ZD_SIZE          52    /* total zone data size */

/* Floor line data */
#define FL_X              0    /* word */
#define FL_Z              2    /* word */
#define FL_XLEN           4    /* word */
#define FL_ZLEN           6    /* word */
#define FL_CONNECT        8    /* word: connected zone or -1 */
#define FL_AWAY          10    /* byte: push-away shift */
#define FL_SIZE          16    /* bytes per floor line (must match movement.c/visibility.c) */

#define NUM_ZONES         4
#define ROOM_SIZE       512
#define FLOOR_H           0                /* floor at y=0 */
#define ROOF_H        (64 << 6)           /* ceiling at 4096 */

/* Points: corners of the 4 rooms */
/*
 *   0─────1─────2
 *   │  0  │  1  │
 *   3─────4─────5
 *   │  2  │  3  │
 *   6─────7─────8
 */
#define NUM_POINTS 9

static void build_test_level_data(LevelState *level)
{
    /* Calculate buffer sizes */
    int hdr_size = 54;                      /* Level header */
    int zone_table_size = NUM_ZONES * 4;    /* Zone offset table */
    int zone_data_size = NUM_ZONES * ZD_SIZE;
    int points_size = NUM_POINTS * 4;       /* x,z pairs as words */
    /* Floor lines: 4 walls per room (16) + 4 doorways = 20 lines */
    #define NUM_FLINES 20
    int flines_size = NUM_FLINES * FL_SIZE;
    /* Wall lists: per zone, list of fline indices terminated by -1 */
    int wlists_size = NUM_ZONES * 12;       /* max 5 words + sentinel per zone */
    /* Exit lists: per zone, list of exit line indices */
    int elists_size = NUM_ZONES * 12;
    /* Points-to-rotate list */
    int ptr_list_size = (NUM_POINTS + 1) * 2; /* indices + sentinel */
    /* Object data: just 2 player objects */
    int obj_data_size = 3 * OBJECT_SIZE; /* 2 players + 1 terminator */
    int obj_points_size = 3 * 8;

    int total = hdr_size + zone_table_size + zone_data_size + points_size +
                flines_size + wlists_size + elists_size + ptr_list_size +
                obj_data_size + obj_points_size + 256; /* padding */

    uint8_t *buf = (uint8_t *)calloc(1, (size_t)total);
    if (!buf) return;

    /* Point coordinates (grid corners) */
    static const int16_t pt_coords[NUM_POINTS][2] = {
        {   0,    0}, { 512,    0}, {1024,    0},  /* top row */
        {   0,  512}, { 512,  512}, {1024,  512},  /* middle row */
        {   0, 1024}, { 512, 1024}, {1024, 1024},  /* bottom row */
    };

    /* ---- Offsets ---- */
    int off_zone_table = hdr_size;
    int off_zones = off_zone_table + zone_table_size;
    int off_points = off_zones + zone_data_size;
    int off_flines = off_points + points_size;
    int off_wlists = off_flines + flines_size;
    int off_elists = off_wlists + wlists_size;
    int off_ptr_list = off_elists + elists_size;
    int off_obj_data = off_ptr_list + ptr_list_size;
    int off_obj_points = off_obj_data + obj_data_size;

    /* ---- Header (matches level.c parser) ---- */
    uint8_t *hdr = buf;
    wr16(hdr + 0,  256);        /* PLR1 start X */
    wr16(hdr + 2,  256);        /* PLR1 start Z */
    wr16(hdr + 4,  0);          /* PLR1 start zone */
    wr16(hdr + 6,  256);        /* PLR1 start angle */
    wr16(hdr + 8,  768);        /* PLR2 start X */
    wr16(hdr + 10, 768);        /* PLR2 start Z */
    wr16(hdr + 12, 3);          /* PLR2 start zone */
    wr16(hdr + 14, 0);          /* PLR2 start angle */
    wr16(hdr + 16, 0);          /* num control points (unused) */
    wr16(hdr + 18, NUM_POINTS); /* num points */
    wr16(hdr + 20, NUM_ZONES);  /* num zones */
    wr16(hdr + 22, NUM_FLINES); /* num floor lines */
    wr16(hdr + 24, 2);          /* num object points */
    wr32(hdr + 26, off_points); /* offset to points */
    wr32(hdr + 30, off_flines); /* offset to floor lines */
    wr32(hdr + 34, off_obj_data);    /* offset to object data */
    wr32(hdr + 38, 0);               /* offset to player shot data */
    wr32(hdr + 42, 0);               /* offset to nasty shot data */
    wr32(hdr + 46, off_obj_points);  /* offset to object points */
    wr32(hdr + 50, off_obj_data);    /* offset to PLR1 obj */

    /* ---- Zone offset table ---- */
    for (int z = 0; z < NUM_ZONES; z++) {
        wr32(buf + off_zone_table + z * 4, off_zones + z * ZD_SIZE);
    }

    /* ---- Zone data ---- */
    for (int z = 0; z < NUM_ZONES; z++) {
        uint8_t *zd = buf + off_zones + z * ZD_SIZE;
        wr16(zd + ZD_ZONE_NUM, (int16_t)z);
        wr32(zd + ZD_FLOOR, FLOOR_H);
        wr32(zd + ZD_ROOF, ROOF_H);
        wr32(zd + ZD_UPPER_FLOOR, 0);
        wr32(zd + ZD_UPPER_ROOF, 0);
        wr32(zd + ZD_WATER, 0);
        wr16(zd + ZD_BRIGHTNESS, 8);        /* lower floor brightness */
        wr16(zd + ZD_UPPER_BRIGHT, 8);      /* upper floor brightness */
        wr16(zd + ZD_CPT, -1);              /* no connect point */
        wr32(zd + ZD_WALL_LIST, off_wlists + z * 12);  /* absolute offset */
        wr32(zd + ZD_EXIT_LIST, off_elists + z * 12);  /* absolute offset */
        /* ToZonePts: relative offset from zone data to points list.
         * renderer.c reads room+34 as be16, treats as relative offset. */
        wr16(zd + ZD_PTS_REL, (int16_t)(off_ptr_list - (off_zones + z * ZD_SIZE)));
        wr16(zd + ZD_BACK, 0);
        wr16(zd + ZD_TEL_ZONE, -1);         /* no teleport */
        wr16(zd + ZD_TEL_X, 0);
        wr16(zd + ZD_TEL_Z, 0);
    }

    /* ---- Points ---- */
    for (int i = 0; i < NUM_POINTS; i++) {
        wr16(buf + off_points + i * 4, pt_coords[i][0]);
        wr16(buf + off_points + i * 4 + 2, pt_coords[i][1]);
    }

    /* ---- Floor lines ----
     * Room walls (each room has 4 outer walls):
     * Room 0 (pts 0,1,3,4): walls 0-3
     * Room 1 (pts 1,2,4,5): walls 4-7
     * Room 2 (pts 3,4,6,7): walls 8-11
     * Room 3 (pts 4,5,7,8): walls 12-15
     * Doorways: 16-19
     */
    typedef struct { int16_t x,z,xl,zl; int16_t connect; } FLineSpec;

    /* Room 0: top wall (0->1), right exit (1->4), bottom exit (3->4), left wall (3->0) */
    /* Room 1: top wall (1->2), right wall (2->5), bottom exit (4->5), left exit (4->1) */
    /* etc. */
    FLineSpec lines[NUM_FLINES] = {
        /* Room 0 walls */
        {   0,   0,  512,    0,  -1},  /* 0: top 0->1 */
        { 512,   0,    0,  512,   1},  /* 1: right 1->4 (exit to room 1) */
        { 512, 512, -512,    0,  -1},  /* 2: bottom 4->3 */
        {   0, 512,    0, -512,   2},  /* 3: left 3->0 (exit to room 2) */
        /* Room 1 walls */
        { 512,   0,  512,    0,  -1},  /* 4: top 1->2 */
        {1024,   0,    0,  512,  -1},  /* 5: right 2->5 */
        {1024, 512, -512,    0,  -1},  /* 6: bottom 5->4 */
        { 512, 512,    0, -512,   0},  /* 7: left 4->1 (exit to room 0) */
        /* Room 2 walls */
        {   0, 512,  512,    0,   0},  /* 8: top 3->4 (exit to room 0) */
        { 512, 512,    0,  512,   3},  /* 9: right 4->7 (exit to room 3) */
        { 512,1024, -512,    0,  -1},  /* 10: bottom 7->6 */
        {   0,1024,    0, -512,  -1},  /* 11: left 6->3 */
        /* Room 3 walls */
        { 512, 512,  512,    0,  -1},  /* 12: top 4->5 (exit to room 1) */
        {1024, 512,    0,  512,  -1},  /* 13: right 5->8 */
        {1024,1024, -512,    0,  -1},  /* 14: bottom 8->7 */
        { 512,1024,    0, -512,   2},  /* 15: left 7->4 (exit to room 2) */
        /* Extra exit lines (matching in other direction) */
        { 512,   0,    0,  512,   0},  /* 16: room1->room0 */
        {   0, 512,  512,    0,   2},  /* 17: room0->room2 */
        { 512, 512,    0,  512,   2},  /* 18: room3->room2 */
        { 512, 512,  512,    0,   1},  /* 19: room3->room1 */
    };

    for (int i = 0; i < NUM_FLINES; i++) {
        uint8_t *fl = buf + off_flines + i * FL_SIZE;
        wr16(fl + FL_X, lines[i].x);
        wr16(fl + FL_Z, lines[i].z);
        wr16(fl + FL_XLEN, lines[i].xl);
        wr16(fl + FL_ZLEN, lines[i].zl);
        wr16(fl + FL_CONNECT, lines[i].connect);
        fl[FL_AWAY] = 4; /* push-away shift */
    }

    /* ---- Wall lists per zone (indices into flines, terminated by -1) ---- */
    /* Room 0: walls 0,1,2,3 */
    int16_t wl0[] = {0, 1, 2, 3, -1};
    int16_t wl1[] = {4, 5, 6, 7, -1};
    int16_t wl2[] = {8, 9, 10, 11, -1};
    int16_t wl3[] = {12, 13, 14, 15, -1};
    int16_t *wlists[] = {wl0, wl1, wl2, wl3};
    int wl_sizes[] = {5, 5, 5, 5};

    for (int z = 0; z < NUM_ZONES; z++) {
        uint8_t *wl = buf + off_wlists + z * 12;
        for (int j = 0; j < wl_sizes[z]; j++) {
            wr16(wl + j * 2, wlists[z][j]);
        }
    }

    /* ---- Exit lists (same as wall lists for now - move_object checks connect) ---- */
    for (int z = 0; z < NUM_ZONES; z++) {
        uint8_t *el = buf + off_elists + z * 12;
        for (int j = 0; j < wl_sizes[z]; j++) {
            wr16(el + j * 2, wlists[z][j]);
        }
    }

    /* ---- Points-to-rotate list ---- */
    {
        uint8_t *ptl = buf + off_ptr_list;
        for (int i = 0; i < NUM_POINTS; i++) {
            wr16(ptl + i * 2, (int16_t)i);
        }
        wr16(ptl + NUM_POINTS * 2, -1); /* sentinel */
    }

    /* ---- Object data (2 player objects + terminator) ---- */
    memset(buf + off_obj_data, 0, (size_t)obj_data_size);
    /* PLR1 object */
    wr16(buf + off_obj_data + 0, 0);     /* collision_id = 0 (PLR1) */
    wr16(buf + off_obj_data + 12, 0);    /* zone = 0 */
    /* PLR2 object */
    wr16(buf + off_obj_data + OBJECT_SIZE + 0, 1);  /* collision_id = 1 (PLR2) */
    wr16(buf + off_obj_data + OBJECT_SIZE + 12, 3);  /* zone = 3 */
    /* Terminator object: collision_id = -1 ends the list */
    wr16(buf + off_obj_data + 2 * OBJECT_SIZE + 0, -1);
    wr16(buf + off_obj_data + 2 * OBJECT_SIZE + 12, -1); /* zone = -1 (inactive) */

    /* ---- Object points ---- */
    wr16(buf + off_obj_points + 0, 256);  /* PLR1 x */
    wr16(buf + off_obj_points + 4, 256);  /* PLR1 z */
    wr16(buf + off_obj_points + 8, 768);  /* PLR2 x */
    wr16(buf + off_obj_points + 12, 768); /* PLR2 z */

    /* Store in level state - set pointers directly (bypass level_parse
     * since our test data isn't in the exact original header format) */
    level->data = buf;
    level->zone_adds = buf + off_zone_table;
    level->points = buf + off_points;
    level->floor_lines = buf + off_flines;
    level->object_data = buf + off_obj_data;
    level->object_points = buf + off_obj_points;
    level->plr1_obj = buf + off_obj_data;
    level->plr2_obj = buf + off_obj_data + OBJECT_SIZE;
    level->num_object_points = 2;
    level->num_zones = NUM_ZONES;
    level->point_brights = NULL; /* No per-point brightness for test level */

    /* Allocate player shot data (20 bullet slots for projectile weapons).
     * Each slot is OBJECT_SIZE bytes.  zone < 0 means the slot is free. */
    {
        int shot_slots = 20;
        int shot_buf_size = shot_slots * OBJECT_SIZE;
        uint8_t *shot_buf = (uint8_t *)calloc(1, (size_t)shot_buf_size);
        if (shot_buf) {
            /* Mark all slots as free (zone = -1) */
            for (int i = 0; i < shot_slots; i++) {
                wr16(shot_buf + i * OBJECT_SIZE + 12, -1); /* obj.zone = -1 */
            }
            level->player_shot_data = shot_buf;
        }
    }

    /* Allocate nasty shot data (20 enemy bullet slots + 64*20 extra) */
    {
        int nasty_shots = 20;
        int nasty_buf_size = nasty_shots * OBJECT_SIZE + 64 * 20;
        uint8_t *nasty_buf = (uint8_t *)calloc(1, (size_t)nasty_buf_size);
        if (nasty_buf) {
            for (int i = 0; i < nasty_shots; i++) {
                wr16(nasty_buf + i * OBJECT_SIZE + 12, -1);
            }
            level->nasty_shot_data = nasty_buf;
            level->other_nasty_data = nasty_buf + nasty_shots * OBJECT_SIZE;
        }
    }

    level->connect_table = NULL;
    level->water_list = NULL;
    level->bright_anim_list = NULL;

    printf("[IO] Test level: %d zones, %d points, %d lines, %d bytes\n",
           NUM_ZONES, NUM_POINTS, NUM_FLINES, total);
}

static void build_test_level_graphics(LevelState *level)
{
    /* Graphics data layout:
     *   [zone_graph_adds: NUM_ZONES * 8 bytes]  (lower gfx offset, upper gfx offset)
     *   [list_of_graph_rooms: (NUM_ZONES+1) * 8 bytes]  (zone_id, clip_off, flags, pad)
     *   [per-zone graphics: N * per_zone bytes]
     *   [zone_bright_table: 2*NUM_ZONES bytes]
     */

    int per_zone = 2 + (4 * 30) + 2; /* zone_num + 4 walls * 30 bytes each + sentinel */
    int graph_adds_size = NUM_ZONES * 8;
    int lgr_size = (NUM_ZONES + 1) * 8; /* +1 for -1 terminator */
    int bright_table_size = 2 * NUM_ZONES;
    int total = graph_adds_size + lgr_size + NUM_ZONES * per_zone + bright_table_size + 256;

    uint8_t *buf = (uint8_t *)calloc(1, (size_t)total);
    if (!buf) return;

    int off_lgr = graph_adds_size;
    int off_gfx_data = off_lgr + lgr_size;
    int off_bright = off_gfx_data + NUM_ZONES * per_zone;

    /* ---- Zone graph adds (8 bytes per zone: lower gfx offset, upper gfx offset) ---- */
    for (int z = 0; z < NUM_ZONES; z++) {
        int zone_gfx_off = off_gfx_data + z * per_zone;
        wr32(buf + z * 8, zone_gfx_off);       /* lower room graphics */
        wr32(buf + z * 8 + 4, 0);              /* no upper room */
    }

    /* ---- ListOfGraphRooms (8 bytes each: zone_id, clip_off, flags, pad) ---- */
    for (int z = 0; z < NUM_ZONES; z++) {
        uint8_t *lgr = buf + off_lgr + z * 8;
        wr16(lgr + 0, (int16_t)z);    /* zone id */
        wr16(lgr + 2, -1);            /* clip_offset = -1 (no clipping) */
        wr16(lgr + 4, 0);             /* flags */
        wr16(lgr + 6, 0);             /* pad */
    }
    /* Terminator */
    wr16(buf + off_lgr + NUM_ZONES * 8, -1);

    /* Room corner point indices:
     * Room 0: 0,1,4,3   Room 1: 1,2,5,4
     * Room 2: 3,4,7,6   Room 3: 4,5,8,7 */
    static const int room_pts[4][4] = {
        {0,1,4,3}, {1,2,5,4}, {3,4,7,6}, {4,5,8,7}
    };

    /* ---- Per-zone graphics (wall polygon data) ---- */
    for (int z = 0; z < NUM_ZONES; z++) {
        uint8_t *gfx = buf + off_gfx_data + z * per_zone;
        int p = 0;

        /* Zone number */
        wr16(gfx + p, (int16_t)z); p += 2;

        /* 4 walls: type 0 (wall), 28 bytes data each */
        for (int w = 0; w < 4; w++) {
            int p1 = room_pts[z][w];
            int p2 = room_pts[z][(w + 1) % 4];

            wr16(gfx + p, 0);          p += 2; /* type = wall */
            wr16(gfx + p, (int16_t)p1);p += 2; /* point1 */
            wr16(gfx + p, (int16_t)p2);p += 2; /* point2 */
            wr16(gfx + p, 0);          p += 2; /* strip_start */
            wr16(gfx + p, 127);        p += 2; /* strip_end */
            wr16(gfx + p, 0);          p += 2; /* texture_tile */
            wr16(gfx + p, 0);          p += 2; /* totalyoff */
            wr16(gfx + p, 0);          p += 2; /* texture_id */
            gfx[p++] = 63;                     /* VALAND */
            gfx[p++] = 0;                      /* VALSHIFT */
            wr16(gfx + p, 127);        p += 2; /* HORAND */
            wr32(gfx + p, ROOF_H);     p += 4; /* topofwall */
            wr32(gfx + p, FLOOR_H);    p += 4; /* botofwall */
            wr16(gfx + p, (int16_t)(w + z * 2)); p += 2; /* brightness */
        }

        /* End sentinel */
        wr16(gfx + p, -1);
    }

    /* ---- Zone brightness table ---- */
    {
        uint8_t *bt = buf + off_bright;
        for (int z = 0; z < NUM_ZONES; z++) {
            bt[z] = 8;                        /* Lower floor brightness */
            bt[z + NUM_ZONES] = 8;             /* Upper floor brightness */
        }
    }

    level->graphics = buf;
    level->zone_graph_adds = buf;              /* graph adds at start of buffer */
    level->list_of_graph_rooms = buf + off_lgr;
    level->zone_bright_table = buf + off_bright;

    printf("[IO] Graphics: zone_graph_adds@0, lgr@%d, gfx_data@%d, bright@%d\n",
           off_lgr, off_gfx_data, off_bright);
}

static void build_test_level_clips(LevelState *level)
{
    /* Minimal clips: just an empty clip list */
    int total = 256;
    uint8_t *buf = (uint8_t *)calloc(1, (size_t)total);
    if (!buf) return;
    /* Fill with -1 sentinels */
    for (int i = 0; i < total; i += 2) {
        wr16(buf + i, -1);
    }
    level->clips = buf;
}

/* -----------------------------------------------------------------------
 * Public API
 * ----------------------------------------------------------------------- */

/* Storage for loaded wall texture data (forward declaration for io_shutdown) */
static uint8_t *g_wall_data[MAX_WALL_TILES];

void io_init(void)
{
    printf("[IO] init\n");
    memset(g_wall_data, 0, sizeof(g_wall_data));
}

void io_shutdown(void)
{
    /* Free wall texture data */
    for (int i = 0; i < MAX_WALL_TILES; i++) {
        free(g_wall_data[i]);
        g_wall_data[i] = NULL;
    }
    printf("[IO] shutdown\n");
}

int io_load_level_data(LevelState *level, int level_num)
{
    /* Try to load real level data */
    char subpath[256], path[512];
    snprintf(subpath, sizeof(subpath),
             "levels/level_%c/twolev.bin", 'a' + level_num);
    make_data_path(path, sizeof(path), subpath);

    uint8_t *data = NULL;
    size_t size = 0;
    if (sb_load_file(path, &data, &size) == 0 && data) {
        level->data = data;
        printf("[IO] Loaded level data: %s (%zu bytes)\n", path, size);
        return 0;
    }

    /* Fallback: generate procedural test level */
    printf("[IO] Generating test level (level %d)\n", level_num);
    build_test_level_data(level);
    return 0;
}

int io_load_level_graphics(LevelState *level, int level_num)
{
    char subpath[256], path[512];
    snprintf(subpath, sizeof(subpath),
             "levels/level_%c/twolev.graph.bin", 'a' + level_num);
    make_data_path(path, sizeof(path), subpath);

    uint8_t *data = NULL;
    size_t size = 0;
    if (sb_load_file(path, &data, &size) == 0 && data) {
        level->graphics = data;
        printf("[IO] Loaded level graphics: %s (%zu bytes)\n", path, size);
        return 0;
    }

    /* Fallback */
    build_test_level_graphics(level);
    return 0;
}

int io_load_level_clips(LevelState *level, int level_num)
{
    char subpath[256], path[512];
    snprintf(subpath, sizeof(subpath),
             "levels/level_%c/twolev.clips", 'a' + level_num);
    make_data_path(path, sizeof(path), subpath);

    uint8_t *data = NULL;
    size_t size = 0;
    if (sb_load_file(path, &data, &size) == 0 && data) {
        level->clips = data;
        printf("[IO] Loaded level clips: %s (%zu bytes)\n", path, size);
        return 0;
    }

    /* Fallback */
    build_test_level_clips(level);
    return 0;
}

void io_release_level_memory(LevelState *level)
{
    /* player_shot_data and nasty_shot_data point into the data buffer
     * when loaded from real files (level_parse resolves them as offsets
     * into level->data). Only free them if they DON'T point into data. */
    if (level->player_shot_data && level->data) {
        uint8_t *d = level->data;
        if (level->player_shot_data < d || level->player_shot_data > d + 1024*1024) {
            free(level->player_shot_data);
        }
    }
    level->player_shot_data = NULL;

    if (level->nasty_shot_data && level->data) {
        uint8_t *d = level->data;
        if (level->nasty_shot_data < d || level->nasty_shot_data > d + 1024*1024) {
            free(level->nasty_shot_data);
        }
    }
    level->nasty_shot_data = NULL;
    level->other_nasty_data = NULL;

    free(level->workspace);         level->workspace = NULL;
    free(level->zone_bright_table); level->zone_bright_table = NULL;

    /* list_of_graph_rooms now points into level->data (zone_data + 48),
     * so it must NOT be freed separately. Just NULL it. */
    level->list_of_graph_rooms = NULL;

    free(level->data);              level->data = NULL;
    free(level->graphics);          level->graphics = NULL;
    free(level->clips);             level->clips = NULL;

    /* Clear remaining pointers (they pointed into the freed buffers) */
    level->door_data = NULL;
    level->lift_data = NULL;
    level->switch_data = NULL;
    level->zone_graph_adds = NULL;
    level->zone_adds = NULL;
    level->points = NULL;
    level->point_brights = NULL;
    level->floor_lines = NULL;
    level->object_data = NULL;
    level->object_points = NULL;
    level->plr1_obj = NULL;
    level->plr2_obj = NULL;
    level->connect_table = NULL;
    level->water_list = NULL;
    level->bright_anim_list = NULL;
}

/* Wall texture table - matches WallChunk.s wallchunkdata ordering.
 * Each entry: { filename (under includes/walls/), unpacked_size }
 * The order matches the walltiles[] index used by level graphics data. */
static const struct {
    const char *name;
    int unpacked_size;
} wall_texture_table[] = {
    { "GreenMechanic.wad",  18560 },
    { "BlueGreyMetal.wad",  13056 },
    { "TechnoDetail.wad",   13056 },
    { "BlueStone.wad",       4864 },
    { "RedAlert.wad",        7552 },
    { "rock.wad",           10368 },
    { "scummy.wad",         13056 },
    { "stairfronts.wad",     2400 },
    { "BIGDOOR.wad",        13056 },
    { "RedRock.wad",        13056 },
    { "dirt.wad",           24064 },
    { "switches.wad",        3456 },
    { "shinymetal.wad",     24064 },
    { "bluemechanic.wad",   15744 },
    { NULL, 0 }
};

void io_load_walls(void)
{
    printf("[IO] Loading wall textures...\n");

    /* Access the global renderer state to set walltiles pointers */
    extern RendererState g_renderer;

    for (int i = 0; i < MAX_WALL_TILES; i++) {
        g_wall_data[i] = NULL;
        g_renderer.walltiles[i] = NULL;
        g_renderer.wall_palettes[i] = NULL;
    }

    for (int i = 0; wall_texture_table[i].name; i++) {
        if (i >= MAX_WALL_TILES) break;

        char subpath[256], path[512];
        snprintf(subpath, sizeof(subpath), "includes/walls/%s",
                 wall_texture_table[i].name);
        make_data_path(path, sizeof(path), subpath);

        uint8_t *data = NULL;
        size_t size = 0;
        if (sb_load_file(path, &data, &size) == 0 && data) {
            g_wall_data[i] = data;
            /* wall_palettes points to the 2048-byte brightness LUT at the
             * START of the .wad data (ASM: PaletteAddr = walltiles[id]).
             * walltiles points past the LUT to the chunky pixel data
             * (ASM: ChunkAddr = walltiles[id] + 64*32). */
            g_renderer.wall_palettes[i] = data;
            g_renderer.walltiles[i] = (size > 2048) ? data + 2048 : data;
            printf("[IO] Wall %2d: %s (%zu bytes)\n", i,
                   wall_texture_table[i].name, size);
        } else {
            printf("[IO] Wall %2d: %s (not found)\n", i,
                   wall_texture_table[i].name);
        }
    }
}

void io_load_floor(void)
{
    printf("[IO] Loading floor texture...\n");

    char path[512];
    make_data_path(path, sizeof(path), "includes/floortile");

    /* Floor tile is raw (uncompressed) 256x256 = 65536 bytes */
    FILE *f = fopen(path, "rb");
    if (f) {
        fseek(f, 0, SEEK_END);
        long len = ftell(f);
        fseek(f, 0, SEEK_SET);

        uint8_t *data = (uint8_t *)malloc((size_t)len);
        if (data) {
            fread(data, 1, (size_t)len, f);
            printf("[IO] Floor tile: %ld bytes\n", len);
            /* TODO: assign to renderer floor texture pointer */
        }
        fclose(f);
        free(data); /* For now we load but don't use - needs renderer support */
    } else {
        printf("[IO] Floor tile not found: %s\n", path);
    }
}

void io_load_objects(void)  { printf("[IO] load_objects (stub)\n"); }
void io_load_sfx(void)     { printf("[IO] load_sfx (stub)\n"); }
void io_load_panel(void)   { printf("[IO] load_panel (stub)\n"); }

void io_load_prefs(char *prefs_buf, int buf_size)
{
    (void)prefs_buf; (void)buf_size;
}
void io_save_prefs(const char *prefs_buf, int buf_size)
{
    (void)prefs_buf; (void)buf_size;
}
void io_load_passwords(void) { }
void io_save_passwords(void) { }
