#ifndef _KEYBOARD_HPP_
#define _KEYBOARD_HPP_

#include <stdint.h>
#include <map>

void keyboard_set_input(uint32_t key);
void keyboard_unset_input(uint32_t key);
unsigned char keyboard_get_map_addr(unsigned char addr);
#endif