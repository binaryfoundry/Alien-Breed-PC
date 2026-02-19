/*
 * Alien Breed 3D I - PC Port
 * math_tables.c - Sine table generation
 *
 * Generates a 4096-entry sine table with values in the range ~[-16384, 16384].
 * The original Amiga table is stored in data/math/bigsine as raw binary.
 * We generate it from scratch using the same scale factor.
 *
 * The Amiga 68000 code uses 16-bit signed words multiplied together
 * (muls instruction), so the sine table values are scaled to ~16384
 * (2^14) to fit nicely in 16-bit math:
 *   sin_table[i] = (int16_t)(sin(i * 2 * PI / 4096) * 16384)
 */

#include "math_tables.h"
#include <math.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

int16_t sine_table[ANGLE_TABLE_SIZE];

void math_tables_init(void)
{
    for (int i = 0; i < ANGLE_TABLE_SIZE; i++) {
        double angle = (double)i * 2.0 * M_PI / (double)ANGLE_TABLE_SIZE;
        double val = sin(angle) * 16384.0;
        /* Round to nearest and clamp to int16_t range */
        if (val >= 0)
            sine_table[i] = (int16_t)(val + 0.5);
        else
            sine_table[i] = (int16_t)(val - 0.5);
    }
}
