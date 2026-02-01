#include "ula.h"
#include "tape_audio.h"
#include "z80.h"
#include "specy_rom.h"
#include "keyboard.h"
#include "display.h"
#include "audio.h"
#include <atomic>
#include <thread>

static clock_master_handle master_clock;
static std::atomic<bool> audio_listen_enabled = false;
static uint64_t last_cycles = 0;

void ula_on_audio_listen() {

	if (audio_listen_enabled.load() == false) {

		tape_audio_sync(cpu_get_cycles());
		audio_listen_enabled.store(true);		
	}
}

void ula_on_cpu_cycles(uint64_t total_cycles) {
	uint64_t delta = total_cycles - last_cycles;
	audio_tick(delta);
	display_tick(delta);
	last_cycles = total_cycles;		
}

void ula_init(uint8_t* system_memory) {

	// TODO: for real emulation clock must be created outside ula
	master_clock = clk_master_create("cpu_sync_clock", Z80_CPU_FREQ_HZ);
	clk_master_subscribe_sync_callback(master_clock, ula_on_cpu_cycles);
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
			audio_set_level(next_pulse >> 2);
			*value |= next_pulse;
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
	audio_set_level(value & 0x18);

}

void ula_assert_INT_line() {

	interrupts_request_mi();
}