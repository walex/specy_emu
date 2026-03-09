#ifndef _KEYBOARD_HPP_
#define _KEYBOARD_HPP_

#include "platform.h"

// #ifdef USE_SDL3
#include "sdl_keyboard.h"
// #endif

using UlaKeyboardKeysCallback = bool(*)(const bool* keys);

void keyboard_init(UlaKeyboardKeysCallback cb);
void keyboard_end();
uint8_t keyboard_get_map_addr(uint8_t addr);
void keyboard_tick(uint64_t delta_cycles);



#endif