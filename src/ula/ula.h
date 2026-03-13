#ifndef _ULA_HPP_
#define _ULA_HPP_

#ifdef __cplusplus

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
void ula_on_tape_load_block();
void ula_on_tape_load_block_from_info();

constexpr uint64_t kULASyncCycles = 69888;
constexpr uint64_t kContainedMemory48LowAddr = 0x4000;
constexpr uint64_t kContainedMemory48HighAddr = 0x7fff;
constexpr uint64_t kContainedMemory48DelayPattern[] = { 6, 5, 4, 3, 2, 1, 0, 0 };
constexpr size_t kContainedMemory48DelayPatternSize = sizeof(kContainedMemory48DelayPattern) / sizeof(kContainedMemory48DelayPattern[0]);
constexpr uint64_t kContainedMemory48CycleStart = 14335;
constexpr uint64_t kContainedMemory48CycleEnd = 14463;

#else
#include <stdint.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif
	void ula_read_port(uint16_t addr, uint8_t* value);
	void ula_write_port(uint16_t addr, uint8_t value);
#ifdef __cplusplus
}
#endif

#endif