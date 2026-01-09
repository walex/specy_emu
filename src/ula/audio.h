#ifndef _AUDIO_HPP_
#define _AUDIO_HPP_

#include <stdint.h>

void audio_init();
void audio_end();
void audio_play(uint64_t tstates_cpu_total, uint8_t value);

#endif