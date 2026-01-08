#ifndef _RENDER_H_
#define _RENDER_H_
#include <stdint.h>

void video_render_init(uint32_t* display_buffer, size_t buffer_size_x, 
	size_t buffer_size_y, size_t window_size_x, size_t window_size_y);
void video_render_end();
void video_render_draw();
#endif