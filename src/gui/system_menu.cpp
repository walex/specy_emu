#include "system_menu.h"
#include "keyboard.h"
#include "video_render.h"
#include "clk_master.h"
#include "audio.h"
#include "tape_audio.h"
#include "sna_loader.h"

#define INVOKE_MENU_CALLBACK(id, params) { \
	if (menu_callbacks.count(id)) { \
		menu_callbacks[id]((void*)params); \
	} \
}

static std::map<uint32_t, SystemMenuCallback> menu_callbacks;
static std::atomic<uint32_t> command_pending = 0;

void system_menu_set_callback(uint32_t cb_id, SystemMenuCallback cb) {
	
	menu_callbacks[cb_id] = cb;
}

void system_menu_switch_cpu_mode() {
	
	static bool cpu_speed_mode = false;	
	cpu_speed_mode = !cpu_speed_mode;
	audio_enable(!cpu_speed_mode);
	clk_master_switch_mode(cpu_speed_mode);
	video_render_show_message("Specy", cpu_speed_mode ? "CPU speed mode switched to fast" : "CPU speed mode switched to normal");
}

void system_menu_open_file_dialog() {
	
	video_render_open_file_dialog([](const char* const* filelist) {
		if (*filelist) {
			SDL_Log("Full path to selected file: '%s'", *filelist);
			INVOKE_MENU_CALLBACK(kSysMenuOpenFileCallback, *filelist);
		}
		});
}

void system_menu_save_file_dialog() {

	video_render_save_file_dialog([](const char* const* filelist) {
		if (*filelist) {
			SDL_Log("Full path to selected file: '%s'", *filelist);
			INVOKE_MENU_CALLBACK(kSysMenuSaveFileCallback , *filelist);
		}
		});
}

void system_menu_update() {

	switch (command_pending.load()) {
	case HOST_KEY_CMD_1:
		system_menu_open_file_dialog();
		break;
	case HOST_KEY_CMD_2:
		system_menu_save_file_dialog();
		break;
	case HOST_KEY_CMD_3:
		system_menu_switch_cpu_mode();
		break;
	}
	command_pending.store(0);
}

bool system_menu_evaluate_keyboard_state(const bool* keys) {

	if (command_pending.load() != 0)
		return false;

	if (keys[HOST_KEY_CMD_1])
		command_pending.store(HOST_KEY_CMD_1);
	else if (keys[HOST_KEY_CMD_2])
		command_pending.store(HOST_KEY_CMD_2);
	else if (keys[HOST_KEY_CMD_3])
		command_pending.store(HOST_KEY_CMD_3);
	else
		return false;
	
	return true;
}