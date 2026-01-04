extern void ula_read_port(unsigned short int addr, unsigned char* value);
extern void ula_write_port(unsigned short int addr, unsigned char value);

extern void __stdcall Inst_IN_Impl(unsigned short int addr, unsigned char* value) {
	
	ula_read_port(addr, value);
}

extern void __stdcall Inst_OUT_Impl(unsigned short int addr, unsigned char value) {


	addr = addr & 0x00FF;
	switch (addr) {
	case 0xFE:
		ula_write_port(addr, value);
		break;
	default:
		break;
	}

}

extern unsigned char __stdcall parity(unsigned char c) {
    int count = 0;

    // Count the number of set bits (1s)
    while (c) {
        count += c & 1; // Add the least significant bit to the count
        c >>= 1;        // Shift right to check the next bit
    }

    // Return 0 for odd parity, 1 for even parity
    return (unsigned char)!(count % 2);
}

extern void __stdcall Inst_DAA_C(unsigned char* reg_a, unsigned char* reg_f)
{
    int t;

    t = 0;

    unsigned char A = *reg_a;
    unsigned char F = *reg_f;
    unsigned char H = ((F & 0x10) >> 4);
    const unsigned char N = ((F & 0x2) >> 1);
    unsigned char C = (F & 1);

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