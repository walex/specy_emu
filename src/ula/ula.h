#ifndef _ULA_HPP_
#define _ULA_HPP_

#include "clk_master.h"
#include <stdint.h>

void ula_init(uint8_t* system_memory);
void ula_assert_INT_line();

#ifdef __cplusplus
extern "C" {
#endif
	void ula_read_port(uint16_t addr, uint8_t* value);
	void ula_write_port(uint16_t addr, uint8_t value);
	void ula_on_audio_listen();
#ifdef __cplusplus
}
#endif

#endif