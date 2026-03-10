#include "automata.h"
#include "z80.h"

bool automata_port_is_waiting_for_tone(uint64_t delta_tstates) {

	constexpr int TONE_CHECK_MAX_TIMES = 5;
	constexpr uint64_t TONE_CHECK_MIN_RANGE = 70;
	constexpr uint64_t TONE_CHECK_MAX_RANGE = 75;
	constexpr uint64_t TONE_CHECK_CYCLE_INTERVAL = Z80_CPU_FREQ_HZ / 10;
	static uint64_t port_calls = 0;
	static uint64_t port_calls_cycles_acum = 0;
	static int tone_check_times = 0;

	bool result = false;
	port_calls_cycles_acum += delta_tstates;
	port_calls++;
	if (port_calls_cycles_acum >= TONE_CHECK_CYCLE_INTERVAL) {

		uint64_t delta = TONE_CHECK_CYCLE_INTERVAL / port_calls;
		if (delta > TONE_CHECK_MIN_RANGE && delta < TONE_CHECK_MAX_RANGE)
			tone_check_times++;
		else
			tone_check_times = 0;
		if (tone_check_times == TONE_CHECK_MAX_TIMES) {
			tone_check_times = 0;
			result = true;
		}
		port_calls_cycles_acum = 0;
		port_calls = 0;
	}
	return result;
}