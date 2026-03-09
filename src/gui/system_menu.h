#ifndef __SYSTEM_MENU_H_
#define __SYSTEM_MENU_H_

#include "platform.h"

using SystemMenuCallback = void(*)(void*);
const uint32_t SYSTEM_MENU_COMMAND_OPEN_FILE = 1;
const uint32_t SYSTEM_MENU_COMMAND_SAVE_FILE = 2;

bool system_menu_evaluate_keyboard_state(const bool* keys);
void system_menu_set_callback(uint32_t cb_id, SystemMenuCallback cb);
void system_menu_switch_cpu_mode();

#endif