#include "ula.h"
#include "tape_audio.h"
#include "z80.h"
#include "keyboard.h"
#include "display.h"
#include "audio.h"

static uint8_t* tape_data = nullptr;
static size_t tape_data_size = 0;

void ula_init(uint8_t* system_memory) {

	display_init(system_memory);
	audio_init();
}

#include <chrono>
auto start_time = std::chrono::high_resolution_clock::now();
void ula_read_port(uint16_t addr, uint8_t* value) {

	uint16_t port = addr & 0x00FF;

	if (port == 0xFE) {

		// ---- TECLADO ----
		uint8_t key = (addr >> 8) & 0xFF;
		uint8_t kbd = keyboard_get_map_addr(key);

		auto end_time = std::chrono::high_resolution_clock::now();
		if (end_time - start_time > std::chrono::seconds(5)) {
			start_time = end_time;
			if (tape_data != nullptr && tape_data_size > 0) {
				tape_audio_set_bytes(cpu_get_cycles(), tape_data, tape_data_size);
				tape_data = nullptr;
				tape_data_size = 0;
			}
		}
		
		// Bit 6 = EAR
		*value = (kbd & 0xBF) | (tape_audio_next_pulse(cpu_get_cycles()) ? 0x40 : 0x00);
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

void ula_set_tape_bytes(uint8_t* data, size_t size) {

	tape_data = data;
	tape_data_size = size;
}
