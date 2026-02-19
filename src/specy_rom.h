#ifndef _SPECY_MEM_H_
#define _SPECY_MEM_H_

#include <stdint.h>

const uint32_t TK90X_SYSTEM = 0;
const uint32_t TK95_SYSTEM = 1;
const uint32_t SPECTRUM_48K_SYSTEM = 2;
const uint32_t SPECTRUM_128K_SYSTEM = 3;

const uint16_t SPECY_48K_SYS_VAR_FRAMES = 0x5C78;

int specy_rom_init(uint32_t machine_id, const char* base_path);
void specy_rom_end();
uint8_t* specy_rom_get_pointer();
uint16_t specy_rom_get_system_var_value(uint16_t system_var_id);

#endif