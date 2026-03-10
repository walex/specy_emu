#ifndef _ULA_HPP_
#define _ULA_HPP_

#include "platform.h"
#include "keyboard.h"

struct Ula_Callbacks {
	
	UlaKeyboardKeysCallback ulaKeyboardKeysCallback;
};

void ula_init(uint8_t* system_memory, Ula_Callbacks* callbacks = nullptr);
bool ula_is_running();
void ula_end();
void ula_assert_INT_line();
bool ula_has_snow_effect();

#ifdef __cplusplus
extern "C" {
#endif
	void ula_read_port(uint16_t addr, uint8_t* value);
	void ula_write_port_FE(uint8_t value);
	void ula_on_tape_load_block();
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