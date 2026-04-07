#ifndef _SPECY_MEM_H_
#define _SPECY_MEM_H_

#include "platform.h"

#define MAX_ROM_NAME_SIZE 256
#define SPECTRUM_48K_ROM_FILE "spec_48.rom"
#define SPECTRUM_128K_ROM_FILE "spec_128.rom"
#define TK95_48K_ROM_FILE "TK95.Spanish.rom"
#define TK90X_48K_ROM_FILE "TK90X.v1.Spanish.rom"
#define TK90X_48K_ROM_V3_FILE "TK90X_v3EN.rom"

constexpr uint32_t kSystemUnknown = 0xFFFFFFFF;
constexpr uint32_t kSystemTK90X = 0;
constexpr uint32_t kSystemTK95 = 1;
constexpr uint32_t kSystemSinclairSpectrum48 = 2;
constexpr uint32_t kSystemSinclairSpectrum128 = 3;
constexpr uint32_t kSystemMin = kSystemTK90X;
constexpr uint32_t kSystemMax = kSystemSinclairSpectrum128;

constexpr uint16_t kFRAMES = 0x5C78;
constexpr uint16_t kMODE = 0x5C41;
constexpr uint16_t kPROG = 0x5C53;
constexpr uint16_t kLD_BYTES = 0x0556;

constexpr size_t kROMSize = 16 * 1024;
constexpr size_t kRAMSize48 = 48 * 1024;
constexpr size_t kRAMSize128 = 128 * 1024;

int system_memory_init(uint32_t machine_id, const char* base_path);
void system_memory_end();
void system_memory_configure_hooks();
extern "C" {
	uint8_t* system_memory_get_pointer(uint64_t offset = 0);
}
size_t system_memory_load_rom(uint8_t* mem, const char* base_path, const char* rom_name);
uint8_t system_memory_get_system_var_value_8(uint16_t system_var_id);
uint16_t system_memory_get_system_var_value_16(uint16_t system_var_id);
void system_memory_set_system_var_value_8(uint16_t system_var_id, uint8_t value);
uint32_t system_memory_get_machine_id();

#endif