#include "ula.h"
#include "tape_audio.h"
#include "z80.h"
#include "keyboard.h"
#include "display.h"
#include "audio.h"
#include <atomic>

static std::atomic<bool> audio_listen_enabled = false;

void ula_on_audio_listen() {

	if (audio_listen_enabled.load() == false) {

		audio_listen_enabled.store(true);		
	}
}

void ula_init(uint8_t* system_memory) {

	display_init(system_memory);
	audio_init();
}

void ula_read_port(uint16_t addr, uint8_t* value) {

	uint16_t port = addr & 0x00FF;
	auto clk = cpu_get_cycles();

	if (port == 0xFE) {

		// ---- KEYBOARD ----
		uint8_t key = (addr >> 8) & 0xFF;
		uint8_t kbd = keyboard_get_map_addr(key);

		// Bit 6 = EAR
		*value = (kbd & 0xBF);

		// ---- TAPE AUDIO ----
		if (audio_listen_enabled.load() == true)
			*value |= (tape_audio_next_pulse(cpu_get_cycles()) ? 0x40 : 0x00);
			
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