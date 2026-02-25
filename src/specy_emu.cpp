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
// https://www.esp32rainbow.com/tools/tap-to-wav
// https://rk.nvg.ntnu.no/sinclair/faq/tech_z80.html?fbclid=IwY2xjawPSyrdleHRuA2FlbQIxMABicmlkETF0NkZDU21SdjZ3WEMyY1Mxc3J0YwZhcHBfaWQQMjIyMDM5MTc4ODIwMDg5MgABHg4WryNU6kFtRhWzZ2LMb4YgcGenosP5lR1txJ8TLC0ddnmS4cRdGQVoASYU_aem_Vc6X0kmWhhcAeV5_hedCOw#RREG
// https://clrhome.org/table/
// https://worldofspectrum.org/z88forever/dn327/z80undoc.htm
// http://z80.info/z80undoc3.txt
// https://gist.github.com/drhelius/8497817
// https://github.com/redcode/Z80/blob/master/sources/Z80.c#L992
// https://github.com/superzazu/z80/blob/master/z80.c#L256
// https://skoolkit.ca/disassemblies/

#include "z80.h"
#include "ula.h"
#include "system_memory.h"
#include "memory_paging.h"
#include "tape_audio.h"
#include "sna_loader.h"
#include <filesystem>
#include <thread>

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

#else

#include <unistd.h>
#include <limits.h>
std::filesystem::path get_executable_directory() {
	char exePath[PATH_MAX];
	// Get the full path of the current executable
	ssize_t count = readlink("/proc/self/exe", exePath, PATH_MAX);
	if (count != -1) {
		exePath[count] = '\0'; // Null-terminate the string
		// Use C++17 filesystem library to get the parent directory
		std::filesystem::path path_obj(exePath);
		return path_obj.parent_path();
	}
	perror("Failed to get executable path.");
	return std::filesystem::path();
}

#endif

#define Z80_TEST
int main(int argc, char* argv[]) {

	auto roms_dir = get_executable_directory();
	roms_dir = roms_dir.append("roms");
	if (system_memory_init(SPECTRUM_128K_SYSTEM, roms_dir.string().c_str())) {
		perror("rom init failed");
		return -1;
	}
	ula_init(system_memory_get_pointer());

#ifndef Z80_TEST
	if (argc > 1) {
		// load audio file from command line
		tape_audio_from_file(argv[1]);
		printf("Starting Z80 CPU emulation... file %s\n", argv[1]);
	}
	else {
		printf("Starting Z80 CPU emulation...\n");
	}
#else
	//tape_audio_from_file("C:\\Users\\wadrw\\Documents\\develop\\projects\\personal\\z80\\specy_emu\\tests\\zexall.tap");
	tape_audio_from_file("C:\\Users\\wadrw\\Documents\\develop\\projects\\personal\\z80\\specy_emu\\media\\working\\EXOLON.TAP");
	//sna_load_48k("C:\\Users\\wadrw\\Documents\\develop\\projects\\personal\\z80\\specy_emu\\media\\automania.sna", system_memory_get_pointer(0x4000));
	
#endif

	std::thread th([&]() {
		const size_t mem_size = 16 * 1024;
		std::this_thread::sleep_for(std::chrono::seconds(5));
		uint8_t* mem = new uint8_t[BANK_SIZE];
		if (mem == nullptr) {
			perror("48k RAM memory error");
			return nullptr;
		}
		memset(mem, 0, mem_size);
		system_memory_load_rom(mem, roms_dir.string().c_str(), "TK95.Spanish.rom");
		memory_paging_copy_mem_to_bank(mem, BANK_ROM_1_INDEX, BANK_SIZE);
		delete[] mem;
		});

	uint8_t force_retn = 0;
	cpu_z80_init(system_memory_get_pointer(), force_retn);
	while (true)
		cpu_z80_step();	
	system_memory_end();

	return 0;
}