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
	uint8_t mask;
	uint8_t byte, attrib;
	uint32_t ink, paper, flash, bright;
	int r, i, scan_pos_x, jPos, scan_pos_y, color_mode, x, y, j, xy, xy_offset;
	int offset_x = (kDisplayResolutionX - kDisplayBufferResolutionX) / 2;
	int offset_y = (kDisplayResolutionY - kDisplayBufferResolutionY) / 2;
	uint16_t frame_count;
	for (y = 0; y < kDisplayResolutionY; y++) {
		if (y>= offset_y && y < kDisplayResolutionY - offset_y) {
			scan_pos_y = y - offset_y;
			scan_pos_x = 0;
			for (jPos = 0;jPos < 32;jPos++)
			{
				mask = 0x80;
				i = ((scan_pos_y >> 3) * 32) + (scan_pos_x >> 3);
				j = (static_cast<size_t>(kScanConvert[scan_pos_y]) << 5) + jPos;
				lock_cpu();				
				byte = *(mem_video + j);
				attrib = (uint8_t) * (mem_atrib_video + i);
				frame_count = specy_rom_get_system_var_value(SPECY_48K_SYS_VAR_FRAMES);
				unlock_cpu();
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
				xy = ((scan_pos_y + offset_y) * kDisplayResolutionX);
				xy_offset = 0;
				for (x = 0; x < offset_x; x++) {
					display_buffer[xy + x] = border_color.load();
				}
				for (r = 0;r < 8;r++)
				{
					xy_offset = scan_pos_x + r + offset_x;
					display_buffer[xy + xy_offset] = byte & mask ? ink : paper;
					mask >>= 1;
				}
				for (x = xy_offset+1; x < xy_offset + offset_x + 1; x++) {
					display_buffer[xy + x] = border_color.load();
				}				
				scan_pos_x += 8;
			}			
		}
		else {
			for (x = 0; x < kDisplayResolutionX; x++) {
				display_buffer[y * kDisplayResolutionX + x] = border_color.load();
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


