#ifndef _SPECY_MEM_H_
#define _SPECY_MEM_H_

#include <stdint.h>

constexpr uint32_t UNKNOWN_SYSTEM = 0xFFFFFFFF;
constexpr uint32_t TK90X_SYSTEM = 0;
constexpr uint32_t TK95_SYSTEM = 1;
constexpr uint32_t SPECTRUM_48K_SYSTEM = 2;
constexpr uint32_t SPECTRUM_128K_SYSTEM = 3;

constexpr uint16_t SPECY_48K_SYS_VAR_FRAMES = 0x5C78;
constexpr uint16_t SPECY_48K_SYS_VAR_MODE = 0x5C41;

constexpr size_t MAX_ROM_NAME_SIZE = 256;

constexpr char SPECTRUM_48K_ROM_FILE[MAX_ROM_NAME_SIZE] = "spec_48.rom";
constexpr char SPECTRUM_128K_ROM_FILE[MAX_ROM_NAME_SIZE] = "spec_128.rom";
constexpr char TK95_48K_ROM_FILE[MAX_ROM_NAME_SIZE] = "TK95.Spanish.rom";
constexpr char TK90X_48K_ROM_FILE[MAX_ROM_NAME_SIZE] = "TK90X.v1.Spanish.rom";
constexpr char TK90X_48K_ROM_V3_FILE[MAX_ROM_NAME_SIZE] = "TK90X_v3EN.rom";

constexpr size_t ROM_48K_SIZE = 16 * 1024;
constexpr size_t ROM_16K_SIZE = 16 * 1024;
constexpr size_t ROM_128K_SIZE = 16 * 1024;
constexpr size_t RAM_48K_SIZE = 48 * 1024;
constexpr size_t RAM_128K_SIZE = 128 * 1024;

int system_memory_init(uint32_t machine_id, const char* base_path);
void system_memory_end();
extern "C" {
	uint8_t* system_memory_get_pointer(uint64_t offset = 0);
}
size_t system_memory_load_rom(uint8_t* mem, const char* base_path, const char* rom_name);
uint8_t system_memory_get_system_var_value_8(uint16_t system_var_id);
uint16_t system_memory_get_system_var_value_16(uint16_t system_var_id);
void system_memory_set_system_var_value_8(uint16_t system_var_id, uint8_t value);
#endif