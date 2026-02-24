#include "z80.h"
#include "clk_master.h"
#include <atomic>
#include <thread>
#include <map>
#include <chrono>

static std::atomic<bool> cpu_lock_t;
static std::atomic<uint64_t> clk_cycles{ 0 };
static std::atomic<uint64_t> sync_cycles{ 0 };
static std::map < uint16_t, clock_call_interceptor_handler> call_interceptors;

void cpu_set_wait_state(uint64_t cycles) {
    
	cpu_lock_t.store(true);
    clk_cycles.fetch_add(cycles);
}

void cpu_unset_wait_state() {

    cpu_lock_t.store(false);
}

bool cpu_get_wait_state() {
    
	return cpu_lock_t.load();
}

void cpu_sync(uint8_t cycles) {
    
    static clock_master_handle cpu_sync_clock = clk_master_get("cpu_sync_clock");
    static constexpr double CPU_SYNC_RATE_HZ = 250;
    static constexpr uint64_t FRAME_CYCLES = (uint64_t)(Z80_CPU_FREQ_HZ / CPU_SYNC_RATE_HZ);
    clk_cycles += (uint64_t)cycles;
    clk_master_sync(cpu_sync_clock, clk_cycles, FRAME_CYCLES);
}

uint64_t cpu_get_cycles() {
    return clk_cycles.load();
}

void cpu_set_cycles(uint64_t cycles) {
    clk_cycles.store(cycles);
}

void cpu_call_opcode_interceptor(uint16_t addr, clock_call_interceptor_handler handler) {
    call_interceptors[addr] = handler;
}

void cpu_call_opcode_notify(uint16_t addr) {

    auto iter = call_interceptors.find(addr);
    if (iter != call_interceptors.end()) {
        (iter->second)();
    }
}

uint16_t cpu_get_pc(uint64_t base_addr)
{
    uint16_t pc;
    GetRegPC(base_addr, &pc);
    return pc;
}