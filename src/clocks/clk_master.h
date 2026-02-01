#ifndef _CLK_MASTER_H_
#define _CLK_MASTER_H_

#include <stdint.h>
#include <functional>
typedef void*  clock_master_handle;
using clock_master_clicks_callback_function = std::function<void(uint64_t)>;

#ifdef __cplusplus
extern "C" {
#endif

	clock_master_handle clk_master_create(const char* name, double frequency_hz);
	void clk_master_destroy(clock_master_handle cm);
	void clk_master_sync(clock_master_handle cmh, uint64_t cycles, uint64_t delta_cycles);
	clock_master_handle clk_master_get(const char* name);
	double clk_master_get_frequency(clock_master_handle cmh);
	uint64_t clk_master_get_cycles(clock_master_handle cmh);
	void clk_master_tick(clock_master_handle cmh, uint64_t cycles);
	void clk_master_subscribe_sync_callback(clock_master_handle cmh, clock_master_clicks_callback_function cb);
#ifdef __cplusplus
}
#endif

#endif