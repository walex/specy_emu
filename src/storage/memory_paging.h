#ifndef __SPECY_MEMORY_H__
#define __SPECY_MEMORY_H__

#include <stdint.h>

constexpr uint32_t BANK_ROM_0_INDEX = 8;
constexpr uint32_t BANK_ROM_1_INDEX = 9;
constexpr uint32_t BANK_FIXED_SCREEN_1_INDEX = 5;
constexpr uint32_t BANK_FIXED_SCREEN_2_INDEX = 7;
constexpr uint32_t BANK_FIXED_RAM_INDEX = 2;
constexpr uint32_t BANK_RAM_INDEX = 3;
constexpr size_t BANK_SIZE = 16 * 1024; // 16KB per RAM bank

#ifdef __cplusplus
extern "C" {
#endif
	uint8_t* memory_paging_init();
	void memory_paging_end();
	void memory_paging_bank_switch(uint8_t value);
	void memory_paging_copy_mem_to_bank(uint8_t* mem, uint32_t bank_id, size_t size);
#ifdef __cplusplus
}
#endif

#endif // __SPECY_MEMORY_H__