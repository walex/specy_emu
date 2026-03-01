#ifndef __SYSTEM_MENU_H_
#define __SYSTEM_MENU_H_

#include <stdint.h>

using SystemMenuCallback = void(*)(void*);
const uint32_t SYSTEM_MENU_OPEN_FILE_DIALOG = 1;

void system_menu_evaluate_keyboard_state(const bool* keys);
void system_menu_set_callback(uint32_t cb_id, SystemMenuCallback cb);

#endif