// http://www.breakintoprogram.co.uk/hardware/computers/zx-spectrum/hardware/ula
// I/O Contention ???
// Snow effect ???
// https://sinclair.wiki.zxnet.co.uk/wiki/ZX_Spectrum_ULA
// https://scratchpad.fandom.com/wiki/Contended_memory
// https://wiki.speccy.org/cursos/ensamblador/interrupciones
// http://www.z80.info/zip/z80-interrupts_rewritten.pdf
// http://www.z80.info/interrup.htm
// http://www.breakintoprogram.co.uk/hardware/computers/zx-spectrum/memory-map
// https://worldofspectrum.org/faq/reference/48kreference.htm
// http://www.zxdesign.info/memoryToScreen.shtml
// https://zx.remysharp.com/tools
// https://skoolkid.github.io/rom/buffers/sysvars.html
// https://www.retroleum.co.uk/plusparts
// https://worldofspectrum.net/zx-modules/fileformats/tapformat.html#any_datablock
// https://softspectrum48.weebly.com/notes/category/tape-loading
// https://softspectrum48.weebly.com/notes/flash-loader-part-3-basic-programs-revisited
// http://www.zxdesign.info/vidparam.shtml 
// https://www.planetemu.net/roms/sinclair-zx-spectrum-tap?page=B
// https://chatgpt.com/g/g-68fd3184e0ac81918bec585b374946d1-retroai-spectrumai?fbclid=IwY2xjawPOQTNleHRuA2FlbQIxMABicmlkETBPWVU0amtXZ1VlZkhJSzc4c3J0YwZhcHBfaWQQMjIyMDM5MTc4ODIwMDg5MgABHvmfNtvzlYimOBDev4Xrk0aQrCywA8mFsuPi3LXKhf2U6oYO3-dstjOyZL6V_aem_TexHC46MCxw5cmVlXU3yHw

#include "z80.h"
#include "ula.h"
#include "specy_rom.h"
#include "tap_loader.h"
#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <filesystem>

const char* SPECY_48K_ROM_FILE = "spec_48.rom";
const char* SPECY_128K_ROM_FILE = "spec_128.rom";
const char* TK95_48K_ROM_FILE = "TK95.Spanish.rom";
const char* TK90X_48K_ROM_FILE = "TK90X.v1.Spanish.rom";
const char* TK90X_48K_ROM_V3_FILE = "TK90X_v3EN.rom";
const size_t SPECY_48K_ROM_SIZE = 16 * 1024;
const size_t ROM_16K_SIZE = 16 * 1024;
const size_t RAM_48K_SIZE = 48 * 1024;
const size_t ROM_128K_SIZE = 128 * 1024;

#ifdef _WIN32
#include <Windows.h>

std::filesystem::path get_executable_directory() {

	char exePath[MAX_PATH];
	// Get the full path of the current executable
	if (GetModuleFileNameA(NULL, exePath, MAX_PATH) != 0) {
		// Use C++17 filesystem library to get the parent directory
		std::filesystem::path path_obj(exePath);
		return path_obj.parent_path();
	}

	perror("Failed to get executable path.");
	return std::filesystem::path();
}

#endif

uint8_t* create_system_memory(const char* rom_path, size_t mem_size) {

	FILE* rom = nullptr;
	fopen_s(&rom, rom_path, "rb");
	if (rom == nullptr) {
		perror("Error opening file");
		return nullptr;
	}

	fseek(rom, 0, SEEK_END); // Move the file pointer to the end
	size_t rom_size = ftell(rom);
	fseek(rom, 0, SEEK_SET);

	uint8_t* mem = (uint8_t*)malloc(mem_size);
	if (mem == nullptr) {

		perror("RAM memory error");
		fclose(rom);
		return nullptr;
	}
	memset(mem, 0, mem_size);
	fread(mem, rom_size, 1, rom);
	fclose(rom);

	return mem;
}

void destroy_system_memory(uint8_t* system_memory) {

	free(system_memory);
}

int main(int argc, char* argv[]) {

	auto exe_dir = get_executable_directory();
	exe_dir.append("roms");
	auto rom_path = exe_dir.append(TK90X_48K_ROM_V3_FILE);
	uint8_t* system_memory = create_system_memory(rom_path.string().c_str(), SPECY_48K_ROM_SIZE + RAM_48K_SIZE);
	if (!system_memory) {
		perror("cannot load rom file");
		return -1;
	}

	printf("ROM %p\n", (void*)system_memory);

	uint8_t* tape_data;
	size_t tape_data_size;
	// https://worldofspectrum.net/archive/games/
	tape_file_to_bytes("..\\..\\..\\media\\Spy Hunter (19xx)(US Gold).TAP", &tape_data, &tape_data_size);
	
	specy_rom_set_pointer(system_memory);
	ula_init(system_memory);

	ula_set_tape_bytes(tape_data, tape_data_size);

	Z80CPU(system_memory, 0);
	destroy_system_memory(system_memory);
	
	free(tape_data);

	return 0;
}