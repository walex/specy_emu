#ifndef __AUDIO_H__
#define __AUDIO_H__

#include "platform.hpp"

void audio_init();
void audio_end();
void audio_tick(uint64_t delta_tstates);
void audio_set_level(uint8_t value);
void audio_enable(bool enable);

#endif