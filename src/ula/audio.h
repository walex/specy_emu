#ifndef _AUDIO_HPP_
#define _AUDIO_HPP_

#include <stdint.h>

void audio_init();
void audio_end();
void audio_play(uint8_t value);

#endif