#include "tap_loader.h"
#include "tape_audio.h"

static bool tap_loader_fast_mode = false;

void tap_loader_on_file_error(FILE* f, const char* msg) {

	if (feof(f))
		perror("file reading end");
	else
		perror(msg);
}

uint16_t tap_loader_read_header(FILE* f, uint8_t header_block_info[kTapHeaderBlockSize]) {

	if (fread(header_block_info, 1, 1, f) != 1) {

		tap_loader_on_file_error(f, "error reading header block info flag");
		return 0;
	}
	if (header_block_info[0] != kTapHeaderBlockId) {

		tap_loader_on_file_error(f, "expected header block");
		return 0;
	}
	if (fread(&header_block_info[1], kTapHeaderBlockSize-1, 1, f) != 1) {

		tap_loader_on_file_error(f, "error reading header block info");
		return 0;
	}
	
	return (uint16_t)(header_block_info[12] | (header_block_info[13] << 8));
}

uint8_t* tap_loader_read_data(FILE* f, uint16_t& len) {

	uint8_t data_type_flag;
	if (fread(&data_type_flag, 1, 1, f) != 1) {

		tap_loader_on_file_error(f, "error reading data type flag");
		return nullptr;
	}

	if (data_type_flag != kTapDataBlockId) {

		tap_loader_on_file_error(f, "expected data block");
		return nullptr;
	}

	uint8_t* data = new uint8_t[len]; // data plus flag and crc byte
	data[0] = data_type_flag;
	if (fread(&data[1], len-2, 1, f) != 1) {

		tap_loader_on_file_error(f, "error reading data block");
		delete[] data;
		return nullptr;
	}
	if (fread(&data[len - 1], 1, 1, f) != 1) {

		tap_loader_on_file_error(f, "error reading crc of data block");
		delete[] data;
		return nullptr;
	}
	return data;
}

tap_info_head* tap_loader_info_from_file(const char* filename) {

	size_t block_index = 0;
	FILE* f = nullptr;
	fopen_s(&f, filename, "rb");
	if (!f) return nullptr;
	tap_info_head* list_head = new tap_info_head();
	uint8_t header_block_info[kTapHeaderBlockSize];
	tap_info* last = nullptr;
	while (!feof(f)) {

		// block len
		uint16_t len;
		if (fread(&len, 2, 1, f) != 1) {

			tap_loader_on_file_error(f, "error reading header block size");
			break;
		}
		uint8_t* data = nullptr;
		if (len == kTapHeaderBlockSize) {
			if (!(tap_loader_read_header(f, header_block_info)))
				break;
			tap_header* header = new tap_header();
			memcpy(header, &header_block_info[0], sizeof(tap_header));
			data = (uint8_t*)header;
		}
		else {
			if (!(data = tap_loader_read_data(f, len)))
				break;
			tap_data* tdata = new tap_data();
			tdata->bytes = data;
			tdata->length = (size_t)len; // data plus flag and crc byte
			data = (uint8_t*)tdata;
		}		
		tap_info* info = new tap_info(block_index++);
		info->is_header = (len == kTapHeaderBlockSize);
		info->data = data;
		info->next = nullptr;
		if (last == nullptr) {
			list_head->node = info;
		}
		else
			last->next = info;
		list_head->block_count++;
		last = info;
	}
	fclose(f);
	return list_head;
}

tap_info_head* tap_loader_info_from_file2(const char* filename) {

	size_t block_count = 0;
	size_t block_index = 0;
	size_t total_data_size = 0;
	FILE* f = nullptr;
	fopen_s(&f, filename, "rb");
	if (!f) return nullptr;
	tap_info_head* list_head = new tap_info_head();
	uint8_t header_block_info[kTapHeaderBlockSize];
	while (!feof(f)) {

		// header block
		uint16_t len;
		if (fread(&len, 2, 1, f) != 1) {

			tap_loader_on_file_error(f, "error reading header block size");
			break;
		}

		if (len != kTapHeaderBlockSize) {

			tap_loader_on_file_error(f, "invalid header block size");
			break;
		}
		if (fread(header_block_info, len, 1, f) != 1) {

			tap_loader_on_file_error(f, "error reading header block info");
			break;
		}
		if (header_block_info[0] != kTapHeaderBlockId) {
			
			tap_loader_on_file_error(f, "expected header block");
			break;
		}
		uint16_t data_len = (uint16_t)(header_block_info[12] | (header_block_info[13] << 8));

		// data block
		if (fread(&len, 2, 1, f) != 1) {

			tap_loader_on_file_error(f, "error reading data block size");
			break;
		}

		if (data_len != (len-2)) {
			tap_loader_on_file_error(f, "data length and header length value mismatch");
			break;
		}

		uint8_t data_type_flag;
		if (fread(&data_type_flag, 1, 1, f) != 1) {

			tap_loader_on_file_error(f, "error reading data type flag");
			break;
		}

		if (data_type_flag != kTapDataBlockId) {

			tap_loader_on_file_error(f, "expected data block");
			break;
		}

		uint8_t* data = new uint8_t[data_len + 2]; // data plus flag and crc byte
		data[0] = data_type_flag;
		if (fread(&data[1], data_len, 1, f) != 1) {

			tap_loader_on_file_error(f, "error reading data block");
			delete[] data;
			break;
		}
		uint8_t crc;
		if (fread(&crc, 1, 1, f) != 1) {

			tap_loader_on_file_error(f, "error reading crc of data block");
			delete[] data;
			break;
		}
		data[data_len+1] = crc;

		// data_len + 1 (for crc)
		total_data_size += data_len + 1;

		tap_info* info = new tap_info(block_index++);
		info->data = (uint8_t*)new tap_header();
		tap_header* header = (tap_header*)info->data;
		memcpy(header, &header_block_info[0], sizeof(tap_header));
		info->is_header = true;
		info->next = new tap_info(block_index++);
		
		if (list_head->node == nullptr)
			list_head->node = info;
		else {
			tap_info* current = list_head->node;
			while (current->next != nullptr)
				current = current->next;
			current->next = info;
		}
		block_count += 2;
		info = info->next;
		info->data = (uint8_t*)new tap_data();
		info->is_header = false;
		info->next = nullptr;
		tap_data* tdata = (tap_data*)info->data;
		tdata->bytes = data;
		tdata->length = (size_t)(data_len + 2); // data plus flag and crc byte
	}
//	list_head->data_size = total_data_size;
	list_head->block_count = block_count;
	fclose(f);
	return list_head;
}

void tap_loader_info_free(tap_info_head* tape) {
	if (!tape)
		return;
	tap_info* current = tape->node;
	while (current != nullptr) {
		tap_info* next = current->next;
		if (current->is_header == true) {
			tap_header* header = (tap_header*)current->data;
			if (header)
				delete header;
		}
		else {
			tap_data* data = (tap_data*)current->data;
			if (data) {
				if (data->bytes)
					delete[] data->bytes;
				delete data;
			};
		}
		delete current;
		current = next;
	}
	delete tape;
}

void tap_loader_bytes_from_file(const char* filename, uint8_t** buffer_out, size_t* size_out) {

	size_t file_size = *size_out = 0;
	FILE* f = nullptr;
	fopen_s(&f, filename, "rb");
	if (!f) return;
	fseek(f, 0, SEEK_END);
	file_size = (size_t)ftell(f);
	if (file_size > 0) {
		fseek(f, 0, SEEK_SET);
		uint8_t* mem = new uint8_t[file_size];
		if (fread(mem, 1, file_size, f) == file_size) {
			*size_out = file_size;
			*buffer_out = mem;
		}
		else {
			perror("error reading tap file to bytes");
			delete[] mem;
		}
	}
	fclose(f);
}

void tap_loader_set_fast_mode(bool enable) {

	tap_loader_fast_mode = enable;
}

bool tap_loader_get_fast_mode() {

	return tap_loader_fast_mode;
}