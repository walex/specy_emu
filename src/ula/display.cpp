#include "display.h"
#include "display_consts.h"
#include "z80.h"
#include "specy_rom.h"
#include "ula.h"
#include "video_render.h"
#include <thread>
#include <chrono>
#include <semaphore>

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

// FixME: horizontal sync needed at 224 t-states per line
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

void on_display_clock_sync(uint64_t delta_cycles) {
	
	ula_assert_INT_line();
	video_render_draw();
}

static const int TOTAL_LINES = 312;
static std::atomic<int> current_line = 0;
static uint64_t cycle_in_line = 0;


std::counting_semaphore<1> hsync_semaphore(0);
std::counting_semaphore<1> hsync_semaphore2(0);

void display_tick(uint64_t delta_cycles) {
	
	constexpr uint64_t HSYNC_CYCLES = 224;

	cycle_in_line += delta_cycles;

	while (cycle_in_line >= HSYNC_CYCLES) {
		cycle_in_line -= HSYNC_CYCLES;

		// Aquí se podría disparar HSYNC
		hsync_semaphore.release();
		hsync_semaphore2.acquire();
		current_line++;
		if (current_line == kDisplayResolutionY) {
			current_line = 0; // Nuevo frame
		}
	}

}

void display_thread_proc() {

	video_render_init(display_buffer, kDisplayResolutionX, kDisplayResolutionY,
		kWindowWidth, kWindowHeight);
	display_running++;
	int y = 0;
	uint64_t render_cycles = 0;
	while (true) {

		if (display_running.load() == 0)
			break;

		hsync_semaphore.acquire();

		int y = current_line.load();
		display_draw(y++);

		// FixME: should be 312 lines
		if (y == kDisplayResolutionY) {
			// FixME: should fit 20 ms per frame
			ula_assert_INT_line();
			video_render_draw();
		}

		hsync_semaphore2.release();
		
	}
	video_render_end();
}

void display_thread_proc2() {

	clock_master_handle cmh = clk_master_create("display_sync_clock", Z80_CPU_FREQ_HZ); // 50 Hz
	clk_master_subscribe_sync_callback(cmh, on_display_clock_sync);
	constexpr uint64_t HSYNC_CYCLES = 224;

	video_render_init(display_buffer, kDisplayResolutionX, kDisplayResolutionY,
				kWindowWidth, kWindowHeight);
	display_running++;
	int y = 0;
	uint64_t render_cycles = 0;
	while (true) {

		if (display_running.load() == 0)
			break;
		
		display_draw(y++);
		render_cycles += HSYNC_CYCLES;
		if (y >= kDisplayResolutionY) {			
			// FixME: should fit 20 ms per frame
			// wrong resolution now (border+paper)
			render_cycles = 70000; // approx 20 ms at 3.5 MHz
			clk_master_sync(cmh, render_cycles, render_cycles);
			render_cycles = 0;
			y = 0;
		}
	}
	video_render_end();
	clk_master_destroy(cmh);
}

void display_set_border_color(uint8_t color) {
	border_color = KVideoColorPalleteHILO[color & 0x7][OPAQUE_MODE];;
}


