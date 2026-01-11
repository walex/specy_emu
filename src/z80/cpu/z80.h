#ifndef _Z80_H_

#define _Z80_H_

#include <stdint.h>

constexpr double Z80_CPU_FREQ_MHZ = 3.5;
constexpr uint64_t Z80_CPU_FREQ_HZ = (uint64_t)(Z80_CPU_FREQ_MHZ * 1000000);

typedef void(*clock_call_interceptor_handler)();

#ifdef __cplusplus
extern "C" {
#endif
	int __stdcall Z80CPU(uint8_t*, uint8_t* pc);
	void __stdcall trigger_MI(uint8_t bus_data);
	void __stdcall cpu_lock();
	void __stdcall cpu_unlock();
	void __stdcall cpu_wait();
	void __stdcall cpu_sync(uint8_t cycles);
	uint64_t __stdcall cpu_get_cycles();
	void __stdcall cpu_call_opcode_interceptor(uint16_t addr, clock_call_interceptor_handler handler);
	void __stdcall cpu_call_opcode_notify(uint16_t addr);
#ifdef __cplusplus
	}
#else
#endif

#define Z80_EMULATION_SYNC_CYCLES_DELAY 0 // seconds to wait before syncing CPU cycles to real time

#endif