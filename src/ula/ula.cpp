#include "ula.h"
#include "tape_audio.h"
#include "z80.h"
#include "keyboard.h"
#include "display.h"
#include "audio.h"
#include <atomic>

static uint8_t* tape_data = nullptr;
static size_t tape_data_size = 0;

// intercept calls functions
static constexpr uint16_t LD_BYTES = 0x0556;
static std::atomic<bool> tape_enabled = false;

void ula_on_LD_BYTES() {

	if (tape_enabled.load() == false && 
		tape_data != nullptr 
		&& tape_data_size > 0) {

		tape_audio_set_bytes(cpu_get_cycles(), tape_data, tape_data_size);
		tape_data = nullptr;
		tape_data_size = 0;
		tape_enabled.store(true);		
	}
}

void ula_init(uint8_t* system_memory) {

	cpu_add_call_interceptor(LD_BYTES, ula_on_LD_BYTES);

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
		if (tape_enabled.load() == true)
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

void ula_set_tape_bytes(uint8_t* data, size_t size) {

	tape_data = data;
	tape_data_size = size;
}
