#ifndef _Z80_H_

#define _Z80_H_

#include <stdint.h>

constexpr double Z80_CPU_FREQ_MHZ = 3.5;
constexpr uint64_t Z80_CPU_FREQ_HZ = (uint64_t)(Z80_CPU_FREQ_MHZ * 1000000);
constexpr uint32_t CPU_REGISTER_AF = 0;
constexpr uint32_t CPU_REGISTER_AF_ = 1;
constexpr uint32_t CPU_REGISTER_BC = 2;
constexpr uint32_t CPU_REGISTER_BC_ = 3;
constexpr uint32_t CPU_REGISTER_DE = 4;
constexpr uint32_t CPU_REGISTER_DE_ = 5;
constexpr uint32_t CPU_REGISTER_HL = 6;
constexpr uint32_t CPU_REGISTER_HL_ = 7;
constexpr uint32_t CPU_REGISTER_IX = 8;
constexpr uint32_t CPU_REGISTER_IY = 9;
constexpr uint32_t CPU_REGISTER_SP = 10;
constexpr uint32_t CPU_REGISTER_I = 11;
constexpr uint32_t CPU_REGISTER_R = 12;
constexpr uint32_t CPU_REGISTER_PC = 13;

typedef void(*clock_call_interceptor_handler)();

#ifdef __cplusplus
extern "C" {
#endif
	void cpu_z80_init(uint8_t* memPtr, uint8_t force_retn=0);
	void cpu_z80_step();
	void GetRegPC(uint64_t memPtr, uint16_t* value);
	void cpu_set_wait_state(uint64_t cycles);
	void cpu_unset_wait_state();
	bool cpu_get_wait_state();
	void cpu_sync(uint8_t cycles);
	uint64_t cpu_get_cycles();
	void cpu_set_cycles(uint64_t cycles);
	void cpu_call_opcode_interceptor(uint16_t addr, clock_call_interceptor_handler handler);
	void cpu_call_opcode_notify(uint16_t addr);
	uint16_t cpu_get_pc(uint64_t base_addr);
	void cpu_set_register16(uint8_t reg_id, uint16_t value);
	void cpu_set_register8(uint8_t reg_id, uint8_t value);
	void cpu_set_interrupt_mode(uint8_t mode);

#ifdef __cplusplus
	}
#else
#endif

#include "interrupts.h"

#endif
