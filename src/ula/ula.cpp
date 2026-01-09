#include "ula.h"
#include "tap_loader.h"
#include "z80.h"
#include "keyboard.h"
#include "display.h"
#include "audio.h"

static uint8_t* tape_data = nullptr;
static size_t tape_data_size = 0;

void ula_init(uint8_t* system_memory) {

	display_init(system_memory);
	audio_init();
}

int first_time = 0;
void ula_read_port(uint16_t addr, uint8_t* value) {

	uint8_t key;
	uint16_t port = addr & 0x00FF;
	switch (port) {
	case 0XFE: {
		key = ((addr & 0xFF00) >> 8);
		*value = keyboard_get_map_addr(key);
		if (key == 127)
			first_time++;
		else
			first_time = 0;
		if (first_time > 2)
			*value |= ula_read_next_tap_pulse();
	}break;
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
	audio_play(cpu_get_cycles(), value & 0x18);
}

void ula_assert_INT_line() {

	trigger_MI(0);
}

uint16_t next_pulse_mask = 0x80;
uint8_t* next_byte_ptr = nullptr;
uint32_t pulse_length_counter = 0;

void ula_set_tape_bytes(const uint8_t* const data, const size_t size) {

	if (size > 0 && data != nullptr) {
		next_byte_ptr = tape_data = const_cast<uint8_t*>(data);
		tape_data_size = size;
	}
}
uint32_t pilot_count = 8063; // 8063 para carga normal, 3223 para carga rapida
uint8_t pilot_pulse = 0;
uint8_t sync_pulse[] = { 0,1,0,0,1,1 };
uint32_t sync_pulse_index = 0;

uint8_t ula_read_next_tap_pulse() {

	if (pilot_count > 0) {
		pilot_count--;
		uint8_t pilot_pulse_ant = pilot_pulse;
		pilot_pulse ^= (1<<6);
		return pilot_pulse_ant; // HIGH
	}
	if (sync_pulse_index < 6) {

		return sync_pulse[sync_pulse_index++];
	}
	static const uint32_t pulse_edge_bit_1[] = { 0,1,1,0 };
	static const uint32_t pulse_edge_bit_0[] = { 0,1,0 };
	/*
	bit 1: LOW -> HIGH -> HIGH -> LOW
	bit 0: LOW -> HIGH -> LOW
	*/
	if (next_byte_ptr!= nullptr && next_byte_ptr < (tape_data+tape_data_size)) {
		
		if (*next_byte_ptr & next_pulse_mask) { // bit 1

			if (pulse_length_counter == 4) {
				pulse_length_counter = 0;
				next_pulse_mask = 0x80;
				next_byte_ptr++;
				return ula_read_next_tap_pulse();
			}
			else {
				return pulse_edge_bit_1[pulse_length_counter++] << 6;
			}
		}
		else { // bit 0
			if (pulse_length_counter == 3) {
				pulse_length_counter = 0;
				next_pulse_mask = 0x80;
				next_byte_ptr++;
				return ula_read_next_tap_pulse();
			}
			else {
				return pulse_edge_bit_0[pulse_length_counter++] << 6;
			}
		}		
	}
	else {
		next_byte_ptr = nullptr;
	}
	return 0;
}