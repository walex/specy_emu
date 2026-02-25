#include "z80.h"
#include "clk_master.h"
#include <atomic>
#include <thread>
#include <map>
#include <chrono>

extern "C" {
    void cpu_set_register_AF(uint16_t);
    void cpu_set_register_AF_(uint16_t);
    void cpu_set_register_BC(uint16_t);
    void cpu_set_register_BC_(uint16_t);
    void cpu_set_register_DE(uint16_t);
    void cpu_set_register_DE_(uint16_t);
    void cpu_set_register_HL(uint16_t);
    void cpu_set_register_HL_(uint16_t);
    void cpu_set_register_IX(uint16_t);
    void cpu_set_register_IY(uint16_t);
    void cpu_set_register_SP(uint16_t);
    void cpu_set_register_I(uint16_t);
    void cpu_set_register_R(uint16_t);
	void cpu_set_register_PC(uint16_t);
	void interrupts_set_im(uint8_t);
}
using register_getter_function = void (*)(uint16_t);
static std::atomic<bool> cpu_lock_t;
static std::atomic<uint64_t> clk_cycles{ 0 };
static std::atomic<uint64_t> sync_cycles{ 0 };
static std::map<uint16_t,clock_call_interceptor_handler> call_interceptors;
static std::map<uint32_t, register_getter_function> register_getters = {
    { CPU_REGISTER_AF, cpu_set_register_AF },
    { CPU_REGISTER_AF_, cpu_set_register_AF_ },
    { CPU_REGISTER_BC, cpu_set_register_BC },
    { CPU_REGISTER_BC_, cpu_set_register_BC_ },
    { CPU_REGISTER_DE, cpu_set_register_DE },
    { CPU_REGISTER_DE_, cpu_set_register_DE_ },
    { CPU_REGISTER_HL, cpu_set_register_HL },
    { CPU_REGISTER_HL, cpu_set_register_HL_ },
    { CPU_REGISTER_IX, cpu_set_register_IX },
    { CPU_REGISTER_IY, cpu_set_register_IY },
    { CPU_REGISTER_SP, cpu_set_register_SP },
    { CPU_REGISTER_I, cpu_set_register_I },
    { CPU_REGISTER_R, cpu_set_register_R },
    { CPU_REGISTER_PC, cpu_set_register_PC}
};

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

void cpu_set_register16(uint8_t reg_id, uint16_t value) {
    auto iter = register_getters.find(reg_id);
    if (iter != register_getters.end()) {
        iter->second(value);
	}
}

void cpu_set_register8(uint8_t reg_id, uint8_t value) {
    auto iter = register_getters.find(reg_id);
    if (iter != register_getters.end()) {
        iter->second((uint16_t)value);
    }
}

void cpu_set_interrupt_mode(uint8_t mode) {
	interrupts_set_im(mode);
}