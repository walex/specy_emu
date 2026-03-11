#include "z80.h"
#include "clk_master.h"

extern void cpu_z80_init(uint8_t* memPtr, uint8_t force_retn);
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
void cpu_set_register_IFF2(uint16_t);
void cpu_set_register_PC(uint16_t);
void interrupts_set_im(uint8_t);

uint16_t cpu_get_register_AF();
uint16_t cpu_get_register_AF_();
uint16_t cpu_get_register_BC();
uint16_t cpu_get_register_BC_();
uint16_t cpu_get_register_DE();
uint16_t cpu_get_register_DE_();
uint16_t cpu_get_register_HL();
uint16_t cpu_get_register_HL_();
uint16_t cpu_get_register_IX();
uint16_t cpu_get_register_IY();
uint16_t cpu_get_register_SP();
uint16_t cpu_get_register_I();
uint16_t cpu_get_register_R();
uint16_t cpu_get_register_IFF2();
uint16_t cpu_get_register_PC();
uint16_t interrupts_get_im();

#define MAX_INTERCEPTOR_HANDLERS    256
typedef struct _call_interceptor_data {
    
    uint16_t addr;
    clock_call_interceptor_handler handler;

} call_interceptor_data;
#define CALL_INTERCEPTOR(addr) { \
for (int i = 0; i < call_interceptors_size; i++) { \
call_interceptor_data* cid = &call_interceptors[i]; \
if (cid->addr == addr) { \
cid->handler(); \
break; \
} \
} \
}

#define SET_INTERCEPTOR(addr, hanlder) { \
if (call_interceptors_size < MAX_INTERCEPTOR_HANDLERS) { \
call_interceptor_data* cid = &call_interceptors[call_interceptors_size++]; \
cid->addr = addr; \
cid->handler = handler; \
} \
}

typedef void (*register_setter_function)(uint16_t);
typedef uint16_t(*register_getter_function)();

static call_interceptor_data call_interceptors[MAX_INTERCEPTOR_HANDLERS];
static int call_interceptors_size = 0;
static uint64_t clk_cycles = 0;
static register_setter_function register_setters[CPU_REGISTER_PC + 1];
static register_getter_function register_getters[CPU_REGISTER_PC + 1];

void cpu_init(uint8_t* memPtr, uint8_t force_retn) {
    
    register_setters[CPU_REGISTER_AF] = cpu_set_register_AF;
    register_setters[CPU_REGISTER_AF_] = cpu_set_register_AF_;
    register_setters[CPU_REGISTER_BC] = cpu_set_register_BC;
    register_setters[CPU_REGISTER_BC_] = cpu_set_register_BC_;
    register_setters[CPU_REGISTER_DE] = cpu_set_register_DE;
    register_setters[CPU_REGISTER_DE_] = cpu_set_register_DE_;
    register_setters[CPU_REGISTER_HL] = cpu_set_register_HL;
    register_setters[CPU_REGISTER_HL] = cpu_set_register_HL_;
    register_setters[CPU_REGISTER_IX] = cpu_set_register_IX; 
    register_setters[CPU_REGISTER_IY] = cpu_set_register_IY;
    register_setters[CPU_REGISTER_SP] = cpu_set_register_SP;
    register_setters[CPU_REGISTER_I] = cpu_set_register_I;
    register_setters[CPU_REGISTER_R] = cpu_set_register_R;
    register_setters[CPU_REGISTER_IFF2] = cpu_set_register_IFF2;
    register_setters[CPU_REGISTER_PC] = cpu_set_register_PC;

    register_getters[CPU_REGISTER_AF] = cpu_get_register_AF;
    register_getters[CPU_REGISTER_AF_] = cpu_get_register_AF_;
    register_getters[CPU_REGISTER_BC] = cpu_get_register_BC;
    register_getters[CPU_REGISTER_BC_] = cpu_get_register_BC_;
    register_getters[CPU_REGISTER_DE] = cpu_get_register_DE;
    register_getters[CPU_REGISTER_DE_] = cpu_get_register_DE_;
    register_getters[CPU_REGISTER_HL] = cpu_get_register_HL;
    register_getters[CPU_REGISTER_HL] = cpu_get_register_HL_;
    register_getters[CPU_REGISTER_IX] = cpu_get_register_IX;
    register_getters[CPU_REGISTER_IY] = cpu_get_register_IY;
    register_getters[CPU_REGISTER_SP] = cpu_get_register_SP;
    register_getters[CPU_REGISTER_I] = cpu_get_register_I;
    register_getters[CPU_REGISTER_R] = cpu_get_register_R;
    register_getters[CPU_REGISTER_IFF2] = cpu_get_register_IFF2;
    register_getters[CPU_REGISTER_PC] = cpu_get_register_PC;

    cpu_z80_init(memPtr, force_retn);
}

void cpu_set_wait_state(uint64_t cycles) {
    
    clk_cycles += cycles;
}

void cpu_sync(uint8_t cycles) {
    
    clock_master_handle cpu_sync_clock = clk_master_get("cpu_sync_clock");
    const double CPU_SYNC_RATE_HZ = 100;
    const uint64_t FRAME_CYCLES = (uint64_t)(Z80_CPU_FREQ_HZ / CPU_SYNC_RATE_HZ);
    clk_cycles += (uint64_t)cycles;
    clk_master_sync(cpu_sync_clock, clk_cycles, FRAME_CYCLES);
}

uint64_t cpu_get_cycles() {
    return clk_cycles;
}

void cpu_set_cycles(uint64_t cycles) {
    clk_cycles = cycles;
}

void cpu_set_call_interceptor(uint16_t addr, clock_call_interceptor_handler handler) {
   SET_INTERCEPTOR(addr, handler);
}

void cpu_on_call_interceptor(uint16_t addr) {

    CALL_INTERCEPTOR(addr);
}

void cpu_set_register16(uint8_t reg_id, uint16_t value) {
    register_setters[reg_id](value);
}

void cpu_set_register8(uint8_t reg_id, uint8_t value) {
    register_setters[reg_id]((uint16_t)value);
}

uint16_t cpu_get_register16(uint8_t reg_id) {
    return register_getters[reg_id]();
}

uint8_t cpu_get_register8(uint8_t reg_id) {
    return (uint8_t)register_getters[reg_id]();
}

void cpu_set_interrupt_mode(uint8_t mode) {
    interrupts_set_im(mode);
}

uint8_t cpu_get_interrupt_mode() {
    return (uint8_t)interrupts_get_im();
}