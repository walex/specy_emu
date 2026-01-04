#include "clk_master.h"
#include <chrono>
#include <thread>
#include <mutex>

static std::chrono::high_resolution_clock::time_point start;
static std::atomic<int> clk_running{ 1 };
constexpr double Z80_FREQ_HZ = 3'500'000.0;
constexpr double CYCLE_US = 1'000'000.0 / Z80_FREQ_HZ;

void clk_master_start() {
    
    clk_running = 1;
}

void clk_master_stop() {

    clk_running = 0;
}

void clk_master_reset() {
    
    start = std::chrono::high_resolution_clock::now();
}

void clk_master_wait() {

    while (clk_running.load() == 0)
        std::this_thread::sleep_for(std::chrono::microseconds(1));
}

// Función para simular espera de N ciclos
void clk_master_sync(uint8_t cycles, uint8_t t_states) {
    
    double total_us = cycles * CYCLE_US;

    while (true) {
        auto now = std::chrono::high_resolution_clock::now();
        double elapsed_us = std::chrono::duration<double, std::micro>(now - start).count();
        if (elapsed_us >= total_us) 
            break;
    }

    clk_master_wait();
}