#include "display.h"
#include "display_consts.h"
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
	unsigned long ink, paper;
	int i, xPos;

	for (int yPos = 0; yPos < kDisplayBufferResolutionY; yPos++) {
		xPos = 0;
		for (int jPos = 0;jPos < 32;jPos++)
		{
			mask = 0x80;
			byte = *(mem_video + (static_cast<size_t>(kScanConvert[yPos]) << 5) + jPos);
			i = (yPos / 8) * jPos;
			ink = KVideoColorPalleteHILO[(((unsigned char)*(mem_atrib_video + i)) & 0x7)][color_mode];
			paper = KVideoColorPalleteHILO[((((unsigned char)*(mem_atrib_video + i)) & 0x38) >> 3)][color_mode];
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
	while (true) {

		if (display_running.load() == 0)
			break;

		auto frameStart = std::chrono::high_resolution_clock::now();

		clk_master_stop();
		display_draw();
		render_draw();
		clk_master_start();
		ula_assert_INT_line();

		auto frameEnd = std::chrono::high_resolution_clock::now();
		auto frameDuration = std::chrono::duration_cast<std::chrono::milliseconds>(frameEnd - frameStart);

		if (frameDuration.count() < 20) { // 50 hz refresh rate
			std::this_thread::sleep_for(std::chrono::milliseconds(20 - frameDuration.count()));
		}
	}
	render_end();
}

