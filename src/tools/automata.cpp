#include "automata.h"
#include "z80.h"

constexpr double ACCEL_START_PERIOD = 100.0;
constexpr double ACCEL_START_VALUE = 10.0;
constexpr double ACCEL_STOP_PERIOD = 5000.0;
constexpr double ACCEL_STOP_VALUE = 200.0;

typedef struct {
	std::atomic<double> period;
	std::atomic<double> acceleration;
	std::atomic<uint64_t> total_states;
} PortTiming;

static PortTiming pt;

void automata_measure_port_accel(uint64_t delta_tstates, uint64_t total_states)
{
	// filtros exponenciales
	const double period_alpha = 0.05;
	const double accel_alpha = 0.2;

	static double period_avg = 0.0;
	static double last_period = 0.0;
	static double accel_avg = 0.0;

	// inicialización
	if (period_avg == 0.0) {
		period_avg = (double)delta_tstates;
		last_period = period_avg;
		pt.period.store(period_avg);
		pt.acceleration.store(0.0);
		return;
	}

	// suavizado del período
	period_avg += period_alpha * ((double)delta_tstates - period_avg);

	// aceleración = cambio del período (invertido)
	double accel = last_period - period_avg;
	last_period = period_avg;

	// suavizar aceleración
	accel_avg += accel_alpha * (accel - accel_avg);

	pt.period.store(period_avg);
	pt.acceleration.store(accel_avg);
	pt.total_states.store(total_states);
}

bool automata_port_acceleration_decrease(PortTiming& t, double x, double y) {
	return (t.period.load() < x && t.acceleration.load() < y);
}

bool automata_port_acceleration_increase(PortTiming& t, double x, double y) {
	return (t.period.load() > x && t.acceleration.load() > y);
}

bool automata_play_tape() {

	return automata_port_acceleration_increase(pt, ACCEL_START_PERIOD, ACCEL_START_VALUE);
}

bool automata_stop_tape() {
	return automata_port_acceleration_decrease(pt, ACCEL_STOP_PERIOD, ACCEL_STOP_VALUE);
}

bool automata_play_tape_idle(uint64_t total_cycles) {

	constexpr uint64_t idle_states_timeout = (uint64_t)(Z80_CPU_FREQ_HZ * 0.5);
	return (total_cycles - pt.total_states) > idle_states_timeout;
}