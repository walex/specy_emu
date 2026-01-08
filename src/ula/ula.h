#ifndef _ULA_HPP_
#define _ULA_HPP_

#include "keyboard.h"
#include "clk_master.h"
#include "display.h"
#include "tape_audio.h"

struct tap_info;
void ula_init(uint8_t* system_memory);
void ula_assert_INT_line();

#ifdef __cplusplus
extern "C" {
#endif
	void __stdcall ula_read_port(uint16_t addr, uint8_t* value);
	void __stdcall ula_write_port(uint16_t addr, uint8_t value);
	uint8_t __stdcall ula_read_next_tap_pulse();
	void __stdcall ula_set_tape_bytes(const uint8_t* const data, const size_t size);
#ifdef __cplusplus
}
#endif

#endif