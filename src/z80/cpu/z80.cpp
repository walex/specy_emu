#include "z80.h"
#include "clk_master.h"
#include <atomic>
#include <thread>
#include <map>
#if Z80_EMULATION_SYNC_CYCLES_DELAY > 0
#include <chrono>
auto start = std::chrono::high_resolution_clock::now();
#endif

static std::atomic<bool> cpu_lock_t;
static std::atomic<uint64_t> clk_cycles{ 0 };
static std::atomic<uint64_t> sync_cycles{ 0 };
static std::map < uint16_t, clock_call_interceptor_handler> call_interceptors;

void __stdcall cpu_lock() {

    cpu_lock_t.store(true);
}

void __stdcall cpu_unlock() {

    cpu_lock_t.store(false);
}

void __stdcall cpu_wait() {
    
    while (cpu_lock_t.load()) {
        std::this_thread::sleep_for(std::chrono::microseconds(1));
    }
}

void __stdcall cpu_sync(uint8_t cycles) {

    clock_master_handle cmh = clk_master_get("display_sync_clock");

    static const uint64_t FRAME_CYCLES = (uint64_t)(Z80_CPU_FREQ_HZ / clk_master_get_frequency(cmh));
	cpu_wait();
    clk_cycles += (uint64_t)cycles;
    sync_cycles += (uint64_t)cycles;
    if (sync_cycles >= FRAME_CYCLES) {
        sync_cycles -= FRAME_CYCLES;
#if Z80_EMULATION_SYNC_CYCLES_DELAY > 0
        auto end = std::chrono::high_resolution_clock::now();
        if (end - start > std::chrono::seconds(Z80_EMULATION_SYNC_CYCLES_DELAY))
#endif
            clk_master_wait(cmh);
        return;
    }
}

uint64_t cpu_get_cycles() {
    return clk_cycles.load();
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

