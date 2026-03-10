#ifndef _TAPE_AUDIO_H_
#define _TAPE_AUDIO_H_

#include "platform.h"

void tape_audio_reset();
uint8_t tape_audio_next_pulse(uint64_t cycles);
void tape_audio_set_bytes(uint8_t* data, size_t size);
bool tape_audio_is_active();
bool tape_audio_eof();
bool tape_audio_sync();
void tape_audio_load_wav(const char* filename);
void tape_audio_load_tap(const char* filename);
void tape_audio_from_file(const char* filename);
void tape_audio_playback(bool enable);

#endif