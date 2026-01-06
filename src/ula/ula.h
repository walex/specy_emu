#ifndef _ULA_HPP_
#define _ULA_HPP_

#include "keyboard.h"
#include "clk_master.h"
#include "display.h"
#include "tape_audio.h"

void ula_init(uint8_t* system_memory);
void ula_assert_INT_line();

#ifdef __cplusplus
extern "C" {
#endif
	void __stdcall ula_read_port(uint16_t addr, uint8_t* value);
	void __stdcall ula_write_port(uint16_t addr, uint8_t value);
#ifdef __cplusplus
}
#endif

#endif