#include "clk_master.h"
#include <chrono>
#include <thread>
#include <mutex>
#include <map>

#include <Windows.h>

struct clock_master {

    std::chrono::steady_clock::time_point clock;
	uint64_t duration_ms;
	double frequency;
	HANDLE sem;
};
std::map<const char*, clock_master_handle> clock_masters;

clock_master_handle clk_master_create(const char* name, double frequency_hz) {

	if (clock_masters.find(name) != clock_masters.end()) {
		return clock_masters[name];
	}
	clock_master* cm = new clock_master();
    cm->clock = std::chrono::steady_clock::now();
	cm->duration_ms = (1 / frequency_hz) * 1000;
	cm->frequency = frequency_hz;
	cm->sem = CreateSemaphoreA(
		NULL,   // seguridad
		1,      // valor inicial
		1,      // valor máximo
		name
	);
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

void clk_master_tick(clock_master_handle cmh, clock_master_callback_function cb) {
   
	clock_master* cm = (clock_master*)cmh;
	cm->clock += std::chrono::milliseconds(cm->duration_ms);
	std::this_thread::sleep_until(cm->clock);
	ReleaseSemaphore(cm->sem, 1, nullptr);
	cb();    
}

void clk_master_wait(clock_master_handle cmh) {

	clock_master* cm = (clock_master*)cmh;
	WaitForSingleObject(cm->sem, INFINITE);
}

double clk_master_get_frequency(clock_master_handle cmh) {
	clock_master* cm = (clock_master*)cmh;
	return cm->frequency;
}