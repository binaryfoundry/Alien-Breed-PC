/*
 * Alien Breed 3D I - PC Port
 * stub_input.h - Stubbed input subsystem
 *
 * Replaces Amiga-specific input:
 *   - Keyboard interrupt handler (key_interrupt / KeyInt)
 *   - Mouse reading (ReadMouse / $dff00a)
 *   - Joystick reading (_ReadJoy1, _ReadJoy2, CD32Joy)
 *   - Hardware port polling ($bfe001)
 *
 * When a real input system is added (SDL2, etc.), these stubs
 * get replaced with actual implementations.
 */

#ifndef STUB_INPUT_H
#define STUB_INPUT_H

#include "game_types.h"
#include <stdint.h>
#include <stdbool.h>

/* Lifecycle */
void input_init(void);
void input_shutdown(void);

/* Per-frame polling */
void input_update(uint8_t *key_map, uint8_t *last_pressed);

/* Mouse */
typedef struct {
    int16_t dx;
    int16_t dy;
    bool    left_button;
    bool    right_button;
} MouseState;

void input_read_mouse(MouseState *out);

/* Joystick */
typedef struct {
    int16_t dx;
    int16_t dy;
    bool    fire;
} JoyState;

void input_read_joy1(JoyState *out);
void input_read_joy2(JoyState *out);

/* Convenience: check if a specific key is pressed */
bool input_key_pressed(const uint8_t *key_map, uint8_t keycode);

/* Clear keyboard state */
void input_clear_keyboard(uint8_t *key_map);

#endif /* STUB_INPUT_H */
