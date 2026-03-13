#ifndef _CLK_MASTER_H_
#define _CLK_MASTER_H_

typedef void* clock_master_handle;

#ifdef __cplusplus
#include "platform.h"
using clock_master_clicks_callback_function = std::function<void(uint64_t)>;
extern "C" {
	clock_master_handle clk_master_create(const char* name, double frequency_hz);
	void clk_master_destroy(clock_master_handle cm);
	double clk_master_get_frequency(clock_master_handle cmh);
	uint64_t clk_master_get_cycles(clock_master_handle cmh);
	void clk_master_tick(clock_master_handle cmh, uint64_t cycles);
	void clk_master_subscribe_sync_callback(clock_master_handle cmh, clock_master_clicks_callback_function cb);
	void clk_master_switch_mode(bool cpu_speed_mode);
}
#endif

#ifdef __cplusplus
extern "C" {
#else
#include <stdint.h>
#endif
	clock_master_handle clk_master_get(const char* name);
	void clk_master_sync(clock_master_handle cmh, uint64_t cycles, uint64_t delta_cycles);
#ifdef __cplusplus
}
#endif

#endif