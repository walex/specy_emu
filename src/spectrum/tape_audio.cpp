#include "tape_audio.h"
#include "audio_render.h"
#include "z80.h"
#include "system_memory.h"
#include "tap_loader.h"
#include "audio.h"

#define PILOT_PULSE_T 2168
#define SYNC1_T 667
#define SYNC2_T 735
#define BIT0_T 855
#define BIT1_T 1710
#define PAUSE_T Z80_CPU_FREQ_HZ // 1 sec
#define PILOT_HEADER 8063
#define PILOT_DATA 3223

static struct _tape_audio_data {
public:
	_tape_audio_data();
	~_tape_audio_data();
	void reset();
	bool is_active() const;
	void is_active(bool value);
	uint8_t ear_level() const;
	void ear_level(uint8_t value);
	void next();
	bool load(const char* filename);
	tap_info_head* get_header() const;
	void add_pulse(tap_info* info, uint64_t& cycles, uint8_t& level);
	uint8_t next_pulse(uint64_t cycles);
	uint8_t* read_block(uint8_t block_type, size_t& size);
	bool has_pulses() const;
	void set_fast_mode(bool value) { fast_mode = value; }
	bool get_fast_mode() const { return fast_mode; }
private:
	// info
	tap_info_head* tap_info_header;
	tap_info* aux;
	uint8_t current_ear;
	// enable
	bool tape_active;
	// mode
	bool fast_mode;
} tape_audio_data;

void tape_add_pause(std::vector<tap_pulse_data>& pulses, uint32_t& t) {
	t += PAUSE_T;
	pulses.push_back({ t, 0 }); // EAR down during pause
}

void tape_add_pulse(std::vector<tap_pulse_data>& pulses, uint64_t& t, uint32_t duration, uint8_t& level) {
	t += duration;
	pulses.push_back({ t, level });
	level ^= 1;
}

uint8_t tape_audio_next_pulse(uint64_t cycles) {	

	if (!tape_audio_data.is_active())
		return 0xFF;

	return tape_audio_data.next_pulse(cycles);	
}

uint8_t* tape_audio_read_block(uint8_t block_type, size_t& size) {
	
	size = 0;
	if (!tape_audio_data.is_active())
		return nullptr;

	return tape_audio_data.read_block(block_type, size);
}

void tape_audio_add_pulses_from_bytes(std::vector<tap_pulse_data>& pulses, uint64_t& cycles, uint8_t& level, uint8_t* data, size_t size) {
	
	for (uint16_t i = 0; i < size; i++) {
		uint8_t byte = data[i];
		for (int b = 7; b >= 0; b--) {
			uint32_t duration = (byte & (1 << b)) ? BIT1_T : BIT0_T;
			tape_add_pulse(pulses, cycles, duration, level);
			tape_add_pulse(pulses, cycles, duration, level);
		}
	}
}

void tape_audio_set_bytes_from_tap_info(tap_info_head* header) {

	uint64_t cycles = 0;
	uint8_t level = 1;

	if (!header || !header->node) {
		printf("No TAP info available\n");
		return;
	}
	
	tap_info* info = header->node;
	while (info) {

		tape_audio_data.add_pulse(info, cycles, level);

		// next block
		info = info->next;
	}
}

void tape_audio_load_wav(const char* filename) {
	/*
	uint8_t* wav_buffer;
	size_t wav_size;
	int freq;
	tape_audio_data.reset();
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
		//tape_block_list.push_back(tb);
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
	*/
}

void tape_audio_load_tap(const char* filename) {

	if (!tape_audio_data.load(filename))
		printf("Error loading TAP file: %s\n", filename);
	else
		tape_audio_set_bytes_from_tap_info(tape_audio_data.get_header());	
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

void tape_audio_next_block() {	
	tape_audio_data.next();
}

void tape_audio_next_pulses_block() {
	tape_audio_set_fast_mode(false);
	tape_audio_next_block();
}

void tape_audio_set_fast_mode(bool value) {
	tape_audio_data.set_fast_mode(value);
}

bool tape_audio_get_fast_mode() {
	return tape_audio_data.get_fast_mode();
}

uint8_t tape_audio_pulse_step(uint64_t delta_cycles) {

	uint8_t next_pulse = tape_audio_next_pulse(delta_cycles);
	if (next_pulse != 0xFF) {
		next_pulse = next_pulse ? 0x40 : 0x00;
		audio_set_level((uint8_t)(next_pulse >> 2));
		return next_pulse;
	}

	return 0xFF;
}

uint8_t tape_audio_block_step() {

	uint16_t pc = cpu_get_register16(CPU_REGISTER_PC);
	uint16_t af = cpu_get_register16(CPU_REGISTER_AF); // a
	uint16_t ix = cpu_get_register16(CPU_REGISTER_IX); // copy addr
	uint16_t de = cpu_get_register16(CPU_REGISTER_DE); // copy size
	uint16_t hl = cpu_get_register16(CPU_REGISTER_HL); // a
	uint8_t a = (uint8_t)(af >> 8); // a == 0 header, a == 0xFF data

	uint8_t* data = nullptr;
	size_t size = 0;

	data = tape_audio_read_block(a, size);
	if (!data) {
		printf("Error getting %s block", a ? "data" : "header");
		return 0;
	}
	if (size-2 != de) {
		printf("Error incorrect block size in:%u tape:%u", de, (uint16_t)(size));
		return 0;
	}
	data++;
	memcpy(system_memory_get_pointer(ix), data, de);

	af |= 1;
	cpu_set_register16(CPU_REGISTER_AF, af);
	cpu_force_next_opcode(RET_OPCODE);
	tape_audio_data.is_active(false);
	return 0;
}

void tape_audio_block_sync() {
	if (tape_audio_get_fast_mode()) {
		tape_audio_next_block();
		tape_audio_block_step();
	}
}

bool tape_audio_is_active() {
	return tape_audio_data.is_active();
}

_tape_audio_data::_tape_audio_data() : fast_mode(true) {
	reset();
}

_tape_audio_data::~_tape_audio_data() {
	reset();
}

void _tape_audio_data::reset() {
	current_ear = 0;
	tape_active = false;
	tap_info_header = nullptr;
	aux = nullptr;
	tap_loader_info_free(tap_info_header);
}

bool _tape_audio_data::is_active() const {
	return tape_active;
}

void _tape_audio_data::is_active(bool value) {
	tape_active = value;
}

uint8_t _tape_audio_data::ear_level() const {
	return current_ear;
}

void _tape_audio_data::ear_level(uint8_t value) {
	current_ear = value;
}

void _tape_audio_data::next() {
	if (!aux) {
		if (tap_info_header && tap_info_header->node)
			aux = tap_info_header->node;
		this->is_active(aux != nullptr);
	}
	else if (aux->next) {
		aux = aux->next;
		this->is_active(true);
	} else
		this->is_active(false);
	
}

bool _tape_audio_data::load(const char* filename) {
	this->reset();
	tap_info_header = tap_loader_info_from_file(filename);
	if (tap_info_header && tap_info_header->node)
		tape_audio_set_bytes_from_tap_info(this->get_header());
	return (tap_info_header != nullptr);
}

tap_info_head* _tape_audio_data::get_header() const {
	return tap_info_header;
}

void _tape_audio_data::add_pulse(tap_info* info, uint64_t& cycles, uint8_t& level) {
	if (!info)
		return;
	auto& block = info->pulses;
	block.start_cycle = cycles;
	block.sync_cycles = cycles;
	bool is_header = info->is_header;
	size_t block_size;
	uint8_t* data;
	if (is_header) {
		block_size = sizeof(tap_header);
		data = (uint8_t*)info->data;
	}
	else {
		block_size = ((tap_data*)info->data)->length;
		data = ((tap_data*)info->data)->bytes;
	}
	// Pilot tone
	int pilot_count = is_header ? PILOT_HEADER : PILOT_DATA;
	for (int i = 0; i < pilot_count; i++)
		tape_add_pulse(block.data, cycles, PILOT_PULSE_T, level);

	// Sync pulses
	tape_add_pulse(block.data, cycles, SYNC1_T, level);
	tape_add_pulse(block.data, cycles, SYNC2_T, level);

	// Data bits
	tape_audio_add_pulses_from_bytes(block.data, cycles, level, data, block_size);

	// Pause between blocks (critical!)
	// Force EAR to 0 at start of pause if it's not already
	if (level != 0) {
		block.data.push_back({ cycles, 0 });
		level = 0;
	}
	// Maintain EAR at 0 during pause
	cycles += PAUSE_T;
	block.data.push_back({ cycles, 0 });
}

uint8_t* _tape_audio_data::read_block(uint8_t block_type, size_t& size) {

	if (!aux) {
		this->is_active(false);
		return nullptr;
	}

	bool request_ok = (block_type == 0 && aux->is_header == true) || (block_type == 0xFF && aux->is_header == false);
	if (!request_ok) {

		printf("Error: requested block type %u does not match current block type", block_type);
		this->is_active(false);
		return nullptr;
	}

	uint8_t* data;
	if (block_type == 0) {
		size = sizeof(tap_header);
		data = (uint8_t*)aux->data;
	}
	else {
		size = ((tap_data*)aux->data)->length;
		data = ((tap_data*)aux->data)->bytes;
	}
	return data;
}

uint8_t _tape_audio_data::next_pulse(uint64_t cycles) {

	if (!aux || !aux->pulses.data.size()) {
		this->is_active(false);
		return 0xFF;
	}

	std::vector<tap_pulse_data>& pulse_data = aux->pulses.data;
	aux->pulses.sync_cycles += cycles;
	auto& idx = aux->pulses.idx;
	while (idx < pulse_data.size() &&
		aux->pulses.sync_cycles >= (pulse_data[idx].end_cycle))
		this->ear_level(pulse_data[idx++].ear_level);

	if (idx == pulse_data.size()) {
		pulse_data.clear();
		return 0xFF;
	}
	return this->ear_level();
}

bool _tape_audio_data::has_pulses() const {
	return (aux != nullptr) && (aux->pulses.data.size() > 0);
}