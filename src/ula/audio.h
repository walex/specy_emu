#ifndef _AUDIO_HPP_
#define _AUDIO_HPP_

#include <stdint.h>

void audio_init();
void audio_end();
// Avanza el reloj de audio (SIEMPRE)
void audio_tick(uint64_t delta_tstates);

// Cambia el nivel del beeper (solo en OUT #FE)
void audio_set_level(uint64_t total_cycles, uint8_t value);

#endif