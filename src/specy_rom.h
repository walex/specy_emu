#ifndef _SPECY_MEM_H_
#define _SPECY_MEM_H_

#include <stdint.h>
const uint16_t SPECY_48K_SYS_VAR_FRAMES = 0x5C78;

uint16_t specy_rom_get_system_var_value(uint16_t system_var_id);
void specy_rom_set_pointer(uint8_t* rom_ptr);

#endif