#include "tape_audio.h"
#include "audio_render.h"
#include "z80.h"
#include "system_memory.h"
#include "tap_loader.h"

#define PILOT_PULSE_T 2168
#define SYNC1_T 667
#define SYNC2_T 735
#define BIT0_T 855
#define BIT1_T 1710
#define PAUSE_T Z80_CPU_FREQ_HZ // 1 sec
#define PILOT_HEADER 8063
#define PILOT_DATA 3223

struct TapePulse {
	uint64_t end_cycle;   // absolute cycle when pulse ends
	uint8_t  ear_level;   // 0 o 1
};

struct TapePulsesBlock {
	TapePulsesBlock(bool is_continuous = false) {
		pulses.reserve(1024 * 1024);
		tape_pulse_index = 0;
		start_cycle = 0;
		sync_cycles = 0;
		idx = 0;
		this->is_continuous = is_continuous;
	}
	uint64_t start_cycle;
	uint64_t sync_cycles;
	std::vector<TapePulse> pulses;
	size_t tape_pulse_index;
	size_t idx;
	bool is_continuous = false;
};

// puslse mode
static std::list<TapePulsesBlock*> tape_block_list;
static TapePulsesBlock* next_block = nullptr;
uint8_t current_ear = 0;
bool tape_active = false;

// info mode
static tap_info_head* tap_info_header = nullptr;
static tap_info* aux = nullptr;

void tape_audio_reset() {
	current_ear = 0;
	tape_active = false;
	for (auto block : tape_block_list) {
		delete block;
	}
	tape_block_list.clear();
	next_block = nullptr;
	tap_info_header = nullptr;
	aux = nullptr;
}

void tape_add_pause(std::vector<TapePulse>& pulses, uint32_t& t) {
	t += PAUSE_T;
	pulses.push_back({ t, 0 }); // EAR down during pause
}

void tape_add_pulse(std::vector<TapePulse>& pulses, uint64_t& t, uint32_t duration, uint8_t& level) {
	t += duration;
	pulses.push_back({ t, level });
	level ^= 1;
}

uint8_t tape_audio_next_pulse(uint64_t cycles) {	

	if (!tape_active)
		return 0xFF;

	if (!next_block) {
		tape_active = false;
		return 0xFF;
	}

	next_block->sync_cycles += cycles;
	auto& idx = next_block->idx;
	while (idx < next_block->pulses.size() &&
		next_block->sync_cycles >= (next_block->pulses[idx].end_cycle))
		current_ear = next_block->pulses[idx++].ear_level;

	if (idx == next_block->pulses.size()) {
		delete next_block;
		next_block = nullptr;
		return 0xFF;
	}
	return current_ear;
}

void tape_audio_set_bytes(uint8_t* data, size_t size) {
	uint8_t* data_end = data + size;
	uint64_t cycles = 0;
	uint8_t level = 1;

	tape_audio_reset();
	
	while (data + 2 <= data_end) {
		uint16_t block_size = (uint16_t)(data[0] | (data[1] << 8));
		data += 2;

		if (data + block_size > data_end) break;

		tape_block_list.push_back(new TapePulsesBlock());
		TapePulsesBlock& block = *tape_block_list.back();
		block.start_cycle = cycles;
		block.sync_cycles = cycles;
		uint8_t flag = data[0];
		bool is_header = (flag == 0x00);

		// Pilot tone
		int pilot_count = is_header ? PILOT_HEADER : PILOT_DATA;
		for (int i = 0; i < pilot_count; i++)
			tape_add_pulse(block.pulses, cycles, PILOT_PULSE_T, level);

		// Sync pulses
		tape_add_pulse(block.pulses, cycles, SYNC1_T, level);
		tape_add_pulse(block.pulses, cycles, SYNC2_T, level);

		// Data bits
		for (uint16_t i = 0; i < block_size; i++) {
			uint8_t byte = data[i];
			for (int b = 7; b >= 0; b--) {
				uint32_t duration = (byte & (1 << b)) ? BIT1_T : BIT0_T;
				tape_add_pulse(block.pulses, cycles, duration, level);
				tape_add_pulse(block.pulses, cycles, duration, level);
			}
		}

		data += block_size;

		// Pause between blocks (critical!)
		// Force EAR to 0 at start of pause if it's not already
		if (level != 0) {
			block.pulses.push_back({ cycles, 0 });
			level = 0;
		}
		// Maintain EAR at 0 during pause
		cycles += PAUSE_T;
		block.pulses.push_back({ cycles, 0 });
	}
}

bool tape_audio_is_active() {
	return tape_active;
}

bool tape_audio_eof() {
	return !(next_block != nullptr && next_block->pulses.size() > 0);
}

bool tape_audio_sync() {

	tape_active = false;
	if (next_block) {
		if (next_block->is_continuous == true)
			return (next_block->pulses.size() > 0);
		delete next_block;
		next_block = nullptr;
	}
	if (!tape_block_list.empty()) {
		next_block = tape_block_list.front();
		tape_block_list.pop_front();
		return (next_block->pulses.size() > 0);
	}
	return false;
}

void tape_audio_load_wav(const char* filename) {

	uint8_t* wav_buffer;
	size_t wav_size;
	int freq;
	tape_audio_reset();
	audio_render_load_wav(filename, &wav_buffer, wav_size, freq);
	if (wav_size > 0) {
		// convert wav to tape pulses
		uint8_t level = 0;
		uint64_t cycles = 0;
		// WAV format: 16bit signed PCM, mono, 44100Hz
		const uint32_t CYCLES_PER_SAMPLE = Z80_CPU_FREQ_HZ / freq;
		int16_t* samples = (int16_t*)wav_buffer;
		size_t sample_count = wav_size / sizeof(int16_t);
		TapePulsesBlock* tb = new TapePulsesBlock(true);
		tape_block_list.push_back(tb);
		for (size_t i = 0; i < sample_count; i++) {
			int16_t sample = samples[i];
			uint8_t sample_level = (sample >= 0) ? 1 : 0;
			if (sample_level != level) {
				// level change, add pulse
				tape_add_pulse(tb->pulses, cycles, CYCLES_PER_SAMPLE, level);
			}
			else {
				// same level, just advance cycles
				cycles += CYCLES_PER_SAMPLE;
			}
		}
		audio_render_free_wav(wav_buffer);
	}
	
}

void tape_audio_load_tap_raw(const char* filename) {

	uint8_t* tap_buffer;
	size_t tap_size;
	tap_file_to_bytes(filename, &tap_buffer, &tap_size);
	if (tap_size == 0) {
		printf("Error loading TAP file: %s\n", filename);
		return;
	}
	tape_audio_set_bytes(tap_buffer, tap_size);
	delete[] tap_buffer;
}

void tape_audio_next_data_block() {

	if (aux)
		aux = aux->next;
}

uint8_t* tape_audio_get_header_block_raw(size_t& size) {
	
	size = 0;
	if (!aux)
		return nullptr;
	size = sizeof(aux->header);
	return (uint8_t*)&aux->header;
}

uint8_t* tape_audio_get_data_block_raw(size_t& size) {

	size = 0;
	if (!aux)
		return nullptr;
	size = aux->size;
	return (uint8_t*)&aux->data;
}

void tape_audio_load_tap_info(const char* filename) {

	tap_free(tap_info_header);
	tap_info_header = tap_load_from_file(filename);
	if (tap_info_header && tap_info_header->node)
		aux = tap_info_header->node;
}

void tape_audio_from_file(const char* filename) {
	std::string file_str(filename);
	std::string ext = file_str.substr(file_str.find_last_of(".") + 1);
	if (ext == "tap" || ext == "TAP") {
		tape_audio_load_tap_raw(filename);
	}
	else if (ext == "wav" || ext == "WAV") {
		tape_audio_load_wav(filename);
	}
	else {
		printf("Unsupported tape file format: %s\n", filename);
	}
}

void tape_audio_playback(bool enable) {
	
	if ((tape_active = enable) == false)
		return;
	if (next_block)
		tape_active = (next_block->pulses.size() > 0);
	else
		tape_active = false;
	if (!tape_active)
		tape_active = tape_audio_sync();
}