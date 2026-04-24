#ifndef __MEMORY_PAGING__
#define __MEMORY_PAGING__

#include "platform.hpp"

constexpr uint32_t kBankROMIndex0 = 8;
constexpr uint32_t kBankROMIndex1 = 9;
constexpr uint32_t kBankScreenIndex0 = 5;
constexpr uint32_t kBankScreenIndex1 = 7;
constexpr uint32_t kBankRAMFixedIndex = 2;
constexpr uint32_t kBankRAMIndex = 3;
constexpr size_t kBankSize = 16 * 1024; // 16KB per RAM bank

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