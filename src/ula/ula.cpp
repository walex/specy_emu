#include "ula.h"
#include "z80.h"

void ula_init(uint8_t* system_memory) {

	display_init(system_memory);
}

void ula_read_port(uint16_t addr, uint8_t* value) {

	uint8_t key;
	uint16_t port = addr & 0x00FF;
	switch (port) {
	case 0XFE:
		key = ((addr & 0xFF00) >> 8);
		*value = keyboard_get_map_addr(key);
		*value |= tape_audio_read();
		break;
	default:
		*value = 0x0;
		return;
	}
}

void ula_write_port(uint16_t addr, uint8_t value) {

   // border = value & 0x7;
   // mic = value & 0x8;
   // ear = value & 0x10;

	display_set_border_color(value & 0x7);
}

void ula_assert_INT_line() {

	trigger_MI(0);
}