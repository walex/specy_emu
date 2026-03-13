#ifndef _TAP_LOADER_H_
#define _TAP_LOADER_H_

#include "platform.h"

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

struct tap_header {
	uint8_t type;
	char file_name[10];
	uint16_t data_length;
	uint16_t auto_start_line;
	uint16_t program_length;
};

struct tap_info {

	tap_header header;
	uint32_t size;
	uint32_t offset;
	uint8_t crc;
	uint8_t* data;
	tap_info* next;
};

struct tap_info_head {

	uint32_t data_size = 0;
	tap_info* node = nullptr;
};

#if defined(_MSC_VER)
#pragma pack(pop)
#endif

tap_info_head* tap_load_from_file(const char* filename);
void tap_free(tap_info_head* tape);
void tap_file_to_bytes(const char* filename, uint8_t** buffer_out, size_t* size_out);

#endif