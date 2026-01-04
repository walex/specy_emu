#ifndef _Z80_H_

#define _Z80_H_

const double Z80_CPU_FREQ_MHZ = 3.5;

#ifdef __cplusplus
extern "C" {
#endif
	int __stdcall Z80CPU(unsigned char*, unsigned char* pc);
	void __stdcall trigger_MI();
#ifdef __cplusplus
	}
#endif

#endif