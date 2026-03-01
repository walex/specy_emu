#ifndef _KEYBOARD_HPP_
#define _KEYBOARD_HPP_

#include <stdint.h>
#include <map>

uint8_t keyboard_get_map_addr(uint8_t addr);
const bool* keyboard_tick(uint64_t delta_cycles);
#endif