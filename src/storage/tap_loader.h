#ifndef _TAP_LOADER_H_
#define _TAP_LOADER_H_

#include <stdint.h>



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

tap_info_head* tape_load_from_file(const char* filename);
void tape_free(tap_info_head* tape);
void tape_file_to_bytes(const char* filename, uint8_t** buffer_out, size_t* size_out);

#endif