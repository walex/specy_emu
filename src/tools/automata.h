#ifndef _AUTOMATA_H_
#define _AUTOMATA_H_

#include "platform.h"

void automata_measure_port_accel(uint64_t delta_tstates, uint64_t total_states);
bool automata_play_tape();
bool automata_stop_tape();
bool automata_play_tape_idle(uint64_t total_cycles);
#endif