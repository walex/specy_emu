#include "specy_rom.h"
#include "z80.h"
#include "ula.h"

// intercept calls functions
static constexpr uint16_t LD_BYTES = 0x0556;

static uint8_t* system_rom_pointer = NULL;

void specy_rom_on_call_LD_BYTES() {
	
	ula_on_audio_listen();
}

void specy_rom_init(uint8_t* rom_ptr) {
	system_rom_pointer = rom_ptr;
	cpu_add_call_interceptor(LD_BYTES, specy_rom_on_call_LD_BYTES);
}

void specy_rom_set_pointer(uint8_t* rom_ptr) {
	system_rom_pointer = rom_ptr;
}

uint16_t specy_rom_get_system_var_value(uint16_t system_var_id) {

	return *(uint16_t*)(system_rom_pointer + system_var_id);
}