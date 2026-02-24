#include "display.h"
#include "display_consts.h"
#include "ula.h"
#include "z80.h"
#include "system_memory.h"
#include "video_render.h"
#include "tempo.h"
#include <mutex>
#include <thread>
#include <chrono>
#include <semaphore>

static std::thread display_thread;
static std::atomic<int> display_running{ 0 };
static std::atomic<uint32_t> border_color{ 0 };
static uint8_t* system_memory_ptr = nullptr;
static uint32_t display_buffer[kDisplayResolutionX * kDisplayResolutionY];
static std::atomic<uint64_t> cycle_in_line = 0;
static std::counting_semaphore<1> line_drawn_semaphore(0);

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

	if (display_running.load() != 0) {
		display_running = 0;
		if (display_thread.joinable())
			display_thread.join();
	}
	
}

void display_draw(int y) {

	uint8_t* mem_atrib_video = system_memory_ptr + 0x5800;
	uint8_t* mem_video = system_memory_ptr + 0x4000;

	int x;
	uint32_t ink, paper, flash, bright;
	uint8_t byte, attrib;
	uint16_t frame_count = system_memory_get_system_var_value_16(SPECY_48K_SYS_VAR_FRAMES);

	int buffer_height = (kDisplayResolutionY - kDisplayBufferResolutionY) / 2;
	int buffer_width = (kDisplayResolutionX - kDisplayBufferResolutionX) / 2;
	static size_t state_index = 0;
	// Fill top and bottom borders
	if (y < kHighBorderSizeY || y >= kDisplayBufferResolutionY + kHighBorderSizeY) {
		for (x = 0; x < kDisplayResolutionX; x++)
			display_buffer[y * kDisplayResolutionX + x] = border_color.load();
	}
	else {		
		// left border
		for (x = 0; x < buffer_width; x++)
			display_buffer[y * kDisplayResolutionX + x] = border_color.load();
		cpu_set_wait_state(DELAY_PATTERN_48k[state_index]);
		state_index = (state_index + 1) % DELAY_PATTERN_48k_SIZE;
		// center of the screen
		int screen_y = y - kHighBorderSizeY;
		for (int byte_x = 0; byte_x < 32; byte_x++) {
			int buffer_x = byte_x * 8 + (kDisplayResolutionX - kDisplayBufferResolutionX) / 2;

			int mem_index = (kScanConvert[screen_y] << 5) + byte_x;
			//cpu_lock();
			byte = mem_video[mem_index];
			attrib = mem_atrib_video[(screen_y >> 3) * 32 + byte_x];
			//cpu_unlock();

			flash = attrib & 0x80;
			bright = attrib & 0x40;
			ink = KVideoColorPalleteHILO[attrib & 0x07][bright ? BRIGHT_MODE : OPAQUE_MODE];
			paper = KVideoColorPalleteHILO[(attrib >> 3) & 0x07][bright ? BRIGHT_MODE : OPAQUE_MODE];

			if (flash && (frame_count & FLASH_FASE_FRAMES))
				std::swap(ink, paper);

			// Draw 8 pixels for this byte
			for (int bit = 0; bit < 8; bit++) {
				display_buffer[y * kDisplayResolutionX + buffer_x + bit] =
					(byte & (0x80 >> bit)) ? ink : paper;
			}
		}
		cpu_unset_wait_state();
		// right border
		for (x = buffer_width + kDisplayBufferResolutionX; x < kDisplayResolutionX; x++)
			display_buffer[y * kDisplayResolutionX + x] = border_color.load();
	}	
}

void display_tick(uint64_t delta_cycles) {

	static uint64_t cycle_in_frame = 0;
	static int y = 0;
	cycle_in_line += delta_cycles;
	if (y == 0) {
		ula_assert_INT_line();
	}
	if (cycle_in_line >= HSYNC_CYCLES) {
		cycle_in_frame += HSYNC_CYCLES;
		cycle_in_line -= HSYNC_CYCLES;
		display_draw(y++);
		if (y == kDisplayResolutionY) {
			MEASURE_ELAPSED_TIME("display ready time:", 200,
				y = 0;
				line_drawn_semaphore.release();
			);
			cycle_in_frame = 0;
		}
	}
}

void display_thread_proc() {

	constexpr int kWindowWidth = 1024;
	constexpr int kWindowHeight = 768;
	video_render_init(display_buffer, kDisplayResolutionX, kDisplayResolutionY,
		kWindowWidth, kWindowHeight);
	display_running++;
	while (true) {		

		if (display_running.load() == 0)
			break;

		MEASURE_ELAPSED_TIME("display scan time:", 100,
		line_drawn_semaphore.acquire();
		video_render_draw();
			)		
	}
	video_render_end();
}


void display_set_border_color(uint8_t color) {
	border_color = KVideoColorPalleteHILO[color & 0x7][OPAQUE_MODE];;
}


