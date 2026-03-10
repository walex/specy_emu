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
#include "system_menu.h"
#include "file_system.h"

bool specy_emu_evaluate_keys(const bool* keys) {

	return system_menu_evaluate_keyboard_state(keys);
}

void specy_load_file(const char* path, int& is_image_file) {

	std::string extension = std::filesystem::path(path).extension().string();
	std::transform(extension.begin(), extension.end(), extension.begin(),
		[](char c) { return static_cast<char>(std::tolower(static_cast<unsigned char>(c))); });

	if (extension == ".sna") {
		is_image_file = sna_loader_load_48k(path, system_memory_get_pointer(0x4000));
		return;
	}

	is_image_file = false;
	if (extension == ".tap"
		|| extension == ".wav"
		) {
		tape_audio_from_file(path);
		return;
	}
}

void specy_save_file(const char* path) {

	std::string extension = std::filesystem::path(path).extension().string();
	std::transform(extension.begin(), extension.end(), extension.begin(),
		[](char c) { return static_cast<char>(std::tolower(static_cast<unsigned char>(c))); });

	if (extension == ".sna") {
		sna_loader_save_48k(path, system_memory_get_pointer(0x4000));
		return;
	}

	printf("unsupported file format for saving: %s\n", extension.c_str());
}

int main(int /*argc*/, char* /*argv[]*/) {
	
	uint32_t machineId = SPECTRUM_48K_SYSTEM;
	static int is_image_file = false;

	// init menu
	system_menu_set_callback(SYSTEM_MENU_COMMAND_OPEN_FILE, [](void* params) {
		specy_load_file((const char*)params, is_image_file);
		}
	);
	system_menu_set_callback(SYSTEM_MENU_COMMAND_SAVE_FILE, [](void* params) {
		specy_save_file((const char*)params);
		}
	);

	// init system memory
	auto roms_dir = get_executable_directory();
	roms_dir = roms_dir.append("roms");
	if (system_memory_init(machineId, roms_dir.string().c_str())) {
		perror("rom init failed");
		return -1;
	}

	// init ULA
	Ula_Callbacks ula_callbacks{
		.ulaKeyboardKeysCallback = specy_emu_evaluate_keys
	};
	ula_init(system_memory_get_pointer(), &ula_callbacks);

	//specy_load_file("C:\\Users\\wadrw\\Documents\\develop\\projects\\personal\\z80\\specy_emu\\media\\exolon.sna", is_image_file);
	//specy_load_file("C:\\Users\\wadrw\\Documents\\develop\\projects\\personal\\z80\\specy_emu\\media\\Renegade (1987)(Ocean Software).tap", is_image_file);
	
	// init z80 cpu
	cpu_z80_init(system_memory_get_pointer(), (uint8_t)is_image_file);

	// run z80 cpu
	while (ula_is_running()) {
		system_menu_update();
		cpu_z80_step();
	}

	// release ula resources
	ula_end();

	// release memory resources
	system_memory_end();
	
	return 0;
}