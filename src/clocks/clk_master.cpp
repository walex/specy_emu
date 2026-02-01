#include "clk_master.h"
#include <chrono>
#include <thread>
#include <map>

struct clock_master {

	std::chrono::high_resolution_clock::time_point clock;
	double frequency;
	std::string name;
	uint64_t cycles;
	std::list<std::function<void(uint64_t)>> callbacks;
};

std::map<const char*, clock_master_handle> clock_masters;

clock_master_handle clk_master_create(const char* name, double frequency_hz) {

	if (clock_masters.find(name) != clock_masters.end()) {
		return clock_masters[name];
	}
	clock_master* cm = new clock_master();
	cm->name = name;
	cm->frequency = frequency_hz;
	cm->cycles = 0;
	clock_masters[name] = cm;
	return (void*)cm;
}

clock_master_handle clk_master_get(const char* name) {
	for (const auto& [key, value] : clock_masters) {
		if (strcmp(key, name) == 0) {
			return value;
		}
	}
	return nullptr;
}

void clk_master_destroy(clock_master_handle cm) {

    delete (clock_master*)cm;
}

void clk_master_tick(clock_master_handle cmh, uint64_t cycles) {

	((clock_master*)cmh)->cycles = cycles;
	for (auto cb : ((clock_master*)cmh)->callbacks) {
		cb(cycles);
	}
}

void clk_master_sync(clock_master_handle cmh, uint64_t cycles, uint64_t delta_cycles) {

	clk_master_tick(cmh, cycles);
	clock_master* cm = (clock_master*)cmh;
	auto now = std::chrono::high_resolution_clock::now();
	auto elapsed_cpu_time = static_cast<int64_t>(delta_cycles / (cm->frequency / 1000.0));
	auto elapsed_real_time = static_cast<int64_t>(std::chrono::duration_cast<std::chrono::milliseconds>(now - cm->clock).count());
	int64_t delta = elapsed_cpu_time - elapsed_real_time;
	if (delta < 0) {	
		delta = 0;
		cm->clock = now;
	}
	cm->clock += std::chrono::milliseconds(delta);
	std::this_thread::sleep_until(cm->clock);
	return;
}

double clk_master_get_frequency(clock_master_handle cmh) {
	clock_master* cm = (clock_master*)cmh;
	return cm->frequency;
}

uint64_t clk_master_get_cycles(clock_master_handle cmh) {

	return ((clock_master*)cmh)->cycles;
}

void clk_master_subscribe_sync_callback(clock_master_handle cmh, clock_master_clicks_callback_function cb) {
		
	((clock_master*)cmh)->callbacks.push_back(cb);
}