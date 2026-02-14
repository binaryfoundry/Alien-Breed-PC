/*
 * Alien Breed 3D I - PC Port
 * control_loop.h - Outer control loop (menu, level management)
 *
 * Translated from: ControlLoop.s
 *
 * This is the outer loop that:
 * 1. Shows title screen / plays title music
 * 2. Loads shared assets (walls, floor, objects, SFX)
 * 3. Presents menu and handles option selection
 * 4. Loads levels and launches PlayTheGame
 * 5. Returns to menu after death/level complete
 */

#ifndef CONTROL_LOOP_H
#define CONTROL_LOOP_H

#include "game_state.h"

/* PlayGame - the top-level game loop (ControlLoop.s: PlayGame) */
void play_game(GameState *state);

/* PlayTheGame - level gameplay (AB3DI.s: PlayTheGame) */
void play_the_game(GameState *state);

/* Menu */
int  read_main_menu(GameState *state);

/* Password system (ControlLoop.s CalcPassword, PassLineToGame, GetStats) */
void calc_password(GameState *state);
int  pass_line_to_game(GameState *state, const char *password);

#endif /* CONTROL_LOOP_H */
