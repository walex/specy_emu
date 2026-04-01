#include "ula.h"
#include "tape_audio.h"
#include "z80.h"
#include "system_memory.h"
#include "memory_paging.h"
#include "display.h"
#include "audio.h"
#include "tempo.h"
#include "clk_master.h"
#include "automata.h"

constexpr uint16_t kPagingControlPort = 0x7FFD;
constexpr uint16_t kPortFE = 0xFE;
static clock_master_handle master_clock;
static uint64_t last_cycles = 0;
static uint64_t last_clock = 0;

void ula_on_cpu_cycles(uint64_t total_cycles);

void ula_init(uint8_t* system_memory, Ula_Callbacks* cb) {

	last_cycles = 0;
	last_clock = 0;
	master_clock = clk_master_create("cpu_sync_clock", Z80_CPU_FREQ_HZ);
	clk_master_subscribe_sync_callback(master_clock, ula_on_cpu_cycles);
	display_init(system_memory);
	audio_init();
	keyboard_init(cb ? cb->ulaKeyboardKeysCallback : nullptr);
}

bool ula_is_running() {
	return display_is_running();
}

void ula_end() {

	keyboard_end();
	display_end();
	audio_end();
	clk_master_destroy("cpu_sync_clock");
}

void ula_on_tape_load_block_from_info() {
	
	uint16_t pc = cpu_get_register16(CPU_REGISTER_PC);
	uint16_t af = cpu_get_register16(CPU_REGISTER_AF); // a
	uint16_t ix = cpu_get_register16(CPU_REGISTER_IX); // copy addr
	uint16_t de = cpu_get_register16(CPU_REGISTER_DE); // copy size
	uint16_t hl = cpu_get_register16(CPU_REGISTER_HL); // a
	uint8_t a = (uint8_t)(af >> 8); // a == 0 header, a == 0xFF data

	uint8_t* data = nullptr;
	size_t size = 0;
	
	if (a == 0) {
		data = tape_audio_get_header_block_raw(size);
		
	}
	else if (a == 0xFF) {
		data = tape_audio_get_data_block_raw(size);
		tape_audio_next_data_block();		
	}
	if (!data) {
		printf("Error getting %s block", a ? "data" : "header");
		return;
	}
	if (size != de) {
		printf("Error incorrect block size in:%u tape:%u", de, (uint16_t)(size));
		return;
	}
	memcpy(system_memory_get_pointer(ix), data, size);

	af |= 1;
	cpu_set_register16(CPU_REGISTER_AF,af);
	cpu_force_next_opcode(RET_OPCODE);	
}

void ula_on_tape_load_block() {

	tape_audio_sync();
}

void ula_on_cpu_cycles(uint64_t total_cycles) {

	uint64_t delta_cycles = total_cycles - last_cycles;
	audio_tick(delta_cycles);
	display_tick(delta_cycles);
	keyboard_tick(delta_cycles);
	last_cycles = total_cycles;
}

void ula_read_tape(uint64_t clock_cycle, uint8_t* value) {

	static bool prev_audio_playing = false;

	uint64_t delta_tstates = clock_cycle - last_clock;
	last_clock = clock_cycle;

	// Track tape playing state
	bool currently_playing = tape_audio_is_active();
	if (currently_playing == false && tape_audio_eof() == false) {
		currently_playing = automata_port_is_waiting_for_tone(delta_tstates);
		if (currently_playing) {
			tape_audio_playback(true);
		}
	}
	// Reset timing when tape starts playing and this is the first port read
	if (currently_playing && !prev_audio_playing) {
		last_clock = clock_cycle;
	}

	prev_audio_playing = currently_playing;

	// Clamp huge deltas that occur during major ROM processing
	// Normal byte processing: 2000-5000 T-states (allow this)
	// Major processing (decompression, etc.): 100000+ T-states (clamp this)
	// We clamp to 5000 to allow legitimate byte processing but prevent huge jumps
	const uint64_t MAX_TAPE_DELTA = 5000;
	if (currently_playing && delta_tstates > MAX_TAPE_DELTA) {
		delta_tstates = MAX_TAPE_DELTA; // Clamp, don't pause
	}	

	// get audio pulses
	if (currently_playing) {
		uint8_t next_pulse = tape_audio_next_pulse(delta_tstates);
		if (next_pulse != 0xFF) {
			next_pulse = next_pulse ? 0x40 : 0x00;
			audio_set_level((uint8_t)(next_pulse >> 2));
			*value |= next_pulse;
		}
		else {
			tape_audio_sync();
		}
	}
}

void ula_read_port_FE(uint16_t addr, uint8_t* value) {

	// timing
	auto cpu_cycles = cpu_get_cycles();

	// keyboard 
	uint8_t key = (uint8_t)((addr >> 8) & 0xFF);
	uint8_t kbd = keyboard_get_map_addr(key);

	// clean bit 6 ear
	*value = (uint8_t)(kbd & 0xBF);

	ula_read_tape(cpu_cycles, value);
}

void ula_read_port(uint16_t addr, uint8_t* value) {	

	const uint16_t port = (uint16_t)(addr & 0x00FF);
	if (port == kPortFE) {

		ula_read_port_FE(addr, value);
		return;
	}

	*value = 0xFF;
}

void ula_write_port_FE(uint8_t value) {

	// border = value & 0x7;
	// mic = value & 0x8;
	// ear = value & 0x10;

	display_set_border_color((uint32_t)(value & 0x7));
	audio_set_level((uint8_t)(value & 0x18));

}

void ula_write_port(uint16_t addr, uint8_t value) {

	if (addr == kPagingControlPort) {
		memory_paging_bank_switch(value);
	}
	else {

		switch (addr & 0x00FF) {
		case kPortFE:
			ula_write_port_FE(value);
			break;
		default:
			break;
		}
	}
}

void ula_assert_INT_line() {

	interrupts_request_mi_c(0xFF);
}

bool ula_has_snow_effect() {

	uint8_t I = cpu_get_register8(CPU_REGISTER_I);
	
	if (I >= 0x40 && I <= 0x7F) {
		return true;
	}

	if (system_memory_get_machine_id() == kSystemSinclairSpectrum128) {

		if (I >= 0xC0 && I <= 0xFF) {
			return true;
		}
	}
	return false;
}