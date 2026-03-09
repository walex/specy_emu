#ifndef _SNA_LOADER_H_
#define _SNA_LOADER_H_

#include "platform.h"

/*

   48k
   Offset   Size   Description
   ------------------------------------------------------------------------
   0        1      byte   I
   1        8      word   HL',DE',BC',AF'
   9        10     word   HL,DE,BC,IY,IX
   19       1      byte   Interrupt (bit 2 contains IFF2, 1=EI/0=DI)
   20       1      byte   R
   21       4      words  AF,SP
   25       1      byte   IntMode (0=IM0/1=IM1/2=IM2)
   26       1      byte   BorderColor (0..7, not used by Spectrum 1.7)
   27       49152  bytes  RAM dump 16384..65535
   ------------------------------------------------------------------------
   Total: 49179 bytes
*/


#define SNA_RAM_SIZE_48K 0xC000

#if defined(_MSC_VER)
#pragma pack(push, 1)
#define PACKED
#elif defined(__GNUC__) || defined(__clang__)
#define PACKED __attribute__((packed))
#else
#define PACKED
#endif

struct PACKED sna_header_48k {
	uint8_t I;
	uint16_t HL_, DE_, BC_, AF_;
	uint16_t HL, DE, BC, IY, IX;
	uint8_t IFF2;
	uint8_t R;
	uint16_t AF, SP;
	uint8_t int_mode;
	uint8_t border_color;
};

struct sna_48k {
	sna_header_48k header;
	uint8_t ram[SNA_RAM_SIZE_48K];
};

#if defined(_MSC_VER)
#pragma pack(pop)
#endif

int sna_loader_load_48k(const char* filename, uint8_t* ram_mem);
void sna_loader_save_48k(const char* filename, uint8_t* ram_mem);

/*
   128k
   Offset   Size   Description
   ------------------------------------------------------------------------
   0        27     bytes  SNA header (see above)
   27       16Kb   bytes  RAM bank 5 \
   16411    16Kb   bytes  RAM bank 2  } - as standard 48Kb SNA file
   32795    16Kb   bytes  RAM bank n / (currently paged bank)
   49179    2      word   PC
   49181    1      byte   port 0x7ffd setting
   49182    1      byte   TR-DOS rom paged (1) or not (0)
   49183    16Kb   bytes  remaining RAM banks in ascending order
*/
#endif