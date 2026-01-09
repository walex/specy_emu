#ifndef _DISPLAY_HPP_
#define _DISPLAY_HPP_

#include <stdint.h>

void display_init(uint8_t* system_memory);
void display_end();
void display_set_border_color(uint8_t border_color);

constexpr int FLASH_FASE_FRAMES = 32;
constexpr double DISPLAY_REFRESH_RATE_HZ = 50.0;
constexpr double DISPLAY_REFRESH_RATE_SECS = 0.02;
#endif