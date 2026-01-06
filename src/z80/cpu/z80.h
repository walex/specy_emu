#ifndef _Z80_H_

#define _Z80_H_

#include <stdint.h>

const double Z80_CPU_FREQ_MHZ = 3.5;
const uint64_t Z80_CPU_FREQ_HZ = (uint64_t)(Z80_CPU_FREQ_MHZ * 1000000);

#ifdef __cplusplus
extern "C" {
#endif
	int __stdcall Z80CPU(uint8_t*, uint8_t* pc);
	void __stdcall trigger_MI(uint8_t bus_data);
#ifdef __cplusplus
	}
#endif

#endif