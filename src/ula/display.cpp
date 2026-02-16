#include "display.h"
#include "display_consts.h"
#include "z80.h"
#include "specy_rom.h"
#include "ula.h"
#include "video_render.h"
#include <mutex>
#include <thread>
#include <chrono>
#include <semaphore>

static std::thread display_thread;
static std::atomic<int> display_running{ 0 };
static std::atomic<uint32_t> border_color{ 0 };
static uint8_t* system_memory_ptr = nullptr;
static uint32_t display_buffer[kDisplayResolutionX * kDisplayResolutionY];
static const int TOTAL_LINES = 312;
static uint64_t cycle_in_line = 0;
static std::counting_semaphore<1> hsync_semaphore(0);

void display_thread_proc();

#define PRINT_AVG_TIME(a) \
			{ \
			static uint64_t avg_sleep_time = 0; \
			static uint64_t avg_sleep_cnt = 0; \
			avg_sleep_time += a; \
			avg_sleep_cnt++; \
			if (avg_sleep_cnt % 250 == 0) { \
				uint64_t avg = avg_sleep_time / avg_sleep_cnt; \
				avg_sleep_time = 0; \
				avg_sleep_cnt = 0; \
				printf("Display avg sleep time: %llu ms\n", avg); \
			} \
			}
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

void display_draw(int y) {

	uint8_t* mem_atrib_video = system_memory_ptr + 0x5800;
	uint8_t* mem_video = system_memory_ptr + 0x4000;

	int x;
	uint32_t ink, paper, flash, bright;
	uint8_t byte, attrib;
	uint16_t frame_count = specy_rom_get_system_var_value(SPECY_48K_SYS_VAR_FRAMES);

	int buffer_height = (kDisplayResolutionY - kDisplayBufferResolutionY) / 2;
	int buffer_width = (kDisplayResolutionX - kDisplayBufferResolutionX) / 2;

	// Fill top and bottom borders
	if (y < buffer_height || y >= kDisplayBufferResolutionY + buffer_height) {
		for (x = 0; x < kDisplayResolutionX; x++) {
			display_buffer[y * kDisplayResolutionX + x] = border_color.load();
		}
	}
	else {

		// left border
		for (x = 0; x < buffer_width; x++) {
			display_buffer[y * kDisplayResolutionX + x] = border_color.load();
		}

		// center of the screen
		int screen_y = y - buffer_height;
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

		// right border
		for (x = buffer_width + kDisplayBufferResolutionX; x < kDisplayResolutionX; x++) {
			display_buffer[y * kDisplayResolutionX + x] = border_color.load();
		}
	}	
}

void display_tick(uint64_t delta_cycles) {

	cycle_in_line += delta_cycles;

	if (cycle_in_line >= HSYNC_CYCLES) {
		cycle_in_line -= HSYNC_CYCLES;

		hsync_semaphore.release();
		
	}
}

void display_thread_proc() {

	constexpr int kWindowWidth = 1024;
	constexpr int kWindowHeight = 768;
	int current_line = 0;
	auto last_draw_time = std::chrono::high_resolution_clock::now();

	video_render_init(display_buffer, kDisplayResolutionX, kDisplayResolutionY,
		kWindowWidth, kWindowHeight);
	display_running++;
	while (true) {

		if (display_running.load() == 0)
			break;

		hsync_semaphore.acquire();

		display_draw(current_line++);

		// FixME: should be 312 lines
		// wrong resolution now (border+paper)
		if (current_line == kDisplayResolutionY) {
			// FixME: should fit 20 ms per frame

			ula_assert_INT_line();
			video_render_draw();
			auto now = std::chrono::high_resolution_clock::now();
			uint64_t frame_duration = std::chrono::duration_cast<std::chrono::milliseconds>(now - last_draw_time).count();
			last_draw_time = now;
			current_line = 0;
			if (frame_duration < DISPLAY_REFRESH_RATE_MILLISECS) {
				uint64_t sleep_time = DISPLAY_REFRESH_RATE_MILLISECS - frame_duration;
				// FixMe: should not be necesary ?
				std::this_thread::sleep_for(std::chrono::milliseconds(sleep_time));
				continue;
			}
		}
		std::this_thread::yield();
	}
	video_render_end();
}


void display_set_border_color(uint8_t color) {
	border_color = KVideoColorPalleteHILO[color & 0x7][OPAQUE_MODE];;
}


