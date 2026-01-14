#ifndef _KEYBOARD_HPP_
#define _KEYBOARD_HPP_

#include <stdint.h>
#include <map>

void keyboard_set_input(uint32_t key, uint16_t mod);
void keyboard_unset_input(uint32_t key, uint16_t mod);
uint8_t keyboard_get_map_addr(uint8_t addr);
#endif