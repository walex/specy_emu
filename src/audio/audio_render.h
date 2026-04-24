#ifndef __AUDIO_RENDER_H__
#define __AUDIO_RENDER_H__

#include "platform.hpp"

typedef void(*audio_render_callback)(uint8_t* buffer, int len);

void audio_render_init(uint32_t sample_rate, audio_render_callback cb);
void audio_render_play(uint8_t* buffer, size_t buffer_size);
void audio_render_end();	
void audio_render_load_wav(const char* filename, uint8_t** out_buffer, size_t& out_size, int& freq);
void audio_render_free_wav(uint8_t* buffer);


#endif