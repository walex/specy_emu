#include "system_menu.h"
#include "sdl_keyboard.h"
#include <SDL3/SDL_dialog.h>
#include <atomic>
#include <map>

std::map<uint32_t, SystemMenuCallback> menu_callbacks;

void system_menu_set_callback(uint32_t cb_id, SystemMenuCallback cb) {
	
	menu_callbacks[cb_id] = cb;
}

void system_menu_evaluate_keyboard_state(const bool* keys) {

	static std::atomic<bool> show_open_menu{ false };
	if (keys[HOST_KEY_F1]) {
		
		if (show_open_menu.load()) {
			return;
		}
		show_open_menu.store(true);
		SDL_ShowOpenFileDialog([](void* /*userdata*/, const char* const* filelist, int /*filter*/ ) {

			if (*filelist) {
				SDL_Log("Full path to selected file: '%s'", *filelist);
				if (menu_callbacks.count(SYSTEM_MENU_OPEN_FILE_DIALOG)) {
					menu_callbacks[SYSTEM_MENU_OPEN_FILE_DIALOG]((void*)*filelist);
				}
			}
			show_open_menu.store(false);
			}, nullptr, nullptr, nullptr, 0, nullptr, false);		
	}
}