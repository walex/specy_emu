#include "ula.h"
#include "z80.h"

void ula_init(unsigned char* system_memory) {

	clk_master_start();
	display_init(system_memory);
}

void ula_read_port(unsigned short int addr, unsigned char* value) {

	unsigned char key;
	switch (addr) {
	case 0xFEFE:
	case 0xFDFE:
	case 0xFBFE:
	case 0xF7FE:
	case 0xEFFE:
	case 0xDFFE:
	case 0xBFFE:
	case 0x7FFE:
		key = ((addr & 0xFF00) >> 8);
		*value = keyboard_get_map_addr(key);
		break;
	default:
		*value = 0;
		break;
	}
}

void ula_write_port(unsigned short int addr, unsigned char value) {

   // border = value & 0x7;
   // mic = value & 0x8;
   // ear = value & 0x10;

	display_set_border_color(value & 0x7);
}

void ula_assert_INT_line() {

	trigger_MI();
}