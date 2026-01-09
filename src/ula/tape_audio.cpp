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
			cycles >= tape_pulses[tape_pulse_index].end_cycle) {

			current_ear = tape_pulses[tape_pulse_index].ear_level;
			tape_pulse_index++;
		}

		if (tape_pulse_index >= tape_pulses.size())
			tape_active = false;
	}
	return current_ear;
}

void tape_audio_set_bytes(uint64_t cycles, const uint8_t* data, size_t size) {

	tape_audio_reset();

	uint8_t level = 0;

	uint8_t* data_end = (uint8_t*)(data + size);
	while (data < data_end) {

		// pass 2 bytes block length
		data += 2;
		// header block
		uint16_t data_len = data[12] | (data[13] << 8);
		// tape_audio_add_block(&data[0], TAP_HEADER_BLOCK_SIZE, true);
		// move to data block

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
}

/*

static uint64_t tape_time = 0;

void tape_audio_reset() {
	tape_pulses.clear();
	tape_pulse_index = 0;
	current_ear = 0;
	tape_time = 0;
	tape_active = false;
}

static void tape_audio_add_pause(uint64_t duration) {
	tape_time += duration;
}

static void tape_audio_add_pulse(uint32_t duration) {
	tape_time += duration;
	current_ear ^= 1;
	tape_pulses.push_back({ tape_time, current_ear });
}

static void tape_audio_add_block(const uint8_t* data, size_t size, bool is_header) {

	tape_audio_add_pause(PAUSE_T);

	uint32_t pilot = is_header ? PILOT_HEADER : PILOT_DATA;

	for (uint32_t i = 0; i < pilot; i++)
		tape_audio_add_pulse(PILOT_PULSE_T);

	tape_audio_add_pulse(SYNC1_T);
	tape_audio_add_pulse(SYNC2_T);

	for (size_t i = 0; i < size; i++) {
		uint8_t byte = data[i];
		for (int b = 7; b >= 0; b--) {
			uint32_t d = (byte & (1 << b)) ? BIT1_T : BIT0_T;
			tape_audio_add_pulse(d);
			tape_audio_add_pulse(d);
		}
	}
}

uint8_t tape_audio_next_pulse(uint64_t cpu_cycles) {

	if (!tape_active)
		return current_ear;

	while (tape_pulse_index < tape_pulses.size() &&
		cpu_cycles >= tape_pulses[tape_pulse_index].end_cycle) {

		current_ear = tape_pulses[tape_pulse_index].ear_level;
		tape_pulse_index++;
	}

	if (tape_pulse_index >= tape_pulses.size())
		tape_active = false;

	return current_ear;
}


void tape_audio_set_bytes(uint64_t cycles, const uint8_t* data, size_t size) {

	tape_audio_reset();

	// el parseo va en tap_loader ? 
	// assuming data is ok
	uint8_t* data_end = (uint8_t*)(data + size);
	while (data < data_end) {

		// pass 2 bytes block length
		data += 2;
		// header block
		uint16_t data_len = data[12] | (data[13] << 8);
		tape_audio_add_block(&data[0], TAP_HEADER_BLOCK_SIZE, true);
		// move to data block
		data += TAP_HEADER_BLOCK_SIZE;
		// pass 2 bytes block length
		data += 2;
		tape_audio_add_block(data, data_len + 2, false);
		data += data_len + 2;
	}

	tape_active = true;
}

void tape_audio_set_bytes2(uint64_t cycles, const uint8_t* data, size_t size) {

	tape_audio_reset();

	// el parseo va en tap_loader ? 
	// assuming data is ok
	uint8_t* data_end = (uint8_t * )(data + size);
	while (data < data_end) {

		// pass 2 bytes block length
		data += 2;
		// header block
		uint16_t data_len = data[12] | (data[13] << 8);
		tape_audio_add_block(&data[0], TAP_HEADER_BLOCK_SIZE, true);
		// move to data block
		data += TAP_HEADER_BLOCK_SIZE;
		// pass 2 bytes block length
		data += 2;
		tape_audio_add_block(data, data_len + 2, false);
		data += data_len + 2;
	}

	tape_active = true;
}
*/
//void tape_file_to_bytes(const char* filename, uint8_t** buffer_out, size_t* size_out) {
//
//	FILE* f = nullptr;
//	fopen_s(&f, filename, "rb");
//	if (!f) return;
//	uint64_t block_offset = 0;
//	*buffer_out = nullptr;
//	*size_out = 0;
//	std::vector<uint8_t> block_info;
//	while (!feof(f)) {
//
//		// header block
//		uint16_t len;
//		if (fread(&len, 2, 1, f) != 1) {
//			perror("error reading header block size");
//			break;
//		}
//
//		if (len != TAP_HEADER_BLOCK_SIZE) {
//			perror("invalid header block size");
//			break;
//		}
//
//		block_info.resize(block_offset + len);
//		if (fread(&block_info[block_offset], len, 1, f) != 1) {
//			perror("error reading header block info");
//			break;
//		}
//		if (block_info[block_offset] != TAP_HEADER_TYPE) {
//
//			perror("expected header block");
//			break;
//		}
//
//		uint16_t data_len = block_info[block_offset + 12] | (block_info[block_offset + 13] << 8);
//
//		// data block
//		if (fread(&len, 2, 1, f) != 1) {
//
//			perror("error reading data block size");
//			break;
//		}
//
//		if (data_len != (len - 2)) {
//			perror("data length and header length value mismatch");
//			break;
//		}
//		block_offset += block_info.size();
//		block_info.resize(block_offset + len);
//
//		if (fread(&block_info[block_offset], len, 1, f) != 1) {
//			perror("error reading data block");
//			break;
//		}
//
//		if (block_info[block_offset] != TAP_DATA_BLOCK) {
//			perror("expected data block");
//			break;
//		}
//
//	}
//
//	uint8_t* buffer = new uint8_t[block_info.size()];
//	memcpy(buffer, block_info.data(), block_info.size());
//
//	*buffer_out = buffer;
//	*size_out = block_info.size();
//}