/*
 * Alien Breed 3D I - PC Port
 * display.c - SDL2 display backend
 *
 * Creates a window, takes the chunky buffer from the software renderer,
 * converts it through a palette to RGB, and presents it on screen.
 */

#include "display.h"
#include "renderer.h"
#include <SDL.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* -----------------------------------------------------------------------
 * SDL2 state
 * ----------------------------------------------------------------------- */
static SDL_Window   *g_window   = NULL;
static SDL_Renderer *g_sdl_ren  = NULL;
static SDL_Texture  *g_texture  = NULL;
static int g_present_width = 0;
static int g_present_height = 0;
static int g_render_target_w = RENDER_WIDTH;
static int g_render_target_h = RENDER_HEIGHT;
static int g_use_fixed_renderer_size = 0;

/* Window size = framebuffer size for 1:1 pixels (no scaling). */
#define WINDOW_W  RENDER_WIDTH
#define WINDOW_H  RENDER_HEIGHT

#ifdef AB3D_RELEASE
/* Release: default renderer target (configurable via AB3D_RENDER_RES). */
#define AB3D_RELEASE_DEFAULT_W 1280
#define AB3D_RELEASE_DEFAULT_H 720
static int s_release_render_w = AB3D_RELEASE_DEFAULT_W;
static int s_release_render_h = AB3D_RELEASE_DEFAULT_H;
static int read_release_resolution(void)
{
    const char *env = getenv("AB3D_RENDER_RES");
    if (!env) return 0;
    int w = 0, h = 0;
    if (sscanf(env, "%dx%d", &w, &h) == 2) {
        if (w >= 96 && h >= 80) {
            s_release_render_w = w;
            s_release_render_h = h;
            return 1;
        }
    }
    return 0;
}
#endif

/* Legacy palette no longer needed - colors come from the .wad LUT data
 * and are written directly to the rgb_buffer as ARGB8888 pixels. */

/* -----------------------------------------------------------------------
 * Renderer scaling helper
 * ----------------------------------------------------------------------- */
static void display_set_renderer_target_size(int w, int h)
{
    if (w < 1 || h < 1) return;
    printf("[DISPLAY] renderer target: %dx%d\n", w, h);
    renderer_resize(w, h);
    renderer_set_present_size(w, h);
    g_render_target_w = w;
    g_render_target_h = h;
    if (g_texture) SDL_DestroyTexture(g_texture);
    g_texture = SDL_CreateTexture(g_sdl_ren,
        SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
        g_render_target_w, g_render_target_h);
    if (g_texture) SDL_SetTextureScaleMode(g_texture, SDL_ScaleModeNearest);
}

/* -----------------------------------------------------------------------
 * Lifecycle
 * ----------------------------------------------------------------------- */
void display_init(void)
{
#ifdef AB3D_RELEASE
    read_release_resolution();
    g_use_fixed_renderer_size = 1;
#endif
    printf("[DISPLAY] SDL2 init\n");

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("[DISPLAY] SDL_Init failed: %s\n", SDL_GetError());
        return;
    }

    renderer_init();
    int init_w = renderer_get_width();
    int init_h = renderer_get_height();
    int window_w = init_w;
    int window_h = init_h;

#ifdef AB3D_RELEASE
    window_w = s_release_render_w;
    window_h = s_release_render_h;
#endif

    g_window = SDL_CreateWindow(
        "Alien Breed 3D I",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        window_w, window_h,
        SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
    );
    if (!g_window) {
        printf("[DISPLAY] SDL_CreateWindow failed: %s\n", SDL_GetError());
        return;
    }

    g_present_width = window_w;
    g_present_height = window_h;

#ifdef AB3D_RELEASE
    if (SDL_SetWindowFullscreen(g_window, SDL_WINDOW_FULLSCREEN_DESKTOP) != 0) {
        printf("[DISPLAY] SDL_SetWindowFullscreenDesktop failed: %s\n", SDL_GetError());
    }
    SDL_PumpEvents();
#endif

    g_sdl_ren = SDL_CreateRenderer(g_window, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!g_sdl_ren) {
        printf("[DISPLAY] SDL_CreateRenderer failed: %s\n", SDL_GetError());
        return;
    }

    // Release build can fix the renderer target size ahead of time.
#ifdef AB3D_RELEASE
    if (g_use_fixed_renderer_size) {
        display_set_renderer_target_size(s_release_render_w, s_release_render_h);
    } else
#endif
    {
        int out_w = init_w;
        int out_h = init_h;
        if (SDL_GetRendererOutputSize(g_sdl_ren, &out_w, &out_h) != 0) {
            out_w = init_w;
            out_h = init_h;
        }
        if (out_w < 96) out_w = 96;
        if (out_h < 80) out_h = 80;
        display_set_renderer_target_size(out_w, out_h);
    }

    printf("[DISPLAY] SDL2 ready: %dx%d (resizable)\n", window_w, window_h);
}

void display_on_resize(int w, int h)
{
    if (w < 1 || h < 1) return;
    printf("[DISPLAY] resize: %dx%d\n", w, h);
    if (g_use_fixed_renderer_size) {
        renderer_set_present_size(w, h);
        g_present_width = w;
        g_present_height = h;
        return;
    }
    display_set_renderer_target_size(w, h);
    g_present_width = w;
    g_present_height = h;
}

void display_handle_resize(void)
{
    if (!g_sdl_ren) return;
    if (g_use_fixed_renderer_size) return;
    int out_w = 0, out_h = 0;
#ifdef AB3D_RELEASE
    /* Same as display_init: output size query can be wrong in fullscreen desktop. */
    if (g_window && (SDL_GetWindowFlags(g_window) & SDL_WINDOW_FULLSCREEN_DESKTOP) != 0) {
        SDL_DisplayMode dm;
        if (SDL_GetWindowDisplayMode(g_window, &dm) == 0 && dm.w >= 96 && dm.h >= 80) {
            out_w = dm.w;
            out_h = dm.h;
        }
    }
#endif
    if (out_w < 96 || out_h < 80) {
        if (SDL_GetRendererOutputSize(g_sdl_ren, &out_w, &out_h) != 0) return;
    }
    if (out_w < 96) out_w = 96;
    if (out_h < 80) out_h = 80;
    printf("[DISPLAY] handle_resize: renderer output %dx%d\n", out_w, out_h);
    display_on_resize(out_w, out_h);
}

int display_is_fullscreen(void)
{
    if (!g_window) return 0;
    return (SDL_GetWindowFlags(g_window) & (SDL_WINDOW_FULLSCREEN | SDL_WINDOW_FULLSCREEN_DESKTOP)) != 0;
}

void display_shutdown(void)
{
    renderer_shutdown();
    if (g_texture)  SDL_DestroyTexture(g_texture);
    if (g_sdl_ren)  SDL_DestroyRenderer(g_sdl_ren);
    if (g_window)   SDL_DestroyWindow(g_window);
    SDL_Quit();
    printf("[DISPLAY] SDL2 shutdown\n");
}

/* -----------------------------------------------------------------------
 * Screen management (no-ops for SDL2)
 * ----------------------------------------------------------------------- */
void display_alloc_text_screen(void)        { }
void display_release_text_screen(void)      { }
void display_alloc_copper_screen(void)      { }
void display_release_copper_screen(void)    { }
void display_alloc_title_memory(void)       { }
void display_release_title_memory(void)     { }
void display_alloc_panel_memory(void)       { }
void display_release_panel_memory(void)     { }

void display_setup_title_screen(void)       { }
void display_load_title_screen(void)        { }
void display_clear_opt_screen(void)         { }
void display_draw_opt_screen(int screen_num) { (void)screen_num; }
void display_fade_up_title(int amount)      { (void)amount; }
void display_fade_down_title(int amount)    { (void)amount; }
void display_clear_title_palette(void)      { }

void display_init_copper_screen(void)       { }

/* -----------------------------------------------------------------------
 * Main rendering
 * ----------------------------------------------------------------------- */
void display_draw_display(GameState *state)
{
    /* 1. Software-render the 3D scene into the rgb buffer */
    renderer_draw_display(state);

    /* 2. Copy 32-bit ARGB rgb_buffer directly to SDL texture */
    if (!g_texture || !g_sdl_ren) return;

    const uint32_t *src = renderer_get_rgb_buffer();
    if (!src) return;

    uint32_t *pixels;
    int pitch;
    if (SDL_LockTexture(g_texture, NULL, (void**)&pixels, &pitch) < 0) return;

    int w = renderer_get_width(), h = renderer_get_height();
    const size_t row_bytes = (size_t)w * sizeof(uint32_t);
    if (pitch == (int)(w * sizeof(uint32_t))) {
        memcpy(pixels, src, row_bytes * (size_t)h);
    } else {
        for (int y = 0; y < h; y++) {
            uint32_t *dst_row = (uint32_t*)((uint8_t*)pixels + (size_t)y * pitch);
            memcpy(dst_row, src + (size_t)y * w, row_bytes);
        }
    }

    SDL_UnlockTexture(g_texture);

    /* 3. Present to screen (no RenderClear – full texture overwrites target) */
    SDL_RenderCopy(g_sdl_ren, g_texture, NULL, NULL);
    SDL_RenderPresent(g_sdl_ren);

    /* Debug: show player position in window title (throttled) */
    {
        static int title_frame = 0;
        if ((++title_frame % 30) == 0) {
            PlayerState *dbg_plr = &state->plr1;
            char title[128];
            snprintf(title, sizeof(title), "AB3D - Pos(%d,%d) Zone=%d Ang=%d",
                     (int)(dbg_plr->xoff >> 16), (int)(dbg_plr->zoff >> 16),
                     dbg_plr->zone, dbg_plr->angpos);
            SDL_SetWindowTitle(g_window, title);
        }
    }
}

void display_swap_buffers(void)
{
    /* Handled in display_draw_display */
}

void display_wait_vblank(void)
{
    /* VSync is handled by SDL_RENDERER_PRESENTVSYNC */
}

/* -----------------------------------------------------------------------
 * HUD
 * ----------------------------------------------------------------------- */
void display_energy_bar(int16_t energy)
{
    uint32_t *rgb = g_renderer.rgb_buffer;
    if (!rgb) return;
    int w = g_renderer.width, h = g_renderer.height;
    int bar_y = h - 2;
    int bar_w = (energy > 0) ? ((int)energy * (w - 4) / 127) : 0;
    for (int x = 2; x < 2 + bar_w && x < w - 2; x++) {
        rgb[bar_y * w + x] = 0xFF00CC00;
        rgb[(bar_y - 1) * w + x] = 0xFF00CC00;
    }
}

void display_ammo_bar(int16_t ammo)
{
    uint32_t *rgb = g_renderer.rgb_buffer;
    if (!rgb) return;
    int w = g_renderer.width, h = g_renderer.height;
    int bar_y = h - 5;
    int max_ammo = 999;
    int bar_w = (ammo > 0) ? ((int)ammo * (w - 4) / max_ammo) : 0;
    if (bar_w > w - 4) bar_w = w - 4;
    for (int x = 2; x < 2 + bar_w && x < w - 2; x++) {
        rgb[bar_y * w + x] = 0xFFCCCC00;
        rgb[(bar_y - 1) * w + x] = 0xFFCCCC00;
    }
}

/* -----------------------------------------------------------------------
 * Text (minimal for now)
 * ----------------------------------------------------------------------- */
void display_draw_line_of_text(const char *text, int line)
{
    (void)text;
    (void)line;
}

void display_clear_text_screen(void)
{
}
