#include "sna_loader.h"
#include "system_memory.h"
#include "z80.h"
#include <stdio.h>
#include <memory>

void sna_load_48k(const char* filename, uint8_t* ram_mem) {
	FILE* file = nullptr;
	fopen_s(&file, filename, "rb");
	if (file == nullptr) {
		perror("Error opening file");
		return;
	}
	sna_48k sna;
	fread(&sna, sizeof(sna_48k), 1, file);
	fclose(file);
	memcpy(ram_mem, sna.ram, 0xC000);
	// set registers
	cpu_set_register16(CPU_REGISTER_AF, sna.header.AF);
	cpu_set_register16(CPU_REGISTER_AF_, sna.header.AF_);
	cpu_set_register16(CPU_REGISTER_BC, sna.header.BC);
	cpu_set_register16(CPU_REGISTER_BC_, sna.header.BC_);
	cpu_set_register16(CPU_REGISTER_DE, sna.header.DE);
	cpu_set_register16(CPU_REGISTER_DE_, sna.header.DE_);
	cpu_set_register16(CPU_REGISTER_HL, sna.header.HL);
	cpu_set_register16(CPU_REGISTER_HL_, sna.header.HL_);
	cpu_set_register16(CPU_REGISTER_IX, sna.header.IX);
	cpu_set_register16(CPU_REGISTER_IY, sna.header.IY);
	cpu_set_register16(CPU_REGISTER_SP, sna.header.SP);
	cpu_set_register8(CPU_REGISTER_I, sna.header.I);
	cpu_set_register8(CPU_REGISTER_R, sna.header.R);
	cpu_set_interrupt_mode(sna.header.int_mode);
}