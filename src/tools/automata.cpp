#include "automata.h"
#include "z80.h"

bool automata_port_is_waiting_for_tone(uint64_t delta_tstates) {

	constexpr int kPilotToneCheckCount = 5;
	constexpr uint64_t kPilotToneCheckCycleCount = Z80_CPU_FREQ_HZ / 10;
	constexpr uint64_t kPilotToneMinFrequency = 70;
	constexpr uint64_t kPilotToneMaxFrequency = 75;
	static uint64_t port_calls = 0;
	static uint64_t port_calls_cycles_acum = 0;
	static int tone_check_times = 0;

	bool result = false;
	port_calls_cycles_acum += delta_tstates;
	port_calls++;
	if (port_calls_cycles_acum >= kPilotToneCheckCycleCount) {

		uint64_t delta = kPilotToneCheckCycleCount / port_calls;
		if (delta > kPilotToneMinFrequency && delta < kPilotToneMaxFrequency)
			tone_check_times++;
		else
			tone_check_times = 0;
		if (tone_check_times == kPilotToneCheckCount) {
			tone_check_times = 0;
			result = true;
		}
		port_calls_cycles_acum = 0;
		port_calls = 0;
	}
	return result;
}