#include "ula.h"
#include "tape_audio.h"
#include "z80.h"
#include "system_memory.h"
#include "display.h"
#include "audio.h"
#include "tempo.h"
#include "clk_master.h"
#include "automata.h"

static clock_master_handle master_clock;

void ula_on_cpu_cycles(uint64_t total_cycles);

void ula_init(uint8_t* system_memory, Ula_Callbacks* cb) {

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
	clk_master_destroy(master_clock);
}

void ula_on_tape_load_block() {

	tape_audio_sync();
}

void ula_on_cpu_cycles(uint64_t total_cycles) {

	static uint64_t last_cycles = 0;
	static uint64_t int_cycles = 0;

	uint64_t delta_cycles = total_cycles - last_cycles;
	audio_tick(delta_cycles);
	display_tick(delta_cycles);
	keyboard_tick(delta_cycles);
	last_cycles = total_cycles;
}

bool ula_port_is_waiting_for_tone(uint64_t delta_tstates) {

	constexpr int TONE_CHECK_MAX_TIMES = 5;
	constexpr uint64_t TONE_CHECK_MIN_RANGE = 70;
	constexpr uint64_t TONE_CHECK_MAX_RANGE = 75;
	constexpr uint64_t TONE_CHECK_CYCLE_INTERVAL = Z80_CPU_FREQ_HZ / 10;
	static uint64_t port_calls = 0;
	static uint64_t port_calls_cycles_acum = 0;
	static int tone_check_times = 0;

	bool result = false;
	port_calls_cycles_acum += delta_tstates;
	port_calls++;
	if (port_calls_cycles_acum >= TONE_CHECK_CYCLE_INTERVAL) {

		uint64_t delta = TONE_CHECK_CYCLE_INTERVAL / port_calls;
		if (delta > TONE_CHECK_MIN_RANGE && delta < TONE_CHECK_MAX_RANGE)
			tone_check_times++;
		else
			tone_check_times = 0;
		if (tone_check_times == TONE_CHECK_MAX_TIMES) {
			tone_check_times = 0;
			result = true;
		}
		port_calls_cycles_acum = 0;
		port_calls = 0;
	}
	return result;
}

void ula_read_port(uint16_t addr, uint8_t* value) {

	static uint64_t last_clock = 0;
	static bool prev_audio_playing = false;
	const uint16_t port = addr & 0x00FF;	

	if (port == 0xFE) {

		// timing
		auto clock_cycle = cpu_get_cycles();

		uint64_t delta_tstates = clock_cycle - last_clock;
		last_clock = clock_cycle;

		// Track tape playing state
		bool currently_playing = tape_audio_is_active();
		if (currently_playing == false && tape_audio_eof() == false) {
			currently_playing = ula_port_is_waiting_for_tone(delta_tstates);
			if (currently_playing) {
				printf("Detected tape tone via timing analysis\n");
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

		// keyboard 
		uint8_t key = (addr >> 8) & 0xFF;
		uint8_t kbd = keyboard_get_map_addr(key);

		// exclude bit 6 ear
		*value = (kbd & 0xBF);

		// get audio pulses
		if (currently_playing) {
			uint8_t next_pulse = tape_audio_next_pulse(delta_tstates);
			if (next_pulse != 0xFF) {
				next_pulse = next_pulse ? 0x40 : 0x00;
				audio_set_level(next_pulse >> 2);
				*value |= next_pulse;
			}
			else {
				tape_audio_sync();
			}
		}

		return;
	}

	*value = 0xFF;
}

void ula_write_port_FE(uint8_t value) {

	// border = value & 0x7;
	// mic = value & 0x8;
	// ear = value & 0x10;

	display_set_border_color(value & 0x7);
	audio_set_level(value & 0x18);

}

void ula_assert_INT_line() {

	interrupts_request_mi_c(0xFF);
}

bool ula_has_snow_effect() {

	uint8_t I = cpu_get_register8(CPU_REGISTER_I);
	
	if (I >= 0x40 && I <= 0x7F) {
		return true;
	}

	if (system_memory_get_machine_id() == SPECTRUM_128K_SYSTEM) {

		if (I >= 0xC0 && I <= 0xFF) {
			return true;
		}
	}
	return false;
}