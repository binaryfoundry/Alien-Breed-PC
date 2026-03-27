/*
 * settings.h - Optional INI next to executable (start level, cheats).
 */

#ifndef SETTINGS_H
#define SETTINGS_H

#include "game_state.h"

/* Load ab3d.ini or ab3d.ini.template from SDL_GetBasePath(). Call after SDL_Init. */
void settings_load(GameState *state);

/* One-line summary of INI-backed fields (same values as at startup). Call where useful for logs. */
void settings_log_recap(const GameState *state);

#endif
