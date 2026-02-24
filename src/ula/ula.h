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
	void ula_write_port_FE(uint16_t addr, uint8_t value);
	void ula_on_load_edge_1();
#ifdef __cplusplus
}
#endif

constexpr uint64_t kULASyncCycles = 69888;
constexpr uint64_t CONTAINED_MEMORY_LOW_48k = 0x4000;
constexpr uint64_t CONTAINED_MEMORY_HIGH_48k = 0x7fff;
constexpr uint64_t DELAY_PATTERN_48k[] = { 6, 5, 4, 3, 2, 1, 0, 0 };
constexpr size_t DELAY_PATTERN_48k_SIZE = sizeof(DELAY_PATTERN_48k) / sizeof(DELAY_PATTERN_48k[0]);
constexpr uint64_t CONTAINED_MEMORY_CYCLE_START_48K = 14335;
constexpr uint64_t CONTAINED_MEMORY_CYCLE_END_48K = 14463;

#endif