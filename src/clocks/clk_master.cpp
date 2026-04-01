#include "clk_master.h"

struct clock_master {

	std::chrono::high_resolution_clock::time_point clock;
	double frequency;
	std::string name;
	uint64_t cycles;
	uint64_t sync_cycles;
	uint64_t last_total_cycles;
	std::list<std::function<void(uint64_t)>> callbacks;
};

struct cmp {
	bool operator()(const char* a, const char* b) const {
		return std::strcmp(a, b) < 0;
	}
};

static std::map<const char*, clock_master_handle, cmp> clock_masters;
static bool cpu_speed_mode = false;
using clock_sync_func_impl_ptr = void(*)(clock_master_handle, uint64_t, uint64_t, uint64_t&);

void non_clock_sync_func(clock_master_handle, uint64_t, uint64_t, uint64_t&) {}
void clock_sync_func(clock_master_handle cmh, uint64_t total_cycles, uint64_t sync_cycles, uint64_t& last_total_cycles) {

	clock_master* cm = (clock_master*)cmh;
	uint64_t delta_cycles = total_cycles - cm->cycles;
	if (cm->sync_cycles == 0)
		cm->clock = std::chrono::high_resolution_clock::now();
	cm->sync_cycles += delta_cycles;
	if (cm->sync_cycles >= sync_cycles) {
		std::chrono::high_resolution_clock::time_point now = std::chrono::high_resolution_clock::now();
		double elapsed_cpu_time = (double)sync_cycles / (cm->frequency / 1000000.0);  // microseconds
		auto target_time = cm->clock + std::chrono::microseconds((int64_t)elapsed_cpu_time);
		// Sleep until target time (smooth pacing)
		if (now < target_time) {
			const auto delta_t = std::chrono::duration_cast<std::chrono::microseconds>(target_time - now).count();
			if (delta_t > 0) {
				uint64_t delta_c = (total_cycles - last_total_cycles) / delta_t;
				while (now < target_time) {
					last_total_cycles += delta_c;
					if (last_total_cycles < total_cycles) {
						clk_master_tick(cmh, (uint64_t)last_total_cycles);
					}
					now = std::chrono::high_resolution_clock::now();
				}
			}
			cm->clock = target_time;
		}
		else {
			// Running behind - don't sleep, but update clock
			cm->clock = now;
		}
		cm->sync_cycles -= sync_cycles;
	}
}

clock_sync_func_impl_ptr clock_sync_func_impl = clock_sync_func;

clock_master_handle clk_master_create(const char* name, double frequency_hz) {

	if (clock_masters.find(name) != clock_masters.end()) {
		return clock_masters[name];
	}
	clock_master* cm = new clock_master();
	cm->name = name;
	cm->frequency = frequency_hz;
	cm->cycles = 0;
	cm->sync_cycles = 0;
	cm->last_total_cycles = 0;
	cm->clock = std::chrono::high_resolution_clock::now();
	clock_masters[name] = cm;
	return (clock_master_handle)cm;
}

void clk_master_reset(const char* name){

	clock_master* cm = (clock_master*)clk_master_get(name);
	cm->cycles = 0;
	cm->sync_cycles = 0;
	cm->clock = std::chrono::high_resolution_clock::now();
}


void clk_master_destroy(const char* name) {

	clock_master* cm = (clock_master*)clk_master_get(name);	
	if (cm) {
		delete cm;
		clock_masters.erase(name);
	}
	else {
		printf("Error destroying clock master %s\n", name);
	}
	
}

clock_master_handle clk_master_get(const char* name) {

	try {
		return clock_masters.at(name);
	} catch (const std::out_of_range&) {
		printf("Error getting clock master %s\n", name);
	}
	return nullptr;
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
	clock_sync_func_impl(cmh, total_cycles, sync_cycles, cm->last_total_cycles);
	clk_master_tick(cmh, total_cycles);
	cm->last_total_cycles = total_cycles;
}

double clk_master_get_frequency(clock_master_handle cmh) {

	return ((clock_master*)cmh)->frequency;
}

uint64_t clk_master_get_cycles(clock_master_handle cmh) {

	return ((clock_master*)cmh)->cycles;
}

void clk_master_subscribe_sync_callback(clock_master_handle cmh, clock_master_clicks_callback_function cb) {
		
	((clock_master*)cmh)->callbacks.push_back(cb);
}

void clk_master_switch_mode(bool mode) {

	cpu_speed_mode = mode;
	if (cpu_speed_mode)
		clock_sync_func_impl = non_clock_sync_func;
	else
		clock_sync_func_impl = clock_sync_func;
}