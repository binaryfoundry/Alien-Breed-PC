/*
 * Alien Breed 3D I - PC Port
 * stub_display.c - SDL2 display backend
 *
 * Creates a window, takes the chunky buffer from the software renderer,
 * converts it through a palette to RGB, and presents it on screen.
 */

#include "stub_display.h"
#include "renderer.h"
#include <SDL.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#ifndef COBJMACROS
#define COBJMACROS
#endif
#include <windows.h>
#include <dxgi1_6.h>
#include <SDL_syswm.h>
#endif

/* -----------------------------------------------------------------------
 * SDL2 state
 * ----------------------------------------------------------------------- */
static SDL_Window   *g_window   = NULL;
static SDL_Renderer *g_sdl_ren  = NULL;
static SDL_Texture  *g_texture  = NULL;
static int g_windows_hdr_active = 0;
static int g_hdr_sdr_fix_enabled = 0;
static int g_hdr_fix_override = -1; /* -1 = auto, 0 = force off, 1 = force on */
static Uint32 g_hdr_last_probe_ms = 0;
static float g_hdr_sdr_fix_strength = 0.30f; /* 0=off, 1=full linearization */
static uint8_t g_hdr_srgb_to_linear_lut[256];
static int g_hdr_lut_ready = 0;

/* Window size = framebuffer size for 1:1 pixels (no scaling). */
#define WINDOW_W  RENDER_WIDTH
#define WINDOW_H  RENDER_HEIGHT

#ifdef AB3D_RELEASE
/* Release: exclusive fullscreen at 720p (not desktop / borderless resolution). */
#define AB3D_RELEASE_FS_W 1280
#define AB3D_RELEASE_FS_H 720
#endif

/* Legacy palette no longer needed - colors come from the .wad LUT data
 * and are written directly to the rgb_buffer as ARGB8888 pixels. */

static int display_parse_hdr_override(void)
{
    const char *env = SDL_getenv("AB3D_HDR_SDR_FIX");
    if (!env || !*env) return -1;

    if (strcmp(env, "1") == 0 ||
        SDL_strcasecmp(env, "on") == 0 ||
        SDL_strcasecmp(env, "true") == 0 ||
        SDL_strcasecmp(env, "yes") == 0) {
        return 1;
    }

    if (strcmp(env, "0") == 0 ||
        SDL_strcasecmp(env, "off") == 0 ||
        SDL_strcasecmp(env, "false") == 0 ||
        SDL_strcasecmp(env, "no") == 0) {
        return 0;
    }

    return -1;
}

static float display_parse_hdr_strength(void)
{
    const char *env = SDL_getenv("AB3D_HDR_SDR_FIX_STRENGTH");
    if (!env || !*env) return 0.30f;

    char *endptr = NULL;
    double value = strtod(env, &endptr);
    if (endptr == env || value != value) return 0.30f;
    if (value < 0.0) value = 0.0;
    if (value > 1.0) value = 1.0;
    return (float)value;
}

static void display_build_hdr_sdr_lut(void)
{
    if (g_hdr_lut_ready) return;
    for (int i = 0; i < 256; i++) {
        float srgb = (float)i / 255.0f;
        float linear = (srgb <= 0.04045f)
                     ? (srgb / 12.92f)
                     : powf((srgb + 0.055f) / 1.055f, 2.4f);
        float corrected = srgb + (linear - srgb) * g_hdr_sdr_fix_strength;
        int mapped = (int)(corrected * 255.0f + 0.5f);
        if (mapped < 0) mapped = 0;
        if (mapped > 255) mapped = 255;
        g_hdr_srgb_to_linear_lut[i] = (uint8_t)mapped;
    }
    g_hdr_lut_ready = 1;
}

static inline uint32_t display_apply_hdr_sdr_fix(uint32_t argb)
{
    uint32_t a = argb & 0xFF000000u;
    uint32_t r = (uint32_t)g_hdr_srgb_to_linear_lut[(argb >> 16) & 0xFFu] << 16;
    uint32_t g = (uint32_t)g_hdr_srgb_to_linear_lut[(argb >> 8) & 0xFFu] << 8;
    uint32_t b = (uint32_t)g_hdr_srgb_to_linear_lut[argb & 0xFFu];
    return a | r | g | b;
}

#ifdef _WIN32
static int display_is_hdr_colorspace(DXGI_COLOR_SPACE_TYPE color_space)
{
    return (color_space == DXGI_COLOR_SPACE_RGB_FULL_G2084_NONE_P2020) ||
           (color_space == DXGI_COLOR_SPACE_RGB_STUDIO_G2084_NONE_P2020) ||
           (color_space == DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709);
}

static int display_windows_detect_hdr(SDL_Window *window, int *hdr_active)
{
    if (!window || !hdr_active) return 0;
    *hdr_active = 0;

    SDL_SysWMinfo wm;
    SDL_VERSION(&wm.version);
    if (!SDL_GetWindowWMInfo(window, &wm)) return 0;
    if (wm.subsystem != SDL_SYSWM_WINDOWS || !wm.info.win.window) return 0;

    HMONITOR target_monitor = MonitorFromWindow(wm.info.win.window, MONITOR_DEFAULTTONEAREST);
    if (!target_monitor) return 0;

    IDXGIFactory1 *factory = NULL;
    HRESULT hr = CreateDXGIFactory1(&IID_IDXGIFactory1, (void **)&factory);
    if (FAILED(hr) || !factory) return 0;

    int found = 0;
    int hdr = 0;

    for (UINT adapter_index = 0; ; adapter_index++) {
        IDXGIAdapter1 *adapter = NULL;
        hr = IDXGIFactory1_EnumAdapters1(factory, adapter_index, &adapter);
        if (hr == DXGI_ERROR_NOT_FOUND) break;
        if (FAILED(hr) || !adapter) continue;

        for (UINT output_index = 0; ; output_index++) {
            IDXGIOutput *output = NULL;
            hr = IDXGIAdapter1_EnumOutputs(adapter, output_index, &output);
            if (hr == DXGI_ERROR_NOT_FOUND) break;
            if (FAILED(hr) || !output) continue;

            DXGI_OUTPUT_DESC desc;
            if (SUCCEEDED(IDXGIOutput_GetDesc(output, &desc)) &&
                desc.Monitor == target_monitor) {
                found = 1;
                IDXGIOutput6 *output6 = NULL;
                if (SUCCEEDED(IDXGIOutput_QueryInterface(output, &IID_IDXGIOutput6,
                                                         (void **)&output6)) && output6) {
                    DXGI_OUTPUT_DESC1 desc1;
                    if (SUCCEEDED(IDXGIOutput6_GetDesc1(output6, &desc1))) {
                        hdr = display_is_hdr_colorspace(desc1.ColorSpace);
                    }
                    IDXGIOutput6_Release(output6);
                }
                IDXGIOutput_Release(output);
                break;
            }

            IDXGIOutput_Release(output);
        }

        IDXGIAdapter1_Release(adapter);
        if (found) break;
    }

    IDXGIFactory1_Release(factory);
    if (!found) return 0;
    *hdr_active = hdr;
    return 1;
}
#endif

static void display_refresh_hdr_state(int force_log)
{
    int prev_hdr = g_windows_hdr_active;
    int prev_fix = g_hdr_sdr_fix_enabled;
    int detected = 0;

#ifdef _WIN32
    int hdr_active = 0;
    detected = display_windows_detect_hdr(g_window, &hdr_active);
    g_windows_hdr_active = detected ? hdr_active : 0;
#else
    g_windows_hdr_active = 0;
#endif

    if (g_hdr_fix_override >= 0) {
        g_hdr_sdr_fix_enabled = g_hdr_fix_override ? 1 : 0;
    } else {
        g_hdr_sdr_fix_enabled = g_windows_hdr_active ? 1 : 0;
    }

    if (g_hdr_sdr_fix_enabled) {
        display_build_hdr_sdr_lut();
    }

    if (force_log || prev_hdr != g_windows_hdr_active || prev_fix != g_hdr_sdr_fix_enabled) {
        const char *override_mode = (g_hdr_fix_override < 0)
                                  ? "auto"
                                  : (g_hdr_fix_override ? "force-on" : "force-off");
        if (detected) {
            printf("[DISPLAY] Windows HDR: %s, SDR fix: %s (%s, strength=%.2f)\n",
                   g_windows_hdr_active ? "on" : "off",
                   g_hdr_sdr_fix_enabled ? "on" : "off",
                   override_mode,
                   g_hdr_sdr_fix_strength);
        } else {
            printf("[DISPLAY] Windows HDR detection unavailable, SDR fix: %s (%s, strength=%.2f)\n",
                   g_hdr_sdr_fix_enabled ? "on" : "off",
                   override_mode,
                   g_hdr_sdr_fix_strength);
        }
    }
}

static void display_maybe_refresh_hdr_state(void)
{
    if (g_hdr_fix_override >= 0) return;
    Uint32 now = SDL_GetTicks();
    if ((now - g_hdr_last_probe_ms) < 2000u) return;
    g_hdr_last_probe_ms = now;
    display_refresh_hdr_state(0);
}

/* -----------------------------------------------------------------------
 * Lifecycle
 * ----------------------------------------------------------------------- */
void display_init(void)
{
#ifdef AB3D_RELEASE
    /* Actual fullscreen mode dimensions (renderer buffer must match). */
    int release_fs_w = AB3D_RELEASE_FS_W;
    int release_fs_h = AB3D_RELEASE_FS_H;
#endif
    printf("[DISPLAY] SDL2 init\n");

    if (SDL_Init(SDL_INIT_VIDEO) < 0) {
        printf("[DISPLAY] SDL_Init failed: %s\n", SDL_GetError());
        return;
    }

    renderer_init();
    int init_w = renderer_get_width();
    int init_h = renderer_get_height();

#ifdef AB3D_RELEASE
    /* Release: 720p window, then exclusive fullscreen at that resolution */
    init_w = AB3D_RELEASE_FS_W;
    init_h = AB3D_RELEASE_FS_H;
#endif

    g_window = SDL_CreateWindow(
        "Alien Breed 3D I",
        SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED,
        init_w, init_h,
        SDL_WINDOW_SHOWN | SDL_WINDOW_RESIZABLE
    );
    if (!g_window) {
        printf("[DISPLAY] SDL_CreateWindow failed: %s\n", SDL_GetError());
        return;
    }

#ifdef AB3D_RELEASE
    {
        SDL_DisplayMode want;
        SDL_zero(want);
        want.w = AB3D_RELEASE_FS_W;
        want.h = AB3D_RELEASE_FS_H;
        /* Pick nearest supported mode (e.g. exact 1280x720 or closest refresh). */
        SDL_DisplayMode closest;
        const SDL_DisplayMode *picked = SDL_GetClosestDisplayMode(0, &want, &closest);
        if (picked) {
            release_fs_w = picked->w;
            release_fs_h = picked->h;
            if (SDL_SetWindowDisplayMode(g_window, picked) != 0) {
                printf("[DISPLAY] SDL_SetWindowDisplayMode failed: %s\n", SDL_GetError());
            }
        }
    }
    if (SDL_SetWindowFullscreen(g_window, SDL_WINDOW_FULLSCREEN) != 0) {
        printf("[DISPLAY] SDL_SetWindowFullscreen failed: %s\n", SDL_GetError());
    }
    /* Let the window complete fullscreen transition before querying size */
    SDL_PumpEvents();
#endif

    g_sdl_ren = SDL_CreateRenderer(g_window, -1,
        SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
    if (!g_sdl_ren) {
        printf("[DISPLAY] SDL_CreateRenderer failed: %s\n", SDL_GetError());
        return;
    }

    g_hdr_fix_override = display_parse_hdr_override();
    g_hdr_sdr_fix_strength = display_parse_hdr_strength();
    g_hdr_lut_ready = 0;
    g_hdr_last_probe_ms = SDL_GetTicks();
    display_refresh_hdr_state(1);

    /* Size the software renderer to match the drawable.
     * In Release exclusive fullscreen, SDL_GetRendererOutputSize right after
     * SDL_CreateRenderer often still reports the old windowed framebuffer size
     * (e.g. 768x640); use the display mode we selected instead. */
#ifdef AB3D_RELEASE
    int out_w = release_fs_w;
    int out_h = release_fs_h;
    if (out_w < 96 || out_h < 80) {
        out_w = AB3D_RELEASE_FS_W;
        out_h = AB3D_RELEASE_FS_H;
    }
#else
    int out_w = init_w, out_h = init_h;
    if (SDL_GetRendererOutputSize(g_sdl_ren, &out_w, &out_h) != 0) {
        out_w = init_w;
        out_h = init_h;
    }
#endif
    if (out_w < 96) out_w = 96;
    if (out_h < 80) out_h = 80;
    display_on_resize(out_w, out_h);

    printf("[DISPLAY] SDL2 ready: %dx%d (resizable)\n", out_w, out_h);
}

void display_on_resize(int w, int h)
{
    if (w < 1 || h < 1) return;
    printf("[DISPLAY] resize: %dx%d\n", w, h);
    renderer_resize(w, h);
    renderer_set_present_size(w, h);
    if (g_texture) SDL_DestroyTexture(g_texture);
    g_texture = SDL_CreateTexture(g_sdl_ren,
        SDL_PIXELFORMAT_ARGB8888, SDL_TEXTUREACCESS_STREAMING,
        renderer_get_width(), renderer_get_height());
    if (g_texture) SDL_SetTextureScaleMode(g_texture, SDL_ScaleModeNearest);
}

void display_handle_resize(void)
{
    if (!g_sdl_ren) return;
    int out_w = 0, out_h = 0;
#ifdef AB3D_RELEASE
    /* Same as display_init: output size query can be wrong in exclusive fullscreen. */
    if (g_window && (SDL_GetWindowFlags(g_window) & SDL_WINDOW_FULLSCREEN) != 0) {
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
    display_refresh_hdr_state(0);
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
    display_maybe_refresh_hdr_state();

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
    if (!g_hdr_sdr_fix_enabled) {
        if (pitch == (int)(w * sizeof(uint32_t))) {
            memcpy(pixels, src, row_bytes * (size_t)h);
        } else {
            for (int y = 0; y < h; y++) {
                uint32_t *dst_row = (uint32_t*)((uint8_t*)pixels + (size_t)y * pitch);
                memcpy(dst_row, src + (size_t)y * w, row_bytes);
            }
        }
    } else {
        for (int y = 0; y < h; y++) {
            const uint32_t *src_row = src + (size_t)y * w;
            uint32_t *dst_row = (uint32_t*)((uint8_t*)pixels + (size_t)y * pitch);
            for (int x = 0; x < w; x++) {
                dst_row[x] = display_apply_hdr_sdr_fix(src_row[x]);
            }
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
