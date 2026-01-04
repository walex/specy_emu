#ifndef _ULA_HPP_
#define _ULA_HPP_

#include "keyboard.h"
#include "clk_master.h"
#include "display.h"

void ula_init(unsigned char* system_memory);
void ula_assert_INT_line();

#ifdef __cplusplus
extern "C" {
#endif
	void __stdcall ula_read_port(unsigned short int addr, unsigned char* value);
	void __stdcall ula_write_port(unsigned short int addr, unsigned char value);
#ifdef __cplusplus
}
#endif

#endif