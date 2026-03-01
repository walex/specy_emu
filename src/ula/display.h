#ifndef _DISPLAY_HPP_
#define _DISPLAY_HPP_

#include <stdint.h>

void display_init(uint8_t* system_memory);
void display_end();
bool display_is_running();
void display_set_border_color(uint32_t border_color);
uint32_t display_get_border_color();
void display_tick(uint64_t delta_cycles);

#endif