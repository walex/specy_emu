#ifndef _DISPLAY_HPP_
#define _DISPLAY_HPP_

#include <stdint.h>

void display_init(uint8_t* system_memory);
void display_end();
void display_set_border_color(uint8_t border_color);

const int FLASH_FASE_FRAMES = 32;

#endif