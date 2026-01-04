#include "specy_rom.h"

static unsigned char* system_rom_pointer = NULL;

void specy_rom_set_pointer(unsigned char* rom_ptr) {
	system_rom_pointer = rom_ptr;
}

uint16_t specy_rom_get_system_var_value(uint16_t system_var_id) {

	return *(uint16_t*)(system_rom_pointer + system_var_id);
}