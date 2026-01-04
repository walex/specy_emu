#include "display.h"
#include "display_consts.h"
#include "specy_rom.h"
#include "ula.h"
#include "render.h"
#include <thread>
#include <chrono>

static std::thread display_thread;
static std::atomic<int> display_running{ 0 };
static unsigned char* system_memory_ptr = nullptr;
static unsigned long display_buffer[kDisplayBufferResolutionX * kDisplayBufferResolutionY];

void display_thread_proc();

void display_init(unsigned char* system_memory) {

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
	
	unsigned char* mem_atrib_video = system_memory_ptr + 0x5800;
	unsigned char* mem_video = system_memory_ptr + 0x4000;
	unsigned char mask = 0x80;
	unsigned char byte;
	unsigned long ink, paper, flash, bright;
	int i, xPos;

	for (int yPos = 0; yPos < kDisplayBufferResolutionY; yPos++) {
		xPos = 0;
		for (int jPos = 0;jPos < 32;jPos++)
		{
			mask = 0x80;
			byte = *(mem_video + (static_cast<size_t>(kScanConvert[yPos]) << 5) + jPos);
			i = (jPos / 8) * yPos;
			//i = (((kScanConvert[yPos]) / 8 ) + 1) * jPos;
			//printf("%d\n", i);
			unsigned char attrib = (unsigned char)*(mem_atrib_video + i);
			auto frame_count = specy_rom_get_system_var_value(SPECY_48K_SYS_VAR_FRAMES);
			flash = attrib & 0x80;
			bright = attrib & 0x40;
			int color_mode = bright ? BRIGHT_MODE : OPAQUE_MODE;
			ink = KVideoColorPalleteHILO[((attrib) & 0x7)][color_mode];
			paper = KVideoColorPalleteHILO[(((attrib) & 0x38) >> 3)][color_mode];
			bool flash_phase = (frame_count & FLASH_FASE_FRAMES) != 0;
			if (flash && flash_phase) {
				std::swap(ink, paper);
			}
			/* 
			bit 7  = FLASH
			bit 6  = BRIGHT
			bit 5–3 = PAPER (0–7)
			bit 2–0 = INK   (0–7)
			*/ 

			for (int r = 0;r < 8;r++)
			{
				display_buffer[(yPos * kDisplayBufferResolutionX) + xPos + r] = byte & mask ? ink : paper;
				mask >>= 1;
			}
			xPos += 8;
		}
	}
}

void display_thread_proc() {

	render_init(display_buffer, kDisplayBufferResolutionX, kDisplayBufferResolutionY, 
				kDisplayResolutionX, kDisplayResolutionY,
				kWindowWidth, kWindowHeight);
	display_running++;
	auto next = std::chrono::steady_clock::now();
	while (true) {

		if (display_running.load() == 0)
			break;

		next += std::chrono::milliseconds(20);

		clk_master_stop();
		display_draw();
		render_draw();
		clk_master_start();
		ula_assert_INT_line();

		std::this_thread::sleep_until(next);
	}
	render_end();
}

void display_set_border_color(unsigned char border_color) {
	render_set_border_color(KVideoColorPalleteHILO[border_color & 0x7][OPAQUE_MODE]);
}