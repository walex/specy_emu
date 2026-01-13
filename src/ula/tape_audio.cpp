#include "tape_audio.h"
#include "audio_render.h"
#include "z80.h" // TODO: replace for cpu.h
#include "tap_loader.h"
#include <vector>
#include <string>

static constexpr uint32_t PILOT_PULSE_T = 2168;
static constexpr uint32_t SYNC1_T = 667;
static constexpr uint32_t SYNC2_T = 735;
static constexpr uint32_t BIT0_T = 855;
static constexpr uint32_t BIT1_T = 1710;
constexpr uint32_t PAUSE_T = 3500000; // 1 sec
constexpr uint32_t PILOT_HEADER = 8063;
constexpr uint32_t PILOT_DATA = 3223;
static uint64_t sync_cycles = 0;

struct TapePulse {
	uint64_t end_cycle;   // absolute cycle when pulse ends
	uint8_t  ear_level;   // 0 o 1
};

static std::vector<TapePulse> tape_pulses;
static size_t tape_pulse_index = 0;
uint8_t current_ear = 0;
bool tape_active = false;


void tape_audio_reset() {
	tape_pulses.clear();
	tape_pulses.reserve(1024 * 1024);
	tape_pulse_index = 0;
	current_ear = 0;
	tape_active = false;
}

static void tape_add_pause(uint32_t& t) {
	t += PAUSE_T;
	tape_pulses.push_back({ t, 0 }); // EAR down during pause
}

static void tape_add_pulse(uint64_t& t, uint32_t duration, uint8_t& level) {
	t += duration;
	tape_pulses.push_back({ t, level });
	level ^= 1;
}

uint8_t tape_audio_next_pulse(uint64_t cycles) {

	if (!tape_active)
		return 0;

	// ---- update tape according to cycles ----
	if (tape_active && tape_pulse_index < tape_pulses.size()) {

		while (tape_pulse_index < tape_pulses.size() &&
			cycles >= (sync_cycles+tape_pulses[tape_pulse_index].end_cycle)) {

			current_ear = tape_pulses[tape_pulse_index].ear_level;
			tape_pulse_index++;
		}

		// TODO: support multi charge tape loading
		// end tape
		if (tape_pulse_index >= tape_pulses.size())
			tape_active = false;
	}
	return current_ear;
}

void tape_audio_set_bytes(uint8_t* data, size_t size) {

	uint8_t* data_ptr = data;

	uint64_t cycles = 0;

	tape_audio_reset();

	uint8_t level = 0;

	uint16_t data_len;
	uint8_t* data_end = (uint8_t*)(data + size);
	while (data < data_end) {

		uint16_t block_size = data[0] | (data[1] << 8);

		// pass 2 bytes block length
		data += 2;

		if (data[0] == 0) {
			// header block
			data_len = data[12] | (data[13] << 8);

			// Pilot
			for (int i = 0; i < PILOT_HEADER; i++)
				tape_add_pulse(cycles, PILOT_PULSE_T, level);

			// Sync
			tape_add_pulse(cycles, SYNC1_T, level);
			tape_add_pulse(cycles, SYNC2_T, level);

			for (int i = 0; i < block_size; i++) {
				uint8_t byte = data[i];
				for (int b = 7; b >= 0; b--) {
					uint32_t d = (byte & (1 << b)) ? BIT1_T : BIT0_T;
					tape_add_pulse(cycles, d, level);
					tape_add_pulse(cycles, d, level);
				}
			}
		}
		else {
			data_len = block_size - 2;
			// Pilot
			for (int i = 0; i < PILOT_DATA; i++)
				tape_add_pulse(cycles, PILOT_PULSE_T, level);

			// Sync
			tape_add_pulse(cycles, SYNC1_T, level);
			tape_add_pulse(cycles, SYNC2_T, level);

			for (int i = 0; i < data_len + 2; i++) {
				uint8_t byte = data[i];
				for (int b = 7; b >= 0; b--) {
					uint32_t d = (byte & (1 << b)) ? BIT1_T : BIT0_T;
					tape_add_pulse(cycles, d, level);
					tape_add_pulse(cycles, d, level);
				}
			}			
		}
		data += block_size;
	}

	tape_add_pause((uint32_t&)cycles);
	current_ear = 0;
	tape_active = true;

	delete[] data_ptr;
}

void tape_audio_sync(uint64_t cycles) {

	sync_cycles = cycles;
}

void tape_audio_load_wav(const char* filename) {

	uint8_t* wav_buffer;
	size_t wav_size;
	audio_render_load_wav(filename, &wav_buffer, &wav_size);
	if (wav_size > 0) {
		// convert wav to tape pulses
		uint8_t level = 0;
		uint64_t cycles = 0;
		tape_audio_reset();
		// WAV format: 16bit signed PCM, mono, 44100Hz
		const uint32_t SAMPLE_RATE = 44100;
		const uint32_t CYCLES_PER_SAMPLE = Z80_CPU_FREQ_HZ / SAMPLE_RATE;
		int16_t* samples = (int16_t*)wav_buffer;
		size_t sample_count = wav_size / sizeof(int16_t);
		for (size_t i = 0; i < sample_count; i++) {
			int16_t sample = samples[i];
			uint8_t sample_level = (sample >= 0) ? 1 : 0;
			if (sample_level != level) {
				// level change, add pulse
				tape_add_pulse(cycles, CYCLES_PER_SAMPLE, level);
			}
			else {
				// same level, just advance cycles
				cycles += CYCLES_PER_SAMPLE;
			}
		}
		current_ear = 0;
		tape_active = true;
		audio_render_free_wav(wav_buffer);
	}
	
}

void tape_audio_load_tap(const char* filename) {

	uint8_t* tap_buffer;
	size_t tap_size;
	tap_file_to_bytes(filename, &tap_buffer, &tap_size);
	tape_audio_set_bytes(tap_buffer, tap_size);
}

void tape_audio_from_file(const char* filename) {
	std::string file_str(filename);
	std::string ext = file_str.substr(file_str.find_last_of(".") + 1);
	if (ext == "tap" || ext == "TAP") {
		tape_audio_load_tap(filename);
	}
	else if (ext == "wav" || ext == "WAV") {
		tape_audio_load_wav(filename);
	}
	else {
		printf("Unsupported tape file format: %s\n", filename);
	}
}