/*
 * Alien Breed 3D I - PC Port
 * stub_audio.c - Stubbed audio (all no-ops)
 */

#include "stub_audio.h"
#include <stdio.h>

void audio_init(void)
{
    printf("[AUDIO] init (stub)\n");
}

void audio_shutdown(void)
{
    printf("[AUDIO] shutdown (stub)\n");
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
    (void)sfx_id;
    (void)volume;
    (void)channel;
}

void audio_play_sample(int sample_id, int volume)
{
    (void)sample_id;
    (void)volume;
}

void audio_stop_all(void)          { /* stub */ }

void audio_mt_init(void)           { /* stub */ }
void audio_mt_end(void)            { /* stub */ }
