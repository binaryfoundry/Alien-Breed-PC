/*
 * Alien Breed 3D I - PC Port
 * math_tables.h - Sine/cosine table and math utilities
 *
 * The original game uses a 4096-entry sine table stored in data/math/bigsine.
 * Angles are 14-bit: 0-8191, but only even indices are used (mask with 8190).
 * So effectively 4096 angle steps for a full circle.
 * Each entry is a signed 16-bit word.
 *
 * Cosine is just sine offset by 1024 entries (2048 bytes = 90 degrees).
 *
 * Access pattern:
 *   sin(angle) = SineTable[angle & 8190]    (byte-indexed, word values)
 *   cos(angle) = SineTable[(angle + 2048) & 8190]
 */

#ifndef MATH_TABLES_H
#define MATH_TABLES_H

#include <stdint.h>

/* Table size constants */
#define ANGLE_TABLE_SIZE    4096    /* number of entries */
#define ANGLE_MASK          8190    /* byte-index mask: (4096-1)*2 */
#define ANGLE_90            2048    /* 90 degree offset in bytes */
#define ANGLE_180           4096    /* 180 degree offset in bytes */
#define ANGLE_270           6144    /* 270 degree offset in bytes */
#define ANGLE_FULL          8192    /* full circle in bytes */

/* The sine table (4096 int16_t values) */
extern int16_t sine_table[ANGLE_TABLE_SIZE];

/* Initialize the sine table (generates values matching Amiga binary) */
void math_tables_init(void);

/*
 * Lookup sin/cos by byte-index angle (matching original ASM convention).
 * angle should be masked with ANGLE_MASK before calling, or these do it.
 */
static inline int16_t sin_lookup(int angle)
{
    return sine_table[(angle & ANGLE_MASK) >> 1];
}

static inline int16_t cos_lookup(int angle)
{
    return sine_table[((angle + ANGLE_90) & ANGLE_MASK) >> 1];
}

/*
 * Distance calculation (from ObjectMove.s CalcDist).
 * Returns approximate distance using |dx|+|dz| with correction.
 */
static inline int32_t calc_dist_approx(int32_t dx, int32_t dz)
{
    if (dx < 0) dx = -dx;
    if (dz < 0) dz = -dz;
    /* The original uses max(|dx|,|dz|) + min(|dx|,|dz|)/2 approximation */
    if (dx > dz)
        return dx + (dz >> 1);
    else
        return dz + (dx >> 1);
}

#endif /* MATH_TABLES_H */
