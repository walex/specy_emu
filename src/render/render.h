#ifndef _RENDER_H_
#define _RENDER_H_
#include <stdint.h>

void render_init(uint32_t* display_buffer, size_t buffer_size_x, 
	size_t buffer_size_y, size_t window_size_x, size_t window_size_y);
void render_end();
void render_draw();
#endif