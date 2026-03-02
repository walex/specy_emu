#include "memory_paging.h"
#include "memory_paging_w32.h" 
#include "system_memory.h"

constexpr uint8_t PAGING_RAM_BANK_MASK = 0x07; // Bits 0-2 for RAM bank selection
constexpr uint8_t PAGING_SCREEN_MASK = 0x08; // Bit 3 for screen selection
constexpr uint8_t PAGING_ROM_MASK = 0x10; // Bit 4 for ROM selection
constexpr uint8_t PAGING_LOCK_MASK = 0x20; // Bit 5 for paging lock
constexpr uint8_t PAGING_UNUSED_MASK = 0xC0; // Bits 6-7 are unused

constexpr size_t BANK_COUNT = 8; // Total number of memory banks (1 ROM + 7 RAM)

constexpr uint16_t BANK_ADDR_ROM = 0x0;
constexpr uint16_t BANK_ADDR_FIXED_SCREEN = 0x4000;
constexpr uint16_t BANK_ADDR_FIXED_RAM = 0x8000;
constexpr uint16_t BANK_ADDR_RAM = 0xC000;

static bool paging_locked = false;

uint8_t* memory_paging_init() {

	std::vector<uint16_t> base_addr = {
		BANK_ADDR_ROM,
		BANK_ADDR_FIXED_SCREEN,
		BANK_ADDR_FIXED_RAM,
		BANK_ADDR_RAM
	};
	std::vector <uint32_t> base_bank_index = {
		BANK_ROM_0_INDEX,
		BANK_FIXED_SCREEN_1_INDEX,
		BANK_FIXED_RAM_INDEX,
		BANK_RAM_INDEX
	};

	// 8 banks plus 2 roms
	return (uint8_t*)memory_page_create(BANK_COUNT+2, BANK_SIZE, base_addr, base_bank_index);
}

void memory_paging_end() {

	memory_page_free();
}

void memory_paging_bank_switch(uint8_t value) {

	if (paging_locked == true)
		return;

	// RAM – The RAM bank to page into& C000 to& FFFF
	uint8_t masked_value = value & PAGING_RAM_BANK_MASK;
	memory_page_set_map(BANK_ADDR_RAM, masked_value);

	// SCR – Set to 0 to display normal screen, 1 to display screen in bank 7
	masked_value = value & PAGING_SCREEN_MASK;
	memory_page_set_map(BANK_ADDR_FIXED_SCREEN, masked_value ? BANK_FIXED_SCREEN_2_INDEX : BANK_FIXED_SCREEN_1_INDEX);
//
	// ROM – Set to 0 to page in the 128K editor, or 1 to page in the 48K BASIC ROM
	masked_value = value & PAGING_ROM_MASK;
	memory_page_set_map(BANK_ADDR_ROM, masked_value ? BANK_ROM_1_INDEX : BANK_ROM_0_INDEX);

	// DIS – Set to 1 to disable memory paging until next reset
	masked_value = value & PAGING_LOCK_MASK;
	paging_locked = (masked_value != 0);
}

void memory_paging_copy_mem_to_bank(uint8_t* mem, uint32_t bank_id, size_t size) {

	memory_paging_copy_mem_to_bank_w32(mem, bank_id, size);
}