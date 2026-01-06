#include "tap_loader.h"
#include <stdio.h>
#include <memory.h>

tap_info* tape_load_from_file(const char* filename) {

	
	const uint8_t TAP_HEADER_TYPE = 0;
	const uint8_t TAP_DATA_BLOCK = 0xFF;
	const uint32_t TAP_HEADER_BLOCK_SIZE = 19;
	FILE* f = nullptr;
	fopen_s(&f, filename, "rb");
	if (!f) return nullptr;
	tap_info* list_head = nullptr;
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

		if (list_head == nullptr) {
			list_head = info;
		}
		else {
			tap_info* current = list_head;
			while (current->next != nullptr) {
				current = current->next;
			}
			current->next = info;
		}
	}

	fclose(f);
	return list_head;
}

void tape_free(tap_info* tape) {
	tap_info* current = tape;
	while (current != nullptr) {
		tap_info* next = current->next;
		delete[] current->data;
		delete current;
		current = next;
	}
}

#include <thread>
#include "clk_master.h"
extern "C" void __stdcall SetRegPC(uint64_t value);
extern "C" void __stdcall SetRegIX(uint16_t value);
extern "C" void __stdcall SetRegD(uint8_t value);
extern "C" void __stdcall SetRegE(uint8_t value);
void thread_load_tape(const char* file_name, uint8_t* mem, uint32_t delay_secs) {

	
	std::this_thread::sleep_for(std::chrono::seconds(5));

	tap_info* info = tape_load_from_file(file_name);

	// load BASIC
	const uint16_t VARS = 0x5C4B;
	const uint16_t PROG = 0x5C53;
	const uint16_t E_LINE = 0x5C59;
	uint16_t loadAddr = *((uint16_t*)(mem + PROG));

	uint16_t last_pos = loadAddr + info->header.program_length;
	uint16_t I = (last_pos / 256);
	uint16_t X = last_pos - 256 * I;
	I <<= 8;
	uint16_t v = I | X;
	std::this_thread::sleep_for(std::chrono::seconds(5));
	SetRegPC(((uint64_t)mem) + 0x0805);
	SetRegIX(v);
	SetRegD(0);
	SetRegE(0);
	memcpy(mem + loadAddr, info->data, info->header.program_length);

	// load screen
	//memcpy(mem + info->next->offset, info->next->data, info->next->size);


	// load CODE
	//memcpy(mem + info->next->next->offset, info->next->next->data, info->next->next->size);

	tape_free(info);
}