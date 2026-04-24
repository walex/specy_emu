#ifndef __VIDEO_RENDER_H__
#define __VIDEO_RENDER_H__

#include "platform.hpp"

using file_dialog_func_ptr = std::function<void(const char* const*)>;

void video_render_init(uint32_t* display_buffer, size_t buffer_size_x, 
	size_t buffer_size_y, size_t window_size_x, size_t window_size_y);
bool video_render_process();
void video_render_end();
uint64_t video_render_get_window_id();
void* video_render_get_window();
void video_render_show_message(const char* title, const char* message);
void video_render_open_file_dialog(file_dialog_func_ptr callback);
void video_render_save_file_dialog(file_dialog_func_ptr callback);

#endif