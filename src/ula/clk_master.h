#ifndef _CLK_MASTER_H_
#define _CLK_MASTER_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

	void clk_master_start();
	void clk_master_stop();
	void clk_master_reset();
	void clk_master_wait();
	void clk_master_sync(uint8_t t_states, uint8_t cycles);

#ifdef __cplusplus
}
#endif

#endif