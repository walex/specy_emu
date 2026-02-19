#include "specy_rom.h"
#include "z80.h"
#include "ula.h"
#include "memory_paging.h"
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <map>
#include <filesystem>

// intercept calls functions
#define SPECTRUM_48K_ROM_FILE  "spec_48.rom"
#define SPECTRUM_128K_ROM_FILE "spec_128.rom"
#define TK95_48K_ROM_FILE "TK95.Spanish.rom"
#define TK90X_48K_ROM_FILE "TK90X.v1.Spanish.rom"
#define TK90X_48K_ROM_V3_FILE "TK90X_v3EN.rom"
static constexpr uint16_t LD_BYTES = 0x0556;
static constexpr uint16_t LD_EDGE_1 = 0x05E7;
static constexpr size_t ROM_NAME_SIZE = 32;
static constexpr size_t ROM_48K_SIZE = 16 * 1024;
static constexpr size_t ROM_16K_SIZE = 16 * 1024;
static constexpr size_t ROM_128K_SIZE = 16 * 1024;
static constexpr size_t RAM_48K_SIZE = 48 * 1024;
static constexpr size_t RAM_128K_SIZE = 128 * 1024;

struct machine_info {
	char rom_name[ROM_NAME_SIZE];
	size_t rom_size;
	size_t ram_size;
};

std::map<uint32_t, machine_info> machines = {
	{SPECTRUM_48K_SYSTEM, {SPECTRUM_48K_ROM_FILE, ROM_48K_SIZE, RAM_48K_SIZE}},
	{SPECTRUM_128K_SYSTEM, {SPECTRUM_128K_ROM_FILE, ROM_128K_SIZE, RAM_128K_SIZE}},
	{TK95_SYSTEM, {TK95_48K_ROM_FILE, ROM_48K_SIZE, RAM_48K_SIZE}},
	{TK90X_SYSTEM, {TK90X_48K_ROM_V3_FILE, ROM_48K_SIZE, RAM_48K_SIZE}}

};

static uint8_t* system_rom_pointer = nullptr;

size_t specy_rom_load(uint8_t* mem, const char* base_path, const char* rom_name) {

	std::filesystem::path rom_path(base_path);
	rom_path = rom_path.append(rom_name);
	FILE* rom = nullptr;
	fopen_s(&rom, rom_path.string().c_str(), "rb");
	if (rom == nullptr) {
		perror("Error opening file");
		return 0;
	}

	fseek(rom, 0, SEEK_END); // Move the file pointer to the end
	size_t rom_size = ftell(rom);
	fseek(rom, 0, SEEK_SET);
	fread(mem, rom_size, 1, rom);
	fclose(rom);

	return rom_size;
}

uint8_t* specy_rom_create_system_memory(uint32_t machine_id, const char* base_path) {

	auto it = machines.find(machine_id);
	machine_info& machine_info = it->second;
	size_t mem_size = machine_info.rom_size + machine_info.ram_size;
	uint8_t* mem = memory_paging_init();
	if (mem == nullptr) {
		perror("RAM memory error");
		return nullptr;
	}
	specy_rom_load(mem, base_path, machine_info.rom_name);
	if (machine_id == SPECTRUM_128K_SYSTEM) {

		uint8_t* rom_48k = new uint8_t[ROM_48K_SIZE];
		size_t rom_size = specy_rom_load(rom_48k, base_path, SPECTRUM_48K_ROM_FILE);
		memory_paging_copy_mem_to_bank(rom_48k, BANK_ROM_1_INDEX, rom_size);
		delete[] rom_48k;
	}
	return mem;
}

void specy_rom_free_system_memory() {
	if (system_rom_pointer)
		memory_paging_end(system_rom_pointer);
}

void specy_rom_on_call_LD_EDGE_1() {
	ula_on_load_edge_1();
}

int specy_rom_init(uint32_t machine_id, const char* base_path) {
	system_rom_pointer = specy_rom_create_system_memory(machine_id, base_path);
	if (!system_rom_pointer) {
		perror("cannot load rom file");
		return -1;
	}
	
	cpu_call_opcode_interceptor(LD_EDGE_1, specy_rom_on_call_LD_EDGE_1);
	return 0;
}

void specy_rom_end() {

	specy_rom_free_system_memory();
	
}

uint8_t* specy_rom_get_pointer() {
	return system_rom_pointer;
}

uint16_t specy_rom_get_system_var_value(uint16_t system_var_id) {

	return *(uint16_t*)(system_rom_pointer + system_var_id);
}