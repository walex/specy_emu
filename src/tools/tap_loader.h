#ifndef __TAP_LOADER_H__
#define __TAP_LOADER_H__

#include "platform.hpp"

constexpr uint8_t kTapHeaderBlockId = 0;
constexpr uint8_t kTapDataBlockId = 0xFF;
constexpr uint32_t kTapHeaderBlockSize = 19;
constexpr uint8_t kTapDataBlockTypeProgramBasic = 0;
constexpr uint8_t kTapDataBlockTypeNumericArray = 1;
constexpr uint8_t kTapDataBlockTypeCharacterArray = 2;
constexpr uint8_t kTapDataBlockTypeCode = 3;

#if defined(_MSC_VER)
#pragma pack(push, 1)
#define PACKED
#elif defined(__GNUC__) || defined(__clang__)
#define PACKED __attribute__((packed))
#else
#define PACKED
#endif

struct tap_level {
	uint64_t end_cycle;   // absolute cycle when pulse ends
	uint8_t  ear_level;   // 0 o 1
};

struct tap_pulse_data {
	uint64_t end_cycle;   // absolute cycle when pulse ends
	uint8_t  ear_level;   // 0 o 1
};

struct tap_pulse_block {

	tap_pulse_block() {
		data.reserve(1024 * 1024);
		tape_pulse_index = 0;
		start_cycle = 0;
		sync_cycles = 0;
		idx = 0;
	}
	uint64_t start_cycle;
	uint64_t sync_cycles;
	std::vector<tap_pulse_data> data;
	size_t tape_pulse_index;
	size_t idx;
};

struct tap_header {

	uint8_t flag;
	uint8_t type;
	char file_name[10];
	uint16_t data_length;
	uint16_t auto_start_line;
	uint16_t program_length;
	uint8_t crc;
};

struct tap_data {

	size_t length;
	uint8_t* bytes;
};

struct tap_info {
	tap_info(size_t index) : index(index) {}
	bool is_header;
	void* data;
	tap_info* next;
	tap_pulse_block pulses;
	size_t index;
	int freq;
};

struct tap_info_head {

	bool is_continous;
	size_t block_count = 0;
	tap_info* node = nullptr;
};

#if defined(_MSC_VER)
#pragma pack(pop)
#endif

tap_info_head* tap_loader_info_from_tap_file(const char* filename);
tap_info_head* tap_loader_info_from_wav_file(const char* filename);
void tap_loader_info_free(tap_info_head* tape);
void tap_loader_bytes_from_file(const char* filename, uint8_t** buffer_out, size_t* size_out);
void tap_loader_set_fast_mode(bool enable);
bool tap_loader_get_fast_mode();
#endif