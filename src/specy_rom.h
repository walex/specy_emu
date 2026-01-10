#ifndef _SPECY_MEM_H_
#define _SPECY_MEM_H_

#include <stdint.h>
const uint16_t SPECY_48K_SYS_VAR_FRAMES = 0x5C78;

int specy_rom_init(const char* rom_path, size_t memory_size);
void specy_rom_end();
uint8_t* specy_rom_get_pointer();
uint16_t specy_rom_get_system_var_value(uint16_t system_var_id);

#endif