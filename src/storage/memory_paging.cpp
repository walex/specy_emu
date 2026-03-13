#include "memory_paging.h"
#include "memory_paging_w32.h" 
#include "system_memory.h"

constexpr uint8_t kRAMPagingBankMask = 0x07; // Bits 0-2 for RAM bank selection
constexpr uint8_t kScreenPagingBankMask = 0x08; // Bit 3 for screen selection
constexpr uint8_t kROMPagingBankMask = 0x10; // Bit 4 for ROM selection
constexpr uint8_t kROMPagingLockMask = 0x20; // Bit 5 for paging lock

constexpr uint16_t kROMPagingBankAddr = 0x0;
constexpr uint16_t kFixedScreenBankAddr = 0x4000;
constexpr uint16_t kRAMPagingBankFixedAddr = 0x8000;
constexpr uint16_t kRAMPagingBankAddr = 0xC000;
constexpr size_t kMemoryBanksCount = 8; // Total number of memory banks (1 ROM + 7 RAM)

static bool paging_locked = false;

uint8_t* memory_paging_init() {

	std::vector<uint16_t> base_addr = {
		kROMPagingBankAddr,
		kFixedScreenBankAddr,
		kRAMPagingBankFixedAddr,
		kRAMPagingBankAddr
	};
	std::vector <uint32_t> base_bank_index = {
		kBankROMIndex0,
		kBankScreenIndex0,
		kBankRAMFixedIndex,
		kBankRAMIndex
	};

	// 8 banks plus 2 roms
	return (uint8_t*)memory_page_create(kMemoryBanksCount+2, kBankSize, base_addr, base_bank_index);
}

void memory_paging_end() {

	memory_page_free();
}

void memory_paging_bank_switch(uint8_t value) {

	if (paging_locked == true)
		return;

	// RAM – The RAM bank to page into& C000 to& FFFF
	uint8_t masked_value = (uint8_t)(value & kRAMPagingBankMask);
	memory_page_set_map(kRAMPagingBankAddr, masked_value);

	// SCR – Set to 0 to display normal screen, 1 to display screen in bank 7
	masked_value = (uint8_t)(value & kScreenPagingBankMask);
	memory_page_set_map(kFixedScreenBankAddr, masked_value ? kBankScreenIndex1 : kBankScreenIndex0);
//
	// ROM – Set to 0 to page in the 128K editor, or 1 to page in the 48K BASIC ROM
	masked_value = (uint8_t)(value & kROMPagingBankMask);
	memory_page_set_map(kROMPagingBankAddr, masked_value ? kBankROMIndex1 : kBankROMIndex0);

	// DIS – Set to 1 to disable memory paging until next reset
	masked_value = (uint8_t)(value & kROMPagingLockMask);
	paging_locked = (masked_value != 0);
}

void memory_paging_copy_mem_to_bank(uint8_t* mem, uint32_t bank_id, size_t size) {

	memory_paging_copy_mem_to_bank_w32(mem, bank_id, size);
}