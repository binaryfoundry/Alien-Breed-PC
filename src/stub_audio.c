/*
 * Alien Breed 3D I - PC Port
 * stub_audio.c - SDL2 sound effects (load from data/sounds, play via SDL)
 *
 * Sample names and order from Amiga LoadFromDisk.s SFX_NAMES.
 * Loads sounds/<name>.wav (e.g. scream.wav, shotgun.wav). IDs 28+ fall back to <id>.wav.
 */

#include "stub_audio.h"
#include "stub_io.h"
#include <SDL.h>
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define MAX_SAMPLES      64
#define MAX_CHANNELS     8
#define NUM_NAMED_SFX    28
#define DEFAULT_FREQ     44100
#define DEFAULT_FORMAT  AUDIO_S16SYS
#define DEFAULT_CHANNELS 1
#define PLAYBACK_SPEED_DIV 1  /* 1 = normal speed; 2 = half speed (each source byte output twice) */

/* Amiga LoadFromDisk.s SFX_NAMES: raw sample byte sizes (no header, 8-bit unsigned, 8363 Hz) */
static const unsigned int amiga_sfx_sizes[NUM_NAMED_SFX] = {
    4400, 7200, 5400, 4600, 3400, 8400, 8000, 4000, 8600, 6200,
    1200, 4000, 2200, 3000, 5600, 11600, 7200, 7400, 9200, 5000,
    4000, 8800, 9000, 1800, 3400, 1600, 11000, 8400
};
#define AMIGA_SFX_RATE 8363  /* PAL Amiga typical SFX rate (3579545/428) */

/* Amiga LoadFromDisk.s SFX_NAMES order: sample_id -> disk/sounds/<name> (we use sounds/<name>.wav or raw) */
static const char *const sfx_names[NUM_NAMED_SFX] = {
    "scream",      /* 0 */
    "fire!",       /* 1 ShootName */
    "munch",       /* 2 */
    "shoot.dm",    /* 3 PooGunName */
    "collect",     /* 4 */
    "newdoor",     /* 5 */
    "splash",      /* 6 BassName */
    "footstep3",   /* 7 StompName */
    "lowscream",   /* 8 */
    "baddiegun",   /* 9 */
    "switch",      /* 10 */
    "switch1.sfx", /* 11 ReloadName */
    "noammo",      /* 12 */
    "splotch",     /* 13 */
    "splatpop",    /* 14 */
    "boom",        /* 15 */
    "newhiss",     /* 16 */
    "howl1",       /* 17 */
    "howl2",       /* 18 */
    "pant",        /* 19 */
    "whoosh",      /* 20 */
    "shotgun",     /* 21 ShotGunName */
    "flame",       /* 22 */
    "muffledfoot", /* 23 (Amiga: MuffledFoot) */
    "footclop",    /* 24 */
    "footclank",   /* 25 */
    "teleport",    /* 26 */
    "halfwormpain" /* 27 (Amiga: HALFWORMPAIN) */
};

/* One preloaded sample (converted to device format) */
typedef struct {
    Uint8  *data;
    Uint32  length;   /* bytes */
    int     loaded;
} LoadedSample;

/* One mixing channel (playing a sample) */
typedef struct {
    const Uint8 *sample_data;
    Uint32       sample_len;
    Uint32       position;   /* bytes played */
    int          volume;     /* 0-255 -> SDL_MixAudio uses 0-128 */
} Channel;

static SDL_AudioDeviceID g_device = 0;
static SDL_AudioSpec     g_spec;
static LoadedSample      g_samples[MAX_SAMPLES];
static Channel           g_channels[MAX_CHANNELS];
static int               g_next_channel = 0;
static int               g_audio_ready = 0;

static void audio_callback(void *userdata, Uint8 *stream, int len)
{
    (void)userdata;
    memset(stream, 0, (size_t)len);

    for (int c = 0; c < MAX_CHANNELS; c++) {
        Channel *ch = &g_channels[c];
        if (ch->sample_data == NULL || ch->position >= ch->sample_len)
            continue;

        /* Normal speed (PLAYBACK_SPEED_DIV 1): consume len bytes per callback */
        Uint32 remain = ch->sample_len - ch->position;
        Uint32 to_mix = (Uint32)len / PLAYBACK_SPEED_DIV;
        if (to_mix > remain)
            to_mix = remain;

        int mix_vol = ch->volume;
        if (mix_vol > 255) mix_vol = 255;
        mix_vol = (mix_vol * 128) / 255;

        SDL_MixAudioFormat(stream, ch->sample_data + ch->position,
                           g_spec.format, to_mix, mix_vol);
        if (PLAYBACK_SPEED_DIV > 1 && to_mix * 2 <= (Uint32)len)
            SDL_MixAudioFormat(stream + to_mix, ch->sample_data + ch->position,
                              g_spec.format, to_mix, mix_vol);
        ch->position += to_mix;

        if (ch->position >= ch->sample_len) {
            ch->sample_data = NULL;
        }
    }
}

/* Lowercase the filename part of path in place (from last '/' or '\\' to end). */
static void path_filename_to_lower(char *path)
{
    char *p = strrchr(path, '/');
    char *b = strrchr(path, '\\');
    if (b && (!p || b > p)) p = b;
    if (p) p++; else p = path;
    for (; *p; p++) *p = (char)tolower((unsigned char)*p);
}

/* Try to load Amiga raw SFX (no header, 8-bit unsigned, 8363 Hz). Returns 1 with buf/len/spec set, 0 on failure. */
static int load_amiga_raw(int id, char *path_out, size_t path_size,
                          SDL_AudioSpec *spec_out, Uint8 **buf_out, Uint32 *len_out)
{
    if (id >= NUM_NAMED_SFX) return 0;

    const char *name = sfx_names[id];
    unsigned int expect_len = amiga_sfx_sizes[id];
    char path[512];
    char path_lower[512];
    FILE *f = NULL;

    /* Try sounds/<name> then sounds/<name>.raw (case-insensitive) */
    io_make_data_path(path, sizeof(path), "sounds/");
    size_t base_len = strlen(path);
    snprintf(path + base_len, sizeof(path) - base_len, "%s", name);
    f = fopen(path, "rb");
    if (!f) {
        strncpy(path_lower, path, sizeof(path_lower) - 1);
        path_lower[sizeof(path_lower) - 1] = '\0';
        path_filename_to_lower(path_lower);
        f = fopen(path_lower, "rb");
        if (f) { (void)strncpy(path, path_lower, sizeof(path) - 1); path[sizeof(path) - 1] = '\0'; }
    }
    if (!f) {
        snprintf(path + base_len, sizeof(path) - base_len, "%s.raw", name);
        f = fopen(path, "rb");
        if (!f) {
            strncpy(path_lower, path, sizeof(path_lower) - 1);
            path_lower[sizeof(path_lower) - 1] = '\0';
            path_filename_to_lower(path_lower);
            f = fopen(path_lower, "rb");
            if (f) { (void)strncpy(path, path_lower, sizeof(path) - 1); path[sizeof(path) - 1] = '\0'; }
        }
    }
    if (!f) return 0;

    fseek(f, 0, SEEK_END);
    long file_len = ftell(f);
    fseek(f, 0, SEEK_SET);
    if (file_len <= 0) {
        fclose(f);
        return 0;
    }
    /* Read up to expected Amiga size (file may be exact, shorter, or slightly longer) */
    unsigned int to_read = (unsigned int)(file_len > (long)expect_len ? expect_len : file_len);
    Uint8 *raw = (Uint8 *)SDL_malloc(to_read);
    if (!raw) { fclose(f); return 0; }
    if (fread(raw, 1, to_read, f) != to_read) {
        SDL_free(raw);
        fclose(f);
        return 0;
    }
    fclose(f);

    /* Paula AUDxLEN is in 16-bit words (SoundPlayer.s: sub.l d1,d0; lsr.l #1,d0 -> words).
     * So the buffer is to_read bytes = (to_read/2) words; only the high byte of each word
     * is the sample (big-endian). Thus we have (to_read/2) samples. */
    Uint32 samples = to_read / 2;
    if (samples == 0) { SDL_free(raw); return 0; }
    Uint32 s16_len = samples * 2;
    Sint16 *s16 = (Sint16 *)SDL_malloc(s16_len);
    if (!s16) { SDL_free(raw); return 0; }
    /* Paula: 8-bit unsigned (0-255), 128 = silence. High byte of each word = sample. */
    for (Uint32 i = 0; i < samples; i++) {
        int u8 = (int)(raw[i * 2]);  /* high byte of word (even byte index) */
        int sample = (u8 - 128) * 256;
        if (sample > 32767) sample = 32767;
        if (sample < -32768) sample = -32768;
        s16[i] = (Sint16)sample;
    }
    SDL_free(raw);

    spec_out->freq = AMIGA_SFX_RATE;
    spec_out->format = AUDIO_S16SYS;
    spec_out->channels = 1;
    *buf_out = (Uint8 *)s16;
    *len_out = s16_len;
    if (path_out && path_size) {
        strncpy(path_out, path, path_size - 1);
        path_out[path_size - 1] = '\0';
    }
    return 1;
}

static int load_one_sample(int id)
{
    char path[512];
    SDL_AudioSpec want;
    Uint8 *buf = NULL;
    Uint32 len = 0;
    int from_amiga = 0;

    /* Try converted WAV first (sounds/<name>.wav), then Amiga raw originals if missing */
    char subpath[80];
    if (id < NUM_NAMED_SFX) {
        snprintf(subpath, sizeof(subpath), "sounds/%s.wav", sfx_names[id]);
    } else {
        snprintf(subpath, sizeof(subpath), "sounds/%d.wav", id);
    }
    io_make_data_path(path, sizeof(path), subpath);

    if (!SDL_LoadWAV(path, &want, &buf, &len)) {
        char path_lower[512];
        snprintf(path_lower, sizeof(path_lower), "%s", path);
        path_filename_to_lower(path_lower);
        if (!SDL_LoadWAV(path_lower, &want, &buf, &len)) {
            /* No WAV: for named SFX try Amiga raw (sounds/<name> or sounds/<name>.raw) */
            if (id < NUM_NAMED_SFX && load_amiga_raw(id, path, sizeof(path), &want, &buf, &len)) {
                from_amiga = 1;
            } else {
                return 0;  /* not found - skip silently for high IDs */
            }
        } else {
            strncpy(path, path_lower, sizeof(path) - 1);
            path[sizeof(path) - 1] = '\0';
        }
    }

    /* Convert to device format so we can mix in callback */
    SDL_AudioCVT cvt;
    if (SDL_BuildAudioCVT(&cvt, want.format, want.channels, want.freq,
                           g_spec.format, g_spec.channels, g_spec.freq) < 0) {
        printf("[AUDIO] sample %d: unsupported format (%s)\n", id, path);
        if (from_amiga) SDL_free(buf); else SDL_FreeWAV(buf);
        return 0;
    }

    cvt.len = (int)len;
    cvt.buf = (Uint8 *)SDL_malloc((size_t)len * cvt.len_mult);
    if (!cvt.buf) {
        printf("[AUDIO] sample %d: out of memory\n", id);
        if (from_amiga) SDL_free(buf); else SDL_FreeWAV(buf);
        return 0;
    }
    memcpy(cvt.buf, buf, (size_t)len);
    if (from_amiga) SDL_free(buf); else SDL_FreeWAV(buf);

    if (SDL_ConvertAudio(&cvt) < 0) {
        printf("[AUDIO] sample %d: convert failed\n", id);
        SDL_free(cvt.buf);
        return 0;
    }

    g_samples[id].data = cvt.buf;
    g_samples[id].length = (Uint32)(cvt.len_cvt);
    g_samples[id].loaded = 1;
    printf("[AUDIO] loaded %d (%s): %s%s (%u bytes)\n",
           id, id < NUM_NAMED_SFX ? sfx_names[id] : "?", path, from_amiga ? " [Amiga raw]" : "", (unsigned)g_samples[id].length);
    return 1;
}

static void free_samples(void)
{
    for (int i = 0; i < MAX_SAMPLES; i++) {
        if (g_samples[i].loaded && g_samples[i].data) {
            SDL_free(g_samples[i].data);
            g_samples[i].data = NULL;
            g_samples[i].length = 0;
            g_samples[i].loaded = 0;
        }
    }
}

void audio_init(void)
{
    printf("[AUDIO] init\n");
    memset(g_samples, 0, sizeof(g_samples));
    memset(g_channels, 0, sizeof(g_channels));
    g_next_channel = 0;
    g_audio_ready = 0;
    g_device = 0;

    if (SDL_InitSubSystem(SDL_INIT_AUDIO) < 0) {
        printf("[AUDIO] SDL_Init AUDIO failed: %s\n", SDL_GetError());
        return;
    }

    g_spec.freq = DEFAULT_FREQ;
    g_spec.format = DEFAULT_FORMAT;
    g_spec.channels = (Uint8)DEFAULT_CHANNELS;
    g_spec.samples = 512;
    g_spec.callback = audio_callback;
    g_spec.userdata = NULL;

    g_device = SDL_OpenAudioDevice(NULL, 0, &g_spec, &g_spec, 0);
    if (g_device == 0) {
        printf("[AUDIO] SDL_OpenAudioDevice failed: %s\n", SDL_GetError());
        SDL_QuitSubSystem(SDL_INIT_AUDIO);
        return;
    }

    /* Load samples by Amiga name (sounds/scream.wav, sounds/shotgun.wav, ...) */
    {
        char first_path[512];
        io_make_data_path(first_path, sizeof(first_path), "sounds/scream.wav");
        printf("[AUDIO] Loading sound effects from data/sounds (e.g. %s)\n", first_path);
    }
    int loaded_count = 0;
    for (int i = 0; i < MAX_SAMPLES; i++) {
        loaded_count += load_one_sample(i);
    }

    SDL_PauseAudioDevice(g_device, 0);
    g_audio_ready = 1;
    if (loaded_count > 0) {
        printf("[AUDIO] Loaded %d sound effect(s): ", loaded_count);
        for (int i = 0, n = 0; i < MAX_SAMPLES && n < loaded_count; i++) {
            if (g_samples[i].loaded) {
                printf("%s%s", n ? ", " : "", i < NUM_NAMED_SFX ? sfx_names[i] : "?");
                n++;
            }
        }
        printf("\n");
    } else {
        printf("[AUDIO] No WAV files found in data/sounds (scream.wav, shotgun.wav, ...)\n");
    }
}

void audio_shutdown(void)
{
    if (g_device) {
        SDL_CloseAudioDevice(g_device);
        g_device = 0;
    }
    free_samples();
    SDL_QuitSubSystem(SDL_INIT_AUDIO);
    g_audio_ready = 0;
    printf("[AUDIO] shutdown\n");
}

void audio_init_player(void)       { /* stub */ }
void audio_stop_player(void)       { /* stub */ }
void audio_rem_player(void)        { /* stub */ }
void audio_load_module(const char *filename) { (void)filename; }
void audio_init_module(void)       { /* stub */ }
void audio_play_module(void)       { /* stub */ }
void audio_unload_module(void)     { /* stub */ }

void audio_play_sfx(int sfx_id, int volume, int channel)
{
    (void)channel;
    audio_play_sample(sfx_id, volume);
}

void audio_play_sample(int sample_id, int volume)
{
    if (!g_audio_ready || g_device == 0)
        return;
    if (sample_id < 0 || sample_id >= MAX_SAMPLES)
        return;
    if (!g_samples[sample_id].loaded || g_samples[sample_id].data == NULL) {
        /* Log once per missing sample (no spam) - helps debug "no sound" */
        static unsigned char logged[MAX_SAMPLES];
        if (sample_id < MAX_SAMPLES && !logged[sample_id]) {
            logged[sample_id] = 1;
            if (sample_id < NUM_NAMED_SFX) {
                printf("[AUDIO] play_sample(%d (%s), %d) - not loaded (add %s.wav to data/sounds)\n",
                       sample_id, sfx_names[sample_id], volume, sfx_names[sample_id]);
            } else {
                printf("[AUDIO] play_sample(%d, %d) - not loaded (add %d.wav to data/sounds)\n",
                       sample_id, volume, sample_id);
            }
        }
        return;
    }

    SDL_LockAudioDevice(g_device);

    /* Pick a channel (round-robin so new sounds override oldest) */
    Channel *ch = &g_channels[g_next_channel];
    g_next_channel = (g_next_channel + 1) % MAX_CHANNELS;

    ch->sample_data = g_samples[sample_id].data;
    ch->sample_len  = g_samples[sample_id].length;
    ch->position    = 0;
    ch->volume      = volume;

    SDL_UnlockAudioDevice(g_device);
}

void audio_stop_all(void)
{
    if (!g_audio_ready || g_device == 0) return;
    SDL_LockAudioDevice(g_device);
    for (int c = 0; c < MAX_CHANNELS; c++) {
        g_channels[c].sample_data = NULL;
        g_channels[c].position = 0;
    }
    SDL_UnlockAudioDevice(g_device);
}

void audio_mt_init(void)           { /* stub */ }
void audio_mt_end(void)            { /* stub */ }
