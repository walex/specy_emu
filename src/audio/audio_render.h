#ifndef _AUDIO_RENDER_H_
#define _AUDIO_RENDER_H_

#include <stdint.h>

void audio_render_init();
void audio_render_play(uint8_t* buffer, size_t buffer_size);
void audio_render_end();	

#endif