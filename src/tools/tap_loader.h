#ifndef _TAP_LOADER_H_
#define _TAP_LOADER_H_

#include "platform.h"

constexpr uint8_t TAP_HEADER_BLOCK = 0;
constexpr uint8_t TAP_DATA_BLOCK = 0xFF;
constexpr uint32_t TAP_HEADER_BLOCK_SIZE = 19;
constexpr uint8_t TAP_DATA_BLOCK_TYPE_BASIC = 0;
constexpr uint8_t TAP_DATA_BLOCK_TYPE_NUMERIC_ARRAY = 1;
constexpr uint8_t TAP_DATA_BLOCK_TYPE_CHARACTER_ARRAY = 2;
constexpr uint8_t TAP_DATA_BLOCK_TYPE_CODE = 3;

struct tap_header {

	char file_name[10 + 1];
	uint32_t length;
	uint32_t offset;
	uint32_t program_type;
	uint16_t program_length;
};

struct tap_info {

	tap_header header;
	uint8_t* data;
	uint32_t size;
	uint32_t offset;
	uint8_t crc;
	tap_info* next;
};

struct tap_info_head {

	tap_info* node = nullptr;
	uint32_t data_size = 0;
};

tap_info_head* tap_load_from_file(const char* filename);
void tap_free(tap_info_head* tape);
void tap_file_to_bytes(const char* filename, uint8_t** buffer_out, size_t* size_out);

#endif