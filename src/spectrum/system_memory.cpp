#include "system_memory.h"
#include "z80.h"
#include "ula.h"
#include "memory_paging.h"

// intercept calls functions
static constexpr uint16_t LD_BYTES = 0x0556;

struct machine_info {
	const char* rom_name;
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
static int32_t system_machine_id = UNKNOWN_SYSTEM;

size_t system_memory_load_rom(uint8_t* mem, const char* base_path, const char* rom_name) {

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

uint8_t* system_memory_create_48k_rom(const char* base_path, machine_info& machine_info, size_t mem_size) {

	uint8_t* mem = new uint8_t[mem_size];
	if (mem == nullptr) {
		perror("48k RAM memory error");
		return nullptr;
	}
	memset(mem, 0, mem_size);
	system_memory_load_rom(mem, base_path, machine_info.rom_name);
	return mem;
}

uint8_t* system_memory_create_128k_rom(const char* base_path, machine_info& machine_info, size_t mem_size) {
	uint8_t* mem = memory_paging_init();
	if (mem == nullptr) {
		perror("128k RAM memory error");
		return nullptr;
	}
	if (!system_memory_load_rom(mem, base_path, machine_info.rom_name)) {
		memory_paging_end();
		perror("128k rom load error");
		return nullptr;
	}
	uint8_t* rom_48k = system_memory_create_48k_rom(base_path, machine_info, mem_size);
	size_t rom_size = system_memory_load_rom(rom_48k, base_path, SPECTRUM_48K_ROM_FILE);
	if (!rom_size) {
		return nullptr;
	}
	memory_paging_copy_mem_to_bank(rom_48k, BANK_ROM_1_INDEX, BANK_SIZE);
	delete[] rom_48k;
	return mem;
}

uint8_t* system_memory_create(uint32_t machine_id, const char* base_path) {

	auto it = machines.find(machine_id);
	machine_info& machine_info = it->second;
	size_t mem_size = machine_info.rom_size + machine_info.ram_size;
	uint8_t* mem = nullptr;
	switch (machine_id) {
	case SPECTRUM_128K_SYSTEM:
		mem = system_memory_create_128k_rom(base_path, machine_info, mem_size);
		break;
	default:
		mem = system_memory_create_48k_rom(base_path, machine_info, mem_size);
		break;
	}		
	return mem;
}

void system_memory_free() {
	if (system_rom_pointer)
		memory_paging_end();
}

void system_memory_on_rom_call_LD_BYTES() {
	ula_on_tape_load_block();
}

int system_memory_init(uint32_t machine_id, const char* base_path) {

	if (machine_id == UNKNOWN_SYSTEM)
		machine_id = SPECTRUM_48K_SYSTEM;
	system_rom_pointer = system_memory_create(machine_id, base_path);
	if (!system_rom_pointer) {
		perror("cannot load rom file");
		return -1;
	}
	
	cpu_call_opcode_interceptor(LD_BYTES, system_memory_on_rom_call_LD_BYTES);
	system_machine_id = machine_id;
	return 0;
}

void system_memory_end() {
	system_memory_free();	
}

uint32_t system_memory_get_machine_id() {
	return system_machine_id;
}

uint8_t* system_memory_get_pointer(uint64_t offset) {
	return system_rom_pointer + offset;
}

uint16_t system_memory_get_system_var_value_16(uint16_t system_var_id) {

	return *(uint16_t*)(system_rom_pointer + system_var_id);
}

uint8_t system_memory_get_system_var_value_8(uint16_t system_var_id) {

	return *(uint8_t*)(system_rom_pointer + system_var_id);
}

void system_memory_set_system_var_value_8(uint16_t system_var_id, uint8_t value) {

	*(uint8_t*)(system_rom_pointer + system_var_id) = value;
}