#include "ula.h"
#include "tape_audio.h"
#include "z80.h"
#include "specy_rom.h"
#include "keyboard.h"
#include "display.h"
#include "audio.h"
#include <atomic>

static std::atomic<bool> audio_listen_enabled = false;

void ula_on_audio_listen() {

	if (audio_listen_enabled.load() == false) {

		tape_audio_sync(cpu_get_cycles());
		audio_listen_enabled.store(true);		
	}
}

void ula_init(uint8_t* system_memory) {

	display_init(system_memory);
	audio_init();
}

void ula_read_port(uint16_t addr, uint8_t* value) {

	uint16_t port = addr & 0x00FF;
	auto clock_cycle = cpu_get_cycles();

	if (port == 0xFE) {

		// keyboard 
		uint8_t key = (addr >> 8) & 0xFF;
		uint8_t kbd = keyboard_get_map_addr(key);

		// bit 6 ear
		*value = (kbd & 0xBF);

		// tape audio
		if (audio_listen_enabled.load() == true) {
			uint8_t next_pulse = (tape_audio_next_pulse(clock_cycle) ? 0x40 : 0x00);
			audio_play(clock_cycle, (next_pulse >> 2));
			*value |= next_pulse;
		}

		// hack: disable audio listen if pc points outside rom
		if (specy_rom_pc_is_in_rom() == false) {

			audio_listen_enabled.store(false);
		}
		return;
	}

	*value = 0xFF;
}

void ula_write_port(uint16_t addr, uint8_t value) {

   // border = value & 0x7;
   // mic = value & 0x8;
   // ear = value & 0x10;

	display_set_border_color(value & 0x7);
	audio_play(cpu_get_cycles(), value & 0x18);
}

void ula_assert_INT_line() {

	trigger_MI(0);
}