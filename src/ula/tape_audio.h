#ifndef _TAPE_AUDIO_H_
#define _TAPE_AUDIO_H_

#include <stdint.h>

const uint8_t TAP_HEADER_TYPE = 0;
const uint8_t TAP_DATA_BLOCK = 0xFF;
const uint32_t TAP_HEADER_BLOCK_SIZE = 19;

void tape_audio_reset();
void tape_add_pulse(uint64_t& t, uint32_t duration, uint8_t& level);
uint8_t tape_audio_next_pulse(uint64_t cycles);
void tape_audio_set_bytes(uint8_t* data, size_t size);
void tape_audio_sync(uint64_t cycles);
void tape_audio_load_wav(const char* filename);
void tape_audio_load_tap(const char* filename);
void tape_audio_from_file(const char* filename);
#endif