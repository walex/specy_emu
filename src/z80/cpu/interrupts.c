#include "interrupts.h"
#include "z80.h"

extern void interrupts_request_mi(uint8_t bus_value);

void interrupts_request_mi_c(uint8_t bus_value) {

    interrupts_request_mi(bus_value);
}