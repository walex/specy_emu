#ifndef _TAPE_AUDIO_H_
#define _TAPE_AUDIO_H_

#include "tap_loader.h"
#include <stdint.h>

void tape_audio_reset();
void tape_add_pulse(uint64_t& t, uint32_t duration, uint8_t& level);
uint8_t tape_audio_next_pulse(uint64_t cycles);
void tape_audio_set_bytes(uint8_t* data, size_t size);
bool tape_audio_is_active();
void tape_audio_sync();
void tape_audio_load_wav(const char* filename);
void tape_audio_load_tap(const char* filename);
void tape_audio_from_file(const char* filename);
#endif