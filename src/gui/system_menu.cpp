#include "system_menu.h"
#include "keyboard.h"
#include "video_render.h"
#include "clk_master.h"
#include "audio.h"
#include "tape_audio.h"
#include "sna_loader.h"
#include <SDL3/SDL_dialog.h>

std::map<uint32_t, SystemMenuCallback> menu_callbacks;

static std::counting_semaphore<1> dialog_semaphore(0);

void system_menu_set_callback(uint32_t cb_id, SystemMenuCallback cb) {
	
	menu_callbacks[cb_id] = cb;
}

void system_menu_switch_cpu_mode() {
	
	static bool cpu_speed_mode = false;	
	cpu_speed_mode = !cpu_speed_mode;
	audio_enable(!cpu_speed_mode);
	clk_master_switch_mode(cpu_speed_mode);
	video_render_show_message("specy emu",
		cpu_speed_mode ? "Cpu speed mode is on" : "Cpu speed mode is off");
	video_render_set_focus();
}

void system_menu_open_file_dialog(uint32_t cmd_id) {
	
	SDL_ShowOpenFileDialog([](void* userdata, const char* const* filelist, int /*filter*/) {

		uint32_t cb_cmd_id = (uint32_t)((uint64_t)userdata);
		if (*filelist) {
			SDL_Log("Full path to selected file: '%s'", *filelist);
			if (menu_callbacks.count(cb_cmd_id)) {
				menu_callbacks[cb_cmd_id]((void*)*filelist);
			}		
		}
		video_render_set_focus();
		dialog_semaphore.release();
	}, (void*)(uint64_t)cmd_id, nullptr, nullptr, 0, nullptr, false);
	dialog_semaphore.acquire();
}

void system_menu_save_file_dialog(uint32_t cmd_id) {

	SDL_ShowSaveFileDialog([](void* userdata, const char* const* filelist, int /*filter*/) {

		uint32_t cb_cmd_id = (uint32_t)((uint64_t)userdata);
		if (*filelist) {
			SDL_Log("Full path to selected file: '%s'", *filelist);
			if (menu_callbacks.count(cb_cmd_id)) {
				menu_callbacks[cb_cmd_id]((void*)*filelist);
			}
		}
		video_render_set_focus();
		dialog_semaphore.release();
	}, (void*)(uint64_t)cmd_id, nullptr, nullptr, 0, nullptr);
	dialog_semaphore.acquire();
}

void system_menu_play_stop() {

	static bool playin_tape = false;
	playin_tape = !playin_tape;
	tape_audio_playback(playin_tape);
	bool playing = tape_audio_is_active();
	video_render_show_message("specy emu",
		playing ? "Tape playing" : "Tape stopped");
	video_render_set_focus();
	
}

bool system_menu_evaluate_keyboard_state(const bool* keys) {

	int key_index = -1;

	if (keys[HOST_KEY_CMD_1])
		key_index = HOST_KEY_CMD_1;
	else if (keys[HOST_KEY_CMD_2])
		key_index = HOST_KEY_CMD_2;
	else if (keys[HOST_KEY_CMD_3])
		key_index = HOST_KEY_CMD_3; 
	else if (keys[HOST_KEY_CMD_4])
		key_index = HOST_KEY_CMD_4;

	switch (key_index) {
		case HOST_KEY_CMD_1:
			system_menu_open_file_dialog(SYSTEM_MENU_COMMAND_OPEN_FILE);
			break;
		case HOST_KEY_CMD_2:
			system_menu_switch_cpu_mode();
			break;
		case HOST_KEY_CMD_3:
			system_menu_save_file_dialog(SYSTEM_MENU_COMMAND_SAVE_FILE);
			break;
		case HOST_KEY_CMD_4:
			system_menu_play_stop();
			break;
		}
	return key_index != -1;
}