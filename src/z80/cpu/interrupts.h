#ifndef _INTERRUPTS_H_
#define _INTERRUPTS_H_
#include <stdint.h>
#ifdef __cplusplus
extern "C" {
#endif
void interrupts_request_mi_c(uint8_t bus_value);
#ifdef __cplusplus
}
#endif
#endif // !_INTERRUPTS_H_
