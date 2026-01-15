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

#include "z80.h"
#include "ula.h"
#include "specy_rom.h"
#include "tape_audio.h"
#include <filesystem>

const char* SPECY_48K_ROM_FILE = "spec_48.rom";
const char* SPECY_128K_ROM_FILE = "spec_128.rom";
const char* TK95_48K_ROM_FILE = "TK95.Spanish.rom";
const char* TK90X_48K_ROM_FILE = "TK90X.v1.Spanish.rom";
const char* TK90X_48K_ROM_V3_FILE = "TK90X_v3EN.rom";
const size_t ROM_48K_SIZE = 16 * 1024;
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

	auto exe_dir = get_executable_directory();
	exe_dir.append("roms");
	auto rom_path = exe_dir.append(TK90X_48K_ROM_V3_FILE);
	if (!specy_rom_init(rom_path.string().c_str(), ROM_48K_SIZE + RAM_48K_SIZE)) {
		perror("rom init failed");
		return -1;
	}
	ula_init(specy_rom_get_pointer());

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
	tape_audio_from_file("C:\\Users\\wadrw\\Documents\\develop\\projects\\personal\\z80\\specy_emu\\tests\\1.2a\\z80full.tap");
#endif
	Z80CPU(specy_rom_get_pointer(), 0);	
	specy_rom_end();

	return 0;
}