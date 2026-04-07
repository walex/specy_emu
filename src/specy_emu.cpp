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

static struct specy_emu_settings {
	bool force_rtn_on_next_instruction = false;
	bool system_reset_requested = false;
} specy_settings;

struct cmd_line_args {
	
	uint32_t machine_id;
};

void specy_emu_gui_update() {

	system_menu_update();
}

bool specy_emu_evaluate_keys(const bool* keys) {

	return system_menu_evaluate_keyboard_state(keys);
}

void specy_emu_load_file(const char* path) {

	std::string extension = std::filesystem::path(path).extension().string();
	std::transform(extension.begin(), extension.end(), extension.begin(),
		[](char c) { return static_cast<char>(std::tolower(static_cast<unsigned char>(c))); });

	if (extension == ".sna") {
		specy_settings.force_rtn_on_next_instruction = (sna_loader_load_48k(path, system_memory_get_pointer(0x4000)) == 0);
		return;
	}

	if (extension == ".tap"
		|| extension == ".wav"
		) {
		tape_audio_from_file(path);
		return;
	}
}

void specy_emu_save_file(const char* path) {

	std::string extension = std::filesystem::path(path).extension().string();
	std::transform(extension.begin(), extension.end(), extension.begin(),
		[](char c) { return static_cast<char>(std::tolower(static_cast<unsigned char>(c))); });

	if (extension == ".sna") {
		sna_loader_save_48k(path, system_memory_get_pointer(0x4000));
		return;
	}

	printf("unsupported file format for saving: %s\n", extension.c_str());
}

void specy_emu_init_gui() {

	system_menu_set_callback(kSysMenuOpenFileCallback, [](void* params) {
		specy_emu_load_file((const char*)params);
		}
	);
	system_menu_set_callback(kSysMenuSaveFileCallback, [](void* params) {
		specy_emu_save_file((const char*)params);
		}
	);
	system_menu_set_callback(kSysMenuSystenResetCallback, [](void* /*params*/ ) {
		specy_settings.system_reset_requested = true;
		}
	);
}

bool specy_emu_is_running() {

	return ula_is_running();
}

void specy_emu_parse_args(int argc, char* argv[], cmd_line_args& args) {

	if (argc > 1) {

		try {
			args.machine_id = std::stoul(argv[1]);
			if (args.machine_id < kSystemMin || args.machine_id > kSystemMax) {
				throw std::out_of_range("machine id out of range");
			}
		}
		catch (const std::exception&) {
			printf("invalid machine id argument, defaulting to 48k\n");
			args.machine_id = kSystemSinclairSpectrum48;
		}
	}
	else {
		args.machine_id = kSystemSinclairSpectrum48;
	}
}

void specy_emu_apply_pending_hacks() {

	if (specy_settings.force_rtn_on_next_instruction == true) {
		specy_settings.force_rtn_on_next_instruction = false;
		cpu_z80_step(1);
	}
}

int main(int argc, char* argv[]) {
	
	cmd_line_args args;

	Ula_Callbacks ula_callbacks{
		.ulaKeyboardKeysCallback = specy_emu_evaluate_keys
	};

	// parse command line arguments
	specy_emu_parse_args(argc, argv, args);
	
	// init app gui
	specy_emu_init_gui();

	uint32_t machine_id = args.machine_id;
	bool main_program_loop_running = true;
	while (main_program_loop_running == true) {

		// no loop unless system restart is requested
		main_program_loop_running = false;

		// init system memory
		auto roms_dir = get_executable_directory();
		roms_dir = roms_dir.append("roms");
		if (system_memory_init(machine_id, roms_dir.string().c_str())) {
			perror("rom init failed");
			return -1;
		}

		// init ULA
		ula_init(system_memory_get_pointer(), &ula_callbacks);

		// init z80 cpu
		cpu_init(system_memory_get_pointer());

		// configure memoru hooks
		system_memory_configure_hooks();

		// reset tape audio
		tape_audio_reset();

		printf("system initialized, starting emulation loop...\n");

		// z80 cpu run loop
		while (specy_emu_is_running()) {

			// update gui
			specy_emu_gui_update();

			// apply hacks
			specy_emu_apply_pending_hacks();

			// check for system reset request
			if (specy_settings.system_reset_requested == true) {
				
				main_program_loop_running = true;
				specy_settings.system_reset_requested = false;
				printf("reboot requested.\nrestarting system...\n");
				break;
			}

			// execcute next cpu instruction
			cpu_z80_step(0);
		}

		// end cpu
		cpu_end();

		// release ula resources
		ula_end();

		// release memory resources
		system_memory_end();

		printf("system resources released.\n");
	}

	return 0;
}