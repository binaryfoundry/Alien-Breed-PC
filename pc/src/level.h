/*
 * Alien Breed 3D I - PC Port
 * level.h - Level data parsing and initialization
 *
 * Translated from: AB3DI.s blag: section (~line 722-848),
 *                  LevelData2.s (InitPlayer, data pointers)
 *
 * Level data comes in three files:
 *   disk/levels/level_X/twolev.bin        - Level geometry & objects
 *   disk/levels/level_X/twolev.graph.bin  - Zone graphics data
 *   disk/levels/level_X/twolev.clips      - Clip/visibility data
 *
 * All three are LHA-compressed in the original. The raw data has a
 * specific header format with offsets to sub-structures.
 */

#ifndef LEVEL_H
#define LEVEL_H

#include "game_state.h"

/*
 * Parse loaded level data and resolve all internal pointers.
 *
 * Translated from AB3DI.s blag: section.
 *
 * Level data header (twolev.bin):
 *   Word  0: PLR1 start X
 *   Word  1: PLR1 start Z
 *   Word  2: PLR1 start zone
 *   Word  3: PLR2 start X
 *   Word  4: PLR2 start Z
 *   Word  5: PLR2 start zone
 *   Word  6: unused
 *   Word  7: Number of points
 *   Word  8: unused
 *   Word  9: unused
 *   Word 10: Number of object points
 *   Long 11: Offset to points
 *   Long 13: Offset to floor lines
 *   Long 15: Offset to object data
 *   Long 17: Offset to player shot data
 *   Long 19: Offset to nasty shot data
 *   Long 21: Offset to object points
 *   Long 23: Offset to player 1 object
 *   Long 25: Offset to player 2 object
 *   Word 16: Number of zones (in graphics data)
 *
 * Graphics data header (twolev.graph.bin):
 *   Long  0: Offset to door data
 *   Long  1: Offset to lift data
 *   Long  2: Offset to switch data
 *   Long  3: Offset to zone graph adds
 *   Then: zone offset table (one long per zone)
 */
int level_parse(LevelState *level);

/*
 * Assign clip data to zone graph lists.
 * Translated from AB3DI.s assignclips loop (~line 812-843).
 */
void level_assign_clips(LevelState *level, int16_t num_zones);

#endif /* LEVEL_H */
