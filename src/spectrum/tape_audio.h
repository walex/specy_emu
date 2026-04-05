#ifndef _TAPE_AUDIO_H_
#define _TAPE_AUDIO_H_

#include "platform.h"
void tape_audio_block_sync();

uint8_t tape_audio_next_pulse(uint64_t cycles);
bool tape_audio_is_active();
void tape_audio_load_wav(const char* filename);
void tape_audio_load_tap(const char* filename);
void tape_audio_from_file(const char* filename);
void tape_audio_set_fast_mode(bool value);
bool tape_audio_get_fast_mode();
void tape_audio_next_pulses_block();
uint8_t tape_audio_pulse_step(uint64_t delta_cycles);
#endif