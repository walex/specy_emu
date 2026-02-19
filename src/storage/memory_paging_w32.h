#ifdef WINDOWS_PLATFORM

#ifndef __MEMORY_PAGE_W32__
#define __MEMORY_PAGE_W32__

#include <Windows.h>
#include <stdio.h>
#include <vector>

#pragma comment(lib, "onecore.lib")

constexpr size_t VISIBLE_SIZE = 64 * 1024;
static HANDLE mem_handle = nullptr;
static void* placeholder_page = nullptr;
static std::vector<void*> memory_views;

inline void log_w32_last_error() {

    char error_desc[256];
    FormatMessageA(
        FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        nullptr,
        GetLastError(),
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        error_desc,
        sizeof(error_desc),
        nullptr);
    printf("Failed:\n%s\n", error_desc);
}

inline void* memory_page_alloc_placeholder(size_t size) {
    
    void * place_holder = VirtualAlloc2(
        GetCurrentProcess(),
        nullptr,
        size,
        MEM_RESERVE | MEM_RESERVE_PLACEHOLDER,
        PAGE_NOACCESS,
        nullptr,
        0);
    if (place_holder == nullptr)
        log_w32_last_error();
	return place_holder;
}

//void switch_bank(int slot, int new_bank)
//{
//    void* addr = base + slot * VIRTUAL_BANK_SIZE;
//
//    UnmapViewOfFile(addr);
//
//    VirtualFree(
//        addr,
//        VIRTUAL_BANK_SIZE,
//        MEM_RELEASE | MEM_PRESERVE_PLACEHOLDER
//    );
//
//   void* map = MapViewOfFile3(
//        hSection[new_bank],
//        GetCurrentProcess(),
//        addr,
//        0,
//        VIRTUAL_BANK_SIZE,
//        MEM_REPLACE_PLACEHOLDER,
//        PAGE_READWRITE,
//        nullptr,
//        0
//    );
//   if (!map)
//       log_w32_last_error();
//}


inline HANDLE memory_page_get_handle() {
    return mem_handle;
}

inline void* memory_page_create(const size_t max_banks, const size_t bank_size, const std::vector<uint16_t>& base_addr,
    const std::vector<uint32_t>& base_bank_index) {

    if (base_addr.size() != base_bank_index.size()) {
        printf("base address array must be same size as bank index array\n");
        return nullptr;
    }

    size_t block_count = base_addr.size();
    size_t mem_size = max_banks * VISIBLE_SIZE;

    mem_handle = CreateFileMapping(
        INVALID_HANDLE_VALUE,
        nullptr,
        PAGE_READWRITE,
        0,
        mem_size,
        nullptr);
    if (mem_handle == nullptr) {
        log_w32_last_error();
        return nullptr;
    }

    // Allocate placeholder for 64KB visible address space (0x0000-0xFFFF)
    placeholder_page = memory_page_alloc_placeholder(VISIBLE_SIZE);
    if (placeholder_page == nullptr) {
        log_w32_last_error();
        return nullptr;
    }

    // Split placeholder at each base address
    for (size_t i = 0; i < block_count - 1; i++) {
        void* target = (void*)((ULONG_PTR)placeholder_page + base_addr[i]);
        BOOL res = VirtualFree(
            target,
            bank_size,
            MEM_RELEASE | MEM_PRESERVE_PLACEHOLDER
        );
        if (!res) {
            printf("VirtualFree split error at 0x%X\n", base_addr[i]);
            log_w32_last_error();
        }
    }

    // Map each region to its corresponding bank in the file mapping
    for (size_t i = 0; i < block_count; i++) {
        void* target = (void*)((ULONG_PTR)placeholder_page + base_addr[i]);
        ULONG64 offset = base_bank_index[i] * VISIBLE_SIZE;

        void* result = MapViewOfFile3(
            mem_handle,
            GetCurrentProcess(),
            target,
            offset,
            bank_size,
            MEM_REPLACE_PLACEHOLDER,
            PAGE_READWRITE,
            nullptr,
            0);
        if (!result) {
            printf("MapViewOfFile3 error at virtual 0x%X -> bank %u (offset 0x%llX)\n",
                base_addr[i], base_bank_index[i], offset);
            log_w32_last_error();
        }
        else {
            memory_views.push_back(result);
        }
    }

    return memory_views.at(0);
}

inline void memory_page_free(uint8_t* memory) {

 //   VirtualFree(placeholder_page, 0, MEM_RELEASE);
    UnmapViewOfFile(memory);
    CloseHandle(mem_handle);
}

inline void* memory_page_remap(void* base_address, uint16_t virtual_offset, uint32_t new_bank_index, size_t bank_size)
{
    void* target = (void*)((ULONG_PTR)base_address + virtual_offset);
    ULONG64 file_offset = new_bank_index * VISIBLE_SIZE;

    // Step 1: Unmap the current view at this virtual address
    if (!UnmapViewOfFile2(GetCurrentProcess(), target, MEM_PRESERVE_PLACEHOLDER)) {
        printf("UnmapViewOfFile2 failed at offset 0x%X\n", virtual_offset);
        log_w32_last_error();
        return nullptr;
    }

    // Step 2: Map the new bank to the same virtual address
    void* result = MapViewOfFile3(
        mem_handle,
        GetCurrentProcess(),
        target,
        file_offset,
        bank_size,
        MEM_REPLACE_PLACEHOLDER,
        PAGE_READWRITE,
        nullptr,
        0);

    if (!result) {
        printf("MapViewOfFile3 failed: virtual 0x%X -> bank %u (offset 0x%llX)\n",
            virtual_offset, new_bank_index, file_offset);
        log_w32_last_error();
    }

    return result;
}

inline void* memory_page_set_map(uint16_t visibleOffset, uint32_t bankNumber, size_t bank_size)
{
    return memory_page_remap(placeholder_page, visibleOffset, bankNumber, bank_size);
}

inline void memory_page_destroy_map(HANDLE bank) {

    CloseHandle(bank);
}

inline void memory_paging_copy_mem_to_bank_w32(uint8_t* mem, uint32_t bank_id, size_t size) {

    HANDLE file_handle = memory_page_get_handle();

    // Map bank directly at a different virtual address
    uint64_t bank_offset = bank_id * (uint64_t)VISIBLE_SIZE;
    uint8_t* direct_bank = (uint8_t*)MapViewOfFile(
        file_handle,
        FILE_MAP_ALL_ACCESS,
        (DWORD)(bank_offset >> 32),
        (DWORD)(bank_offset & 0xFFFFFFFF),
        size
    );

    if (direct_bank) {

        memcpy(direct_bank, mem, size);
        UnmapViewOfFile(direct_bank);
    }
    else {
        printf("Error getting memory bank %d\n", bank_id);
    }
}

//inline void test_memory_paging(uint8_t* mem) {
//
//    // Get the file mapping handle to create a direct view
//    HANDLE file_handle = memory_page_get_handle();
//
//    size_t virtual_index = BANK_ADDR_ROM;
//    size_t real_index = BANK_ROM_0_INDEX;
//
//    // Map bank directly at a different virtual address
//    uint64_t bank_offset = real_index * (uint64_t)VISIBLE_SIZE;
//    uint8_t* direct_bank = (uint8_t*)MapViewOfFile(
//        file_handle,
//        FILE_MAP_ALL_ACCESS,
//        (DWORD)(bank_offset >> 32),
//        (DWORD)(bank_offset & 0xFFFFFFFF),
//        BANK_SIZE
//    );
//
//    if (direct_bank) {
//        // Write directly to bank 5's backing store
//        direct_bank[0] = 0x42;
//
//        // This change is now visible at mem[16384]
//        printf("Direct write: direct_bank[0] = 0x42\n");
//        printf("Virtual view: mem[%lld] = 0x%02X (should be 0x42)\n", virtual_index, mem[virtual_index]);
//
//        // Write from virtual address
//        mem[virtual_index] = 0x99;
//        printf("Virtual write: mem[%lld] = 0x99\n", virtual_index);
//        printf("Direct view: direct_bank5[0] = 0x%02X (should be 0x99)\n", direct_bank[0]);
//
//        UnmapViewOfFile(direct_bank);
//    }
//    else {
//        printf("Error getting memory bank %lld\n", real_index);
//    }
//}

#endif // !__MEMORY_PAGE_W32__


#endif