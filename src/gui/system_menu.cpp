#include "system_menu.h"
#include "sdl_keyboard.h"
#include "video_render.h"
#include "clk_master.h"
#include "audio.h"
#include <SDL3/SDL_dialog.h>
#include <mutex>
#include <map>
#include <chrono>

std::map<uint32_t, SystemMenuCallback> menu_callbacks;
static std::mutex system_menu_lock;

#ifdef WINDOWS_PLATFORM
#include <Windows.h>
#include <thread>

#define SET_FOCUS(title) { \
std::thread([&]() { \
HWND hwnd = FindWindowA(nullptr, title); \
if (hwnd) \
	BringWindowToTop(hwnd); \
}).detach(); \
}

#define SHOW_MESSAGE_BOX(title, text) { \
	std::thread t([&]() { \
		MessageBoxA(nullptr, text, title, MB_OK); \
		}); \
	while (true) { \
		HWND hwnd = FindWindowA(nullptr, title); \
		if (hwnd) { \
			SetWindowPos(hwnd, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE | SWP_NOSIZE); \
			break; \
		} \
	} \
	t.join(); \
} 



#endif

void system_menu_set_callback(uint32_t cb_id, SystemMenuCallback cb) {
	
	menu_callbacks[cb_id] = cb;
}

void system_menu_switch_cpu_mode() {
	
	static bool cpu_speed_mode = false;	
	cpu_speed_mode = !cpu_speed_mode;
	audio_enable(!cpu_speed_mode);
	clk_master_switch_mode(cpu_speed_mode);
	SHOW_MESSAGE_BOX("specy emu",
		cpu_speed_mode ? "Cpu speed mode is on" : "Cpu speed mode is off");
	SET_FOCUS("spectrum render");	
}

void system_menu_open_file_dialog() {

	SDL_ShowOpenFileDialog([](void* /*userdata*/, const char* const* filelist, int /*filter*/) {

		if (*filelist) {
			SDL_Log("Full path to selected file: '%s'", *filelist);
			if (menu_callbacks.count(SYSTEM_MENU_OPEN_FILE_DIALOG)) {
				menu_callbacks[SYSTEM_MENU_OPEN_FILE_DIALOG]((void*)*filelist);
			}		
		}
		SET_FOCUS("spectrum render");
	}, nullptr, nullptr, nullptr, 0, nullptr, false);		
}

void system_menu_evaluate_keyboard_state(const bool* keys) {

	static auto last_check = std::chrono::steady_clock::now();
	int key_index = -1;
	if (keys[HOST_KEY_F1])
		key_index = HOST_KEY_F1;
	else if (keys[HOST_KEY_F2])
		key_index = HOST_KEY_F2;
	else
		return;

	{
		std::lock_guard<std::mutex> mtx(system_menu_lock);
		if (std::chrono::duration_cast<std::chrono::milliseconds>(std::chrono::steady_clock::now() - last_check).count() < 1000)
			return;
		switch (key_index) {
		case HOST_KEY_F1:
			system_menu_open_file_dialog();
			break;
		case HOST_KEY_F2:
			system_menu_switch_cpu_mode();
			break;
		}
		last_check = std::chrono::steady_clock::now();
	}
}