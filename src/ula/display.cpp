#include "display.h"
#include "display_consts.h"
#include "specy_rom.h"
#include "ula.h"
#include "render.h"
#include <thread>
#include <chrono>

static std::thread display_thread;
static std::atomic<int> display_running{ 0 };
static uint8_t* system_memory_ptr = nullptr;
static uint32_t display_buffer[kDisplayBufferResolutionX * kDisplayBufferResolutionY];

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

void display_draw_paper() {
	
	uint8_t* mem_atrib_video = system_memory_ptr + 0x5800;
	uint8_t* mem_video = system_memory_ptr + 0x4000;
	uint8_t mask;
	uint8_t byte, attrib;
	uint32_t ink, paper, flash, bright;
	int r, i, xPos, jPos, yPos, color_mode;
	auto frame_count = specy_rom_get_system_var_value(SPECY_48K_SYS_VAR_FRAMES);
	for (yPos = 0; yPos < kDisplayBufferResolutionY; yPos++) {
		xPos = 0;
		for (jPos = 0;jPos < 32;jPos++)
		{			
			mask = 0x80;
			byte = *(mem_video + (static_cast<size_t>(kScanConvert[yPos]) << 5) + jPos);
			i = ((yPos >> 3) * 32) + (xPos >> 3);
			attrib = (uint8_t)*(mem_atrib_video + i);
			flash = attrib & 0x80;
			bright = attrib & 0x40;
			color_mode = bright ? BRIGHT_MODE : OPAQUE_MODE;
			ink = KVideoColorPalleteHILO[((attrib) & 0x7)][color_mode];
			paper = KVideoColorPalleteHILO[(((attrib) & 0x38) >> 3)][color_mode];
			if (flash && ((frame_count & FLASH_FASE_FRAMES) != 0)) {
				std::swap(ink, paper);
			}
			/* 
			bit 7  = FLASH
			bit 6  = BRIGHT
			bit 5–3 = PAPER (0–7)
			bit 2–0 = INK   (0–7)
			*/
			for (r = 0;r < 8;r++)
			{	
				display_buffer[(yPos * kDisplayBufferResolutionX) + xPos + r] = byte & mask ? ink : paper;
				mask >>= 1;
			}
			xPos += 8;
		}
	}

}

void display_draw_border() {
}

void display_draw() {

	display_draw_border();
	display_draw_paper();
}

void display_clock_sync() {
	
	ula_assert_INT_line();
	display_draw();
	render_draw();
}

void display_thread_proc() {

	clock_master_handle cmh = clk_master_create("display_sync_clock", 50.0); // 50 Hz
	render_init(display_buffer, kDisplayBufferResolutionX, kDisplayBufferResolutionY, 
				kDisplayResolutionX, kDisplayResolutionY,
				kWindowWidth, kWindowHeight);
	display_running++;
	while (true) {

		if (display_running.load() == 0)
			break;

		clk_master_tick(cmh, display_clock_sync);
	}
	render_end();
	clk_master_destroy(cmh);
}

void display_set_border_color(uint8_t border_color) {
	render_set_border_color(KVideoColorPalleteHILO[border_color & 0x7][OPAQUE_MODE]);
}