#include "ula.h"
#include "tape_audio.h"
#include "z80.h"
#include "system_memory.h"
#include "keyboard.h"
#include "display.h"
#include "audio.h"
#include "automata.h"
#include "tempo.h"
#include <atomic>
#include <thread>
#include <chrono>
#include <algorithm>

static clock_master_handle master_clock;
static std::atomic<bool> audio_playing = false;
static std::atomic<bool> edge_sync = false;

void force_tape_state(uint64_t total_cycles) {

	if (audio_playing.load() == false) {
		if (edge_sync.load() == true) {
			if (automata_play_tape()) {
				audio_playing.store(true);
				printf("PLAY\n");
			}
		}
	}
	else {
		if (automata_play_tape_idle(total_cycles)) {
			audio_playing.store(false);
			edge_sync.store(false);
			printf("STOP IDLE\n");
		}
	}
}

void ula_on_load_edge_1() {

	if (audio_playing.load() == false) {
		tape_audio_sync();
		audio_playing.store(true);
		//edge_sync.store(true);
	}
}

void ula_on_cpu_cycles(uint64_t total_cycles) {

	static uint64_t last_cycles = 0;
	static uint64_t int_cycles = 0;

	uint64_t delta_cycles = total_cycles - last_cycles;
	audio_tick(delta_cycles);
	display_tick(delta_cycles);
	//force_tape_state(total_cycles);

	int_cycles += delta_cycles;
	if (int_cycles >= kULASyncCycles)
	{
		MEASURE_ELAPSED_TIME("int assert time:", 200,
			int_cycles -= kULASyncCycles;
			keyboard_tick(delta_cycles);
			
		);
	}

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

	static uint64_t last_clock = 0;
	const uint16_t port = addr & 0x00FF;

	if (port == 0xFE) {

		MEASURE_ELAPSED_TIME("keyboard scan time:", 200, ;)
		// timing
		auto clock_cycle = cpu_get_cycles();
		uint64_t delta_tstates = clock_cycle - last_clock;
		last_clock = clock_cycle;

		// keyboard 
		uint8_t key = (addr >> 8) & 0xFF;
		uint8_t kbd = keyboard_get_map_addr(key);

		// exclude bit 6 ear
		*value = (kbd & 0xBF);

		// measure port 0xFE request rate
		//automata_measure_port_accel(delta_tstates, clock_cycle);

		// get audio pulses
		if (audio_playing.load() == true) {
			uint8_t next_pulse = (tape_audio_next_pulse(delta_tstates) ? 0x40 : 0x00);
			audio_set_level(clock_cycle, next_pulse >> 2);
			*value |= next_pulse;
		}


		return;
	}

	*value = 0xFF;
}

void ula_write_port_FE(uint16_t addr, uint8_t value) {

	// border = value & 0x7;
	// mic = value & 0x8;
	// ear = value & 0x10;

	display_set_border_color(value & 0x7);
	audio_set_level(cpu_get_cycles(), value & 0x18);

}

void ula_assert_INT_line() {

	interrupts_request_mi_c(0xFF);
}