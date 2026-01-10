#include "tape_audio.h"
#include <vector>

static constexpr uint32_t PILOT_PULSE_T = 2168;
static constexpr uint32_t SYNC1_T = 667;
static constexpr uint32_t SYNC2_T = 735;
static constexpr uint32_t BIT0_T = 855;
static constexpr uint32_t BIT1_T = 1710;
constexpr uint32_t PAUSE_T = 3500000; // 1 segundo
constexpr uint32_t PILOT_HEADER = 8063;
constexpr uint32_t PILOT_DATA = 3223;

struct TapePulse {
	uint64_t end_cycle;   // ciclo absoluto
	uint8_t  ear_level;   // 0 o 1
};

static std::vector<TapePulse> tape_pulses;
static size_t tape_pulse_index = 0;
uint8_t current_ear = 0;
bool tape_active = false;


void tape_audio_reset() {
	tape_pulses.clear();
	tape_pulse_index = 0;
	current_ear = 0;
	tape_active = false;
}

static void tape_add_pause(uint32_t& t) {
	t += PAUSE_T;
	tape_pulses.push_back({ t, 0 }); // EAR bajo durante pausa
}

static void tape_add_pulse(uint64_t& t, uint32_t duration, uint8_t& level) {
	t += duration;
	tape_pulses.push_back({ t, level });
	level ^= 1;
}

uint8_t tape_audio_next_pulse(uint64_t cycles) {

	if (!tape_active)
		return 0;

	// ---- ACTUALIZAR TAPE SEGÚN CICLOS ----
	if (tape_active && tape_pulse_index < tape_pulses.size()) {

		while (tape_pulse_index < tape_pulses.size() &&
			cycles >= (cycles-tape_pulses[tape_pulse_index].end_cycle)) {

			current_ear = tape_pulses[tape_pulse_index].ear_level;
			tape_pulse_index++;
		}

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

	uint8_t* data_end = (uint8_t*)(data + size);
	while (data < data_end) {

		// pass 2 bytes block length
		data += 2;
		// header block
		uint16_t data_len = data[12] | (data[13] << 8);

		// Pilot
		for (int i = 0; i < PILOT_HEADER; i++)
			tape_add_pulse(cycles, PILOT_PULSE_T, level);

		// Sync
		tape_add_pulse(cycles, SYNC1_T, level);
		tape_add_pulse(cycles, SYNC2_T, level);

		for (int i = 0; i < TAP_HEADER_BLOCK_SIZE; i++) {
			uint8_t byte = data[i];
			for (int b = 7; b >= 0; b--) {
				uint32_t d = (byte & (1 << b)) ? BIT1_T : BIT0_T;
				tape_add_pulse(cycles, d, level);
				tape_add_pulse(cycles, d, level);
			}
		}
		data += TAP_HEADER_BLOCK_SIZE;
		// pass 2 bytes block length
		data += 2;

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
		data += data_len + 2;
	}

	tape_add_pause((uint32_t&)cycles);
	current_ear = 0;
	tape_active = true;

	delete[] data_ptr;
}

