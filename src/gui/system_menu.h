#ifndef __SYSTEM_MENU_H_
#define __SYSTEM_MENU_H_

#include "platform.h"

using SystemMenuCallback = void(*)(void*);
const uint32_t kSysMenuOpenFileCallback = 1;
const uint32_t kSysMenuSaveFileCallback = 2;
const uint32_t kSysMenuSystenResetCallback = 3;

bool system_menu_evaluate_keyboard_state(const bool* keys);
void system_menu_set_callback(uint32_t cb_id, SystemMenuCallback cb);
void system_menu_switch_cpu_mode();
void system_menu_update();

#endif