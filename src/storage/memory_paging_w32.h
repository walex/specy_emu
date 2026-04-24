#ifdef WINDOWS_PLATFORM

#ifndef __MEMORY_PAGING_W32__
#define __MEMORY_PAGING_W32__

#include "platform.hpp"

#if defined(_MSC_VER)
#pragma comment(lib, "onecore.lib")
#endif

constexpr size_t kBankMemoryAligment = 64 * 1024;
static HANDLE mem_handle = nullptr;
static void* placeholder_page = nullptr;
static std::map<uint16_t, void*> memory_views;
static size_t bank_size = 0;

inline void print_w32_last_error(const char* func, int line) {

    char error_desc[256];
    FormatMessageA(
        FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
        nullptr,
        GetLastError(),
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        error_desc,
        sizeof(error_desc),
        nullptr);
    printf("Error %s (%d):\n%s\n\n", func, line, error_desc);
}
#define PRINT_W32_ERROR() print_w32_last_error(__FUNCTION__, __LINE__)

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
        PRINT_W32_ERROR();
	return place_holder;
}

inline HANDLE memory_page_get_handle() {
    return mem_handle;
}

inline void* memory_page_create(const size_t max_banks, const size_t size, const std::vector<uint16_t>& base_addr,
    const std::vector<uint32_t>& base_bank_index) {

    if (base_addr.size() != base_bank_index.size()) {
        printf("base address array must be same size as bank index array\n");
        return nullptr;
    }

    bank_size = size;
    size_t block_count = base_addr.size();
    size_t mem_size = max_banks * kBankMemoryAligment;

    mem_handle = CreateFileMapping(
        INVALID_HANDLE_VALUE,
        nullptr,
        PAGE_READWRITE,
        0,
        (DWORD)mem_size,
        nullptr);
    if (mem_handle == nullptr) {
        PRINT_W32_ERROR();
        return nullptr;
    }

    // Allocate placeholder for 64KB visible address space (0x0000-0xFFFF)
    placeholder_page = memory_page_alloc_placeholder(kBankMemoryAligment);
    if (placeholder_page == nullptr) {
        PRINT_W32_ERROR();
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
            PRINT_W32_ERROR();
        }
    }

    // Map each region to its corresponding bank in the file mapping
    for (size_t i = 0; i < block_count; i++) {
        void* target = (void*)((ULONG_PTR)placeholder_page + base_addr[i]);
        ULONG64 offset = base_bank_index[i] * kBankMemoryAligment;

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
            PRINT_W32_ERROR();
        }
        else {
            memory_views[base_addr[i]] = result;
        }
    }

    return memory_views[base_addr[0]];
}

inline void memory_page_free() {
    
    for (auto& view : memory_views) {
        BOOL res = UnmapViewOfFileEx(view.second, 0);
        if (!res) {
            PRINT_W32_ERROR();
        }
    }
    memory_views.clear();
    CloseHandle(mem_handle);
    placeholder_page = nullptr;
	mem_handle = nullptr;
}

inline void* memory_page_remap(void* base_address, uint16_t virtual_offset, uint32_t new_bank_index)
{
    void* target = (void*)((ULONG_PTR)base_address + virtual_offset);
    ULONG64 file_offset = new_bank_index * kBankMemoryAligment;

    // Step 1: Unmap the current view at this virtual address
    if (!UnmapViewOfFile2(GetCurrentProcess(), target, MEM_PRESERVE_PLACEHOLDER)) {
        PRINT_W32_ERROR();
        return nullptr;
    }

    memory_views[virtual_offset] = nullptr;

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
        PRINT_W32_ERROR();
    }
    memory_views[virtual_offset] = result;
    return result;
}

inline void* memory_page_set_map(uint16_t visibleOffset, uint32_t bankNumber)
{
    return memory_page_remap(placeholder_page, visibleOffset, bankNumber);
}

inline void memory_paging_copy_mem_to_bank_w32(uint8_t* mem, uint32_t bank_id, size_t size) {

    HANDLE file_handle = memory_page_get_handle();

    // Map bank directly at a different virtual address
    uint64_t bank_offset = bank_id * (uint64_t)kBankMemoryAligment;
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

#endif // !__MEMORY_PAGE_W32__


#endif