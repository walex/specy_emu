#ifndef _Z80_H_

#define _Z80_H_

#include "interrupts.h"

#define Z80_CPU_FREQ_MHZ 3.5
#define Z80_CPU_FREQ_HZ (uint64_t)(Z80_CPU_FREQ_MHZ * 1000000)
#define CPU_REGISTER_AF 0
#define CPU_REGISTER_AF_ 1
#define CPU_REGISTER_BC  2
#define CPU_REGISTER_BC_ 3
#define CPU_REGISTER_DE  4
#define CPU_REGISTER_DE_ 5
#define CPU_REGISTER_HL 6
#define CPU_REGISTER_HL_ 7
#define CPU_REGISTER_IX 8
#define CPU_REGISTER_IY 9
#define CPU_REGISTER_SP 10
#define CPU_REGISTER_I 11
#define CPU_REGISTER_R 12
#define CPU_REGISTER_IFF2 13
#define CPU_REGISTER_PC 14

#define RET_OPCODE 0x00C9

typedef void(*clock_call_interceptor_handler)(void);

#ifdef __cplusplus
extern "C" {
#endif
	void cpu_init(uint8_t* memPtr);
	void cpu_end();
	extern void cpu_z80_step(uint8_t force_retn);
	extern void cpu_force_next_opcode(uint16_t opcode);
	void cpu_set_wait_state(uint64_t cycles);
	void cpu_sync(uint8_t cycles);
	uint64_t cpu_get_cycles(void);
	void cpu_set_cycles(uint64_t cycles);
	void cpu_set_call_interceptor(uint16_t addr, clock_call_interceptor_handler handler);
	void cpu_on_call_interceptor(uint16_t addr);
	void cpu_set_register16(uint8_t reg_id, uint16_t value);
	void cpu_set_register8(uint8_t reg_id, uint8_t value);
	void cpu_set_interrupt_mode(uint8_t mode);
	uint16_t cpu_get_register16(uint8_t reg_id);
	uint8_t cpu_get_register8(uint8_t reg_id);
	uint8_t cpu_get_interrupt_mode(void);
#ifdef __cplusplus
	}
#endif

#endif
