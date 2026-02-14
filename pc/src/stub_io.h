/*
 * Alien Breed 3D I - PC Port
 * stub_io.h - Stubbed file I/O subsystem
 *
 * Replaces Amiga-specific I/O:
 *   - dos.library file operations (Open/Read/Close)
 *   - LoadFromDisk.s routines (LoadWalls, LoadFloor, LoadObjects, LoadSFX, LoadPanel)
 *   - LHA decompression (UnLHA)
 *   - Level loading
 *   - Prefs/password save/load
 *
 * Eventually these will use standard C file I/O to load
 * game data from the original Amiga data files.
 */

#ifndef STUB_IO_H
#define STUB_IO_H

#include "game_state.h"

/* Lifecycle */
void io_init(void);
void io_shutdown(void);

/* Level loading */
int  io_load_level_data(LevelState *level, int level_num);
int  io_load_level_graphics(LevelState *level, int level_num);
int  io_load_level_clips(LevelState *level, int level_num);
void io_release_level_memory(LevelState *level);

/* Asset loading */
void io_load_walls(void);
void io_load_floor(void);
void io_load_gun_graphics(void);

/* Debug: dump all loaded textures as BMP images into textures/ */
void io_dump_textures(void);
void io_load_objects(void);
void io_load_sfx(void);
void io_load_panel(void);

/* Prefs */
void io_load_prefs(char *prefs_buf, int buf_size);
void io_save_prefs(const char *prefs_buf, int buf_size);

/* Passwords */
void io_load_passwords(void);
void io_save_passwords(void);

#endif /* STUB_IO_H */
