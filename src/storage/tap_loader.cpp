#include "tap_loader.h"
#include "tape_audio.h"
#include <stdio.h>
#include <memory.h>
#include <vector>

tap_info_head* tape_load_from_file(const char* filename) {

	uint32_t total_data_size = 0;
	FILE* f = nullptr;
	fopen_s(&f, filename, "rb");
	if (!f) return nullptr;
	tap_info_head* list_head = new tap_info_head();
	uint8_t header_block_info[TAP_HEADER_BLOCK_SIZE];
	while (!feof(f)) {

		// header block
		uint16_t len;
		if (fread(&len, 2, 1, f) != 1) {
			perror("error reading header block size");
			break;
		}

		if (len != TAP_HEADER_BLOCK_SIZE) {
			perror("invalid header block size");
			break;
		}
		if (fread(header_block_info, len, 1, f) != 1) {
			perror("error reading header block info");
			break;
		}
		if (header_block_info[0] != TAP_HEADER_TYPE) {
			
			perror("expected header block");
			break;
		}
		char file_name[10+1] = "";
		memcpy(file_name, &header_block_info[2], 10);
		uint16_t data_len = header_block_info[12] | (header_block_info[13] << 8);
		uint16_t load_addr = header_block_info[14] | (header_block_info[15] << 8);
		uint16_t program_len = header_block_info[16] | (header_block_info[17] << 8);

		// data block
		if (fread(&len, 2, 1, f) != 1) {

			perror("error reading data block size");
			break;
		}

		if (data_len != (len-2)) {
			perror("data length and header length value mismatch");
			break;
		}

		uint8_t data_type_flag;
		if (fread(&data_type_flag, 1, 1, f) != 1) {

			perror("error reading data type flag");
			break;
		}
		if (data_type_flag != TAP_DATA_BLOCK) {
			perror("expected data block");
			break;
		}

		uint8_t* data = new uint8_t[data_len];
		if (fread(data, data_len, 1, f) != 1) {
			perror("error reading data block");
			delete[] data;
			break;
		}
		uint8_t crc;
		if (fread(&crc, 1, 1, f) != 1) {
			perror("error reading crc of data block");
			delete[] data;
			break;
		}

		// data_len + 1 (for crc)
		total_data_size += data_len + 1;

		tap_info* info = new tap_info();
		info->header.file_name[10] = 0;
		memcpy(info->header.file_name, file_name, 10);
		info->header.length = data_len;
		info->header.program_length = program_len;
		info->header.offset = load_addr;
		info->header.program_type = header_block_info[1];
		info->data = data;
		info->size = data_len;
		info->offset = load_addr;
		info->crc = crc;
		info->next = nullptr;

		if (list_head->node == nullptr) {
			list_head->node = info;
		}
		else {
			tap_info* current = list_head->node;
			while (current->next != nullptr) {
				current = current->next;
			}
			current->next = info;
		}
	}
	list_head->data_size = total_data_size;
	fclose(f);
	return list_head;
}

void tape_free(tap_info_head* tape) {
	tap_info* current = tape->node;
	while (current != nullptr) {
		tap_info* next = current->next;
		delete[] current->data;
		delete current;
		current = next;
	}
	delete tape;
}

void tape_file_to_bytes(const char* filename, uint8_t** buffer_out, size_t* size_out) {

	FILE* f = nullptr;
	fopen_s(&f, filename, "rb");
	if (!f) return;
	fseek(f, 0, SEEK_END);
	*size_out = (size_t)ftell(f);
	fseek(f, 0, SEEK_SET);
	*buffer_out = new uint8_t[*size_out];
	fread(*buffer_out, *size_out, 1, f);
	fclose(f);
}