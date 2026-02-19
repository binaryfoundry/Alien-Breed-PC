/*
 * Alien Breed 3D I - PC Port
 * stub_audio.h - Stubbed audio subsystem
 *
 * Replaces Amiga-specific audio:
 *   - Paula audio channels ($dff0a0-$dff0d8)
 *   - ProTracker music player (ProPlayer.s / MtPlayer.s)
 *   - Sound effects (SoundPlayer.s)
 *   - Module loading/playback (_InitPlayer, _PlayModule, etc.)
 */

#ifndef STUB_AUDIO_H
#define STUB_AUDIO_H

/* Lifecycle */
void audio_init(void);
void audio_shutdown(void);

/* Music (ProTracker module) */
void audio_init_player(void);
void audio_stop_player(void);
void audio_rem_player(void);
void audio_load_module(const char *filename);
void audio_init_module(void);
void audio_play_module(void);
void audio_unload_module(void);

/* Sound effects */
void audio_play_sfx(int sfx_id, int volume, int channel);
void audio_play_sample(int sample_id, int volume); /* MakeSomeNoise simplified */
void audio_stop_all(void);

/* In-game music (mt_init / mt_end from SoundPlayer.s) */
void audio_mt_init(void);
void audio_mt_end(void);

#endif /* STUB_AUDIO_H */
