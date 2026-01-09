#include "display.h"
#include "display_consts.h"
#include "z80.h"
#include "specy_rom.h"
#include "ula.h"
#include "video_render.h"
#include <thread>
#include <chrono>

static std::thread display_thread;
static std::atomic<int> display_running{ 0 };
static std::atomic<uint32_t> border_color{ 0 };
static uint8_t* system_memory_ptr = nullptr;
static uint32_t display_buffer[kDisplayResolutionX * kDisplayResolutionY];
void display_thread_proc();

void display_init(uint8_t* system_memory) {

	if (display_running.load() != 0)
		return;

	system_memory_ptr = system_memory;
	display_thread = std::thread(display_thread_proc);
	while (display_running.load() == 0)
		std::this_thread::sleep_for(std::chrono::microseconds(1));
}

void display_end() {

	if (display_running.load() == 0)
		return;
	display_running = 0;
	if (display_thread.joinable())
		display_thread.join();
}

void display_draw() {
	uint8_t* mem_atrib_video = system_memory_ptr + 0x5800;
	uint8_t* mem_video = system_memory_ptr + 0x4000;

	int x, y;
	uint32_t ink, paper, flash, bright;
	uint8_t byte, attrib;
	uint16_t frame_count = specy_rom_get_system_var_value(SPECY_48K_SYS_VAR_FRAMES);

	// Fill top and bottom borders
	for (y = 0; y < kDisplayResolutionY; y++) {
		for (x = 0; x < kDisplayResolutionX; x++) {
			display_buffer[y * kDisplayResolutionX + x] = border_color.load();
		}
	}

	// Draw 256x192 screen in center
	for (y = 0; y < kDisplayBufferResolutionY; y++) {
		int screen_y = y;
		int buffer_y = y + (kDisplayResolutionY - kDisplayBufferResolutionY) / 2;

		for (int byte_x = 0; byte_x < 32; byte_x++) {
			int buffer_x = byte_x * 8 + (kDisplayResolutionX - kDisplayBufferResolutionX) / 2;

			int mem_index = (kScanConvert[screen_y] << 5) + byte_x;
			cpu_lock();
			byte = mem_video[mem_index];
			attrib = mem_atrib_video[(screen_y >> 3) * 32 + byte_x];
			cpu_unlock();

			flash = attrib & 0x80;
			bright = attrib & 0x40;
			ink = KVideoColorPalleteHILO[attrib & 0x07][bright ? BRIGHT_MODE : OPAQUE_MODE];
			paper = KVideoColorPalleteHILO[(attrib >> 3) & 0x07][bright ? BRIGHT_MODE : OPAQUE_MODE];

			if (flash && (frame_count & FLASH_FASE_FRAMES))
				std::swap(ink, paper);

			// Draw 8 pixels for this byte
			for (int bit = 0; bit < 8; bit++) {
				display_buffer[buffer_y * kDisplayResolutionX + buffer_x + bit] =
					(byte & (0x80 >> bit)) ? ink : paper;
			}
		}
	}
}

void display_clock_sync() {
	
	ula_assert_INT_line();
	display_draw();
	video_render_draw();
}

void display_thread_proc() {

	clock_master_handle cmh = clk_master_create("display_sync_clock", DISPLAY_REFRESH_RATE_HZ); // 50 Hz
	clock_master_handle cmh2 = clk_master_create("display_sync_clock2", DISPLAY_REFRESH_RATE_HZ); // 50 Hz

	video_render_init(display_buffer, kDisplayResolutionX, kDisplayResolutionY,
				kWindowWidth, kWindowHeight);
	display_running++;
	while (true) {

		if (display_running.load() == 0)
			break;

		clk_master_tick(cmh, display_clock_sync);
		clk_master_tick(cmh2, nullptr);
	}
	video_render_end();
	clk_master_destroy(cmh);
	clk_master_destroy(cmh2);
}

void display_set_border_color(uint8_t color) {
	border_color = KVideoColorPalleteHILO[color & 0x7][OPAQUE_MODE];;
}


