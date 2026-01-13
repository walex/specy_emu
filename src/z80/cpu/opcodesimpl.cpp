#include "z80.h"
#include "clk_master.h"
#include <stdint.h>
#include <chrono>
#include <thread>

extern "C" void ula_read_port(uint16_t addr, uint8_t* value);
extern "C" void ula_write_port(uint16_t addr, uint8_t value);

extern "C" void  inst_IN_Impl(uint16_t addr, uint8_t* value) {
	
    ula_read_port(addr, value);
}

extern "C" void inst_OUT_Impl(uint16_t addr, uint8_t value) {


	addr = addr & 0x00FF;
	switch (addr) {
	case 0xFE:
		ula_write_port(addr, value);
		break;
	default:
		break;
	}

}

extern "C" uint8_t parity(uint8_t c) {
    int count = 0;

    // Count the number of set bits (1s)
    while (c) {
        count += c & 1; // Add the least significant bit to the count
        c >>= 1;        // Shift right to check the next bit
    }

    // Return 0 for odd parity, 1 for even parity
    return (uint8_t)!(count % 2);
}

extern "C" void inst_DAA_C(uint8_t* reg_a, uint8_t* reg_f)
{
    int t;

    t = 0;

    uint8_t A = *reg_a;
    uint8_t F = *reg_f;
    uint8_t H = ((F & 0x10) >> 4);
    const uint8_t N = ((F & 0x2) >> 1);
    uint8_t C = (F & 1);

    if (H || ((A & 0xF) > 9))
        t++;

    if (C || (A > 0x99))
    {
        t += 2;
        C = 1;
    }
    else {
        C = 0;
    }

    // builds final H flag
    if (N && !H)
        H = 0;
    else
    {
        if (N && H)
            H = ((A & 0x0F) < 6);
        else
            H = ((A & 0x0F) >= 0x0A);
    }

    switch (t)
    {
    case 1:
        A += (N) ? 0xFA : 0x06; // -6:6
        break;
    case 2:
        A += (N) ? 0xA0 : 0x60; // -0x60:0x60
        break;
    case 3:
        A += (N) ? 0x9A : 0x66; // -0x66:0x66
        break;
    }

    *reg_a = A;
    F = (F & 0x2);
    F |= ((A & 0x80) | ((A == 0) ? (1 << 6) : 0 ) | (H << 4) | (parity(A) << 2) | C);
    *reg_f = F;

}

extern "C" void acumulate_opcode_cycles_c(uint8_t cycles, uint8_t m_cycles) {
    
    cpu_sync(cycles);
}

