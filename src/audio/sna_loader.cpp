#include "sna_loader.h"
#include "z80.h"
#include "display.h"
#include <memory>

int sna_load_48k(const char* filename, uint8_t* ram_mem) {
	
	sna_48k sna;
	FILE* file = nullptr;

	fopen_s(&file, filename, "rb");
	if (file == nullptr) {
		perror("Error opening file");
		return 0;
	}
	
	fread(&sna, sizeof(sna), 1, file);
	fclose(file);
	memcpy(ram_mem, sna.ram, SNA_RAM_SIZE_48K);

	cpu_set_register8(CPU_REGISTER_I, sna.header.I);
	cpu_set_register16(CPU_REGISTER_HL_, sna.header.HL_);
	cpu_set_register16(CPU_REGISTER_DE_, sna.header.DE_);
	cpu_set_register16(CPU_REGISTER_BC_, sna.header.BC_);
	cpu_set_register16(CPU_REGISTER_AF_, sna.header.AF_);	
	cpu_set_register16(CPU_REGISTER_HL, sna.header.HL);
	cpu_set_register16(CPU_REGISTER_DE, sna.header.DE);
	cpu_set_register16(CPU_REGISTER_BC, sna.header.BC);
	cpu_set_register16(CPU_REGISTER_IY, sna.header.IY);
	cpu_set_register16(CPU_REGISTER_IX, sna.header.IX);
	cpu_set_register8(CPU_REGISTER_IFF2, (uint8_t)(sna.header.IFF2 & 0x4) >> 2);
	cpu_set_register8(CPU_REGISTER_R, sna.header.R);
	cpu_set_register16(CPU_REGISTER_AF, sna.header.AF);
	cpu_set_register16(CPU_REGISTER_SP, sna.header.SP);
	cpu_set_interrupt_mode(sna.header.int_mode);
	display_set_border_color(sna.header.border_color);
	return 1;
}

void sna_save_48k(const char* filename, uint8_t* ram_mem) {

	sna_48k sna;
	FILE* file = nullptr;

	fopen_s(&file, filename, "wb");
	if (file == nullptr) {
		perror("Error opening file");
		return;
	}

	sna.header.I = (uint8_t)cpu_get_register8(CPU_REGISTER_I);
	sna.header.HL_ = cpu_get_register16(CPU_REGISTER_HL_);
	sna.header.DE_ = cpu_get_register16(CPU_REGISTER_DE_);
	sna.header.BC_ = cpu_get_register16(CPU_REGISTER_BC_);
	sna.header.AF_ = cpu_get_register16(CPU_REGISTER_AF_);
	sna.header.HL = cpu_get_register16(CPU_REGISTER_HL);
	sna.header.DE = cpu_get_register16(CPU_REGISTER_DE);
	sna.header.BC = cpu_get_register16(CPU_REGISTER_BC);
	sna.header.IY = cpu_get_register16(CPU_REGISTER_IY);
	sna.header.IX = cpu_get_register16(CPU_REGISTER_IX);
	sna.header.IFF2 = (uint8_t)(cpu_get_register8(CPU_REGISTER_IFF2) << 2);
	sna.header.R = cpu_get_register8(CPU_REGISTER_R);
	sna.header.AF = cpu_get_register16(CPU_REGISTER_AF);
	sna.header.SP = cpu_get_register16(CPU_REGISTER_SP);
	sna.header.int_mode = cpu_get_interrupt_mode();
	sna.header.border_color = (uint8_t)display_get_border_color();
	memcpy(sna.ram, ram_mem, SNA_RAM_SIZE_48K);
	fwrite(&sna, sizeof(sna), 1, file);
	fclose(file);
}