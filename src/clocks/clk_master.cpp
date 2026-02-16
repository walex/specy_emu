#include "clk_master.h"
#include <chrono>
#include <thread>
#include <map>

struct clock_master {

	std::chrono::high_resolution_clock::time_point clock;
	double frequency;
	std::string name;
	uint64_t cycles;
	uint64_t sync_cycles;
	std::list<std::function<void(uint64_t)>> callbacks;
};

static std::map<const char*, clock_master_handle> clock_masters;

clock_master_handle clk_master_create(const char* name, double frequency_hz) {

	if (clock_masters.find(name) != clock_masters.end()) {
		return clock_masters[name];
	}
	clock_master* cm = new clock_master();
	cm->name = name;
	cm->frequency = frequency_hz;
	cm->cycles = 0;
	cm->sync_cycles = 0;
	cm->clock = std::chrono::high_resolution_clock::now();
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

void clk_master_tick(clock_master_handle cmh, uint64_t total_cycles) {

	clock_master* cm = (clock_master*)cmh;
	cm->cycles = total_cycles;
	for (auto cb : ((clock_master*)cmh)->callbacks) {
		cb(cm->cycles);
	}
}

void clk_master_sync(clock_master_handle cmh, uint64_t total_cycles, uint64_t sync_cycles) {

	clock_master* cm = (clock_master*)cmh;	
	uint64_t delta_cycles = total_cycles - cm->cycles;
	static uint64_t last_total_cycles = 0;
	if (cm->sync_cycles == 0)
		cm->clock = std::chrono::high_resolution_clock::now();
	
	cm->sync_cycles += delta_cycles;	

	if (cm->sync_cycles >= sync_cycles) {
		auto now = std::chrono::high_resolution_clock::now();
		double elapsed_cpu_time = sync_cycles / (cm->frequency / 1000000.0);  // microseconds
		auto target_time = cm->clock + std::chrono::microseconds((int64_t)elapsed_cpu_time);
		// Sleep until target time (smooth pacing)
		if (now < target_time) {
			const uint64_t delta_t = std::chrono::duration_cast<std::chrono::microseconds>(target_time-now).count();
			if (delta_t > 0) {
				uint64_t delta_c = (total_cycles - last_total_cycles) / delta_t;
				while (now < target_time) {
					last_total_cycles += delta_c;
					if (last_total_cycles < total_cycles) {
						clk_master_tick(cmh, (uint64_t)last_total_cycles);
					}
					std::this_thread::yield();
					now = std::chrono::high_resolution_clock::now();
				}				
			}
			if (last_total_cycles < total_cycles)
				clk_master_tick(cmh, total_cycles);
			cm->clock = target_time;
		} else {
			// Running behind - don't sleep, but update clock
			cm->clock = now;
			clk_master_tick(cmh, total_cycles);
		}		
		cm->sync_cycles -= sync_cycles;
	} else
		clk_master_tick(cmh, total_cycles);
	
	last_total_cycles = total_cycles;
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