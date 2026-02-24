#ifndef _SPECY_MEM_H_
#define _SPECY_MEM_H_

#include <stdint.h>

const uint32_t UNKNOWN_SYSTEM = 0xFFFFFFFF;
const uint32_t TK90X_SYSTEM = 0;
const uint32_t TK95_SYSTEM = 1;
const uint32_t SPECTRUM_48K_SYSTEM = 2;
const uint32_t SPECTRUM_128K_SYSTEM = 3;

const uint16_t SPECY_48K_SYS_VAR_FRAMES = 0x5C78;
const uint16_t SPECY_48K_SYS_VAR_MODE = 0x5C41;

int system_memory_init(uint32_t machine_id, const char* base_path);
void system_memory_end();
extern "C" {
	uint8_t* system_memory_get_pointer();
}
uint8_t system_memory_get_system_var_value_8(uint16_t system_var_id);
uint16_t system_memory_get_system_var_value_16(uint16_t system_var_id);
void system_memory_set_system_var_value_8(uint16_t system_var_id, uint8_t value);
#endif