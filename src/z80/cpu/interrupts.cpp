#include "interrupts.h"
#include "z80.h"
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
	void interrupts_request_mi(uint8_t bus_value);
#ifdef __cplusplus
}
#endif

static uint64_t interrupt_request_cycle_start = 0;
void interrupts_request_mi_c(uint8_t bus_value) {

    interrupts_request_mi(bus_value);
	interrupt_request_cycle_start = cpu_get_cycles();
}