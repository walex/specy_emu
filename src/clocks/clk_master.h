#ifndef _CLK_MASTER_H_
#define _CLK_MASTER_H_

#include <stdint.h>
typedef void*  clock_master_handle;
typedef void (*clock_master_callback_function)(void);

#ifdef __cplusplus
extern "C" {
#endif

	clock_master_handle clk_master_create(const char* name, double frequency_hz);
	void clk_master_destroy(clock_master_handle cm);
	void clk_master_tick(clock_master_handle cmh, clock_master_callback_function cb);
	clock_master_handle clk_master_get(const char* name);
	void clk_master_wait(clock_master_handle cmh);
	double clk_master_get_frequency(clock_master_handle cmh);
#ifdef __cplusplus
}
#endif

#endif