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

tap_info* tape_load_from_file(const char* filename);
void tape_free(tap_info* tape);

#endif