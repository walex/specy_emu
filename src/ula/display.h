#ifndef __DISPLAY_HPP__
#define __DISPLAY_HPP__

#include "platform.hpp"

void display_init(uint8_t* system_memory);
void display_end();
bool display_is_running();
void display_set_border_color(uint32_t border_color);
uint32_t display_get_border_color();
void display_tick(uint64_t delta_cycles);

#endif