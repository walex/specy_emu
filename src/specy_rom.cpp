#include "specy_rom.h"
#include "z80.h"
#include "ula.h"
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>

// intercept calls functions
static constexpr uint16_t LD_BYTES = 0x0556;

static uint8_t* system_rom_pointer = nullptr;

uint8_t* create_system_memory(const char* rom_path, size_t mem_size) {

	FILE* rom = nullptr;
	fopen_s(&rom, rom_path, "rb");
	if (rom == nullptr) {
		perror("Error opening file");
		return nullptr;
	}

	fseek(rom, 0, SEEK_END); // Move the file pointer to the end
	size_t rom_size = ftell(rom);
	fseek(rom, 0, SEEK_SET);

	uint8_t* mem = (uint8_t*)malloc(mem_size);
	if (mem == nullptr) {

		perror("RAM memory error");
		fclose(rom);
		return nullptr;
	}
	memset(mem, 0, mem_size);
	fread(mem, rom_size, 1, rom);
	fclose(rom);

	return mem;
}

void specy_rom_on_call_LD_BYTES() {	
	ula_on_audio_listen();
}

int specy_rom_init(const char* rom_path, size_t memory_size) {
	system_rom_pointer = create_system_memory(rom_path, memory_size);
	if (!system_rom_pointer) {
		perror("cannot load rom file");
		return -1;
	}
	cpu_call_opcode_interceptor(LD_BYTES, specy_rom_on_call_LD_BYTES);
}

void specy_rom_end() {

	if (system_rom_pointer)
		free(system_rom_pointer);
}

uint8_t* specy_rom_get_pointer() {
	return system_rom_pointer;
}

uint16_t specy_rom_get_system_var_value(uint16_t system_var_id) {

	return *(uint16_t*)(system_rom_pointer + system_var_id);
}