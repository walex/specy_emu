#include "audio.h"
#include "audio_render.h"
#include "display.h"
#include "clk_master.h"
#include "z80.h"
#include <thread>
#include <mutex> 

static std::thread audio_thread;
static std::atomic<int> audio_running{ 0 };
static std::mutex audio_buffer_mutex;
const size_t SAMPLE_RATE = 44100;
const double SAMPLES_TIME_SECS = (1.0 / DISPLAY_REFRESH_RATE_HZ);
const size_t CHUNK_SIZE = SAMPLES_TIME_SECS * SAMPLE_RATE;
const size_t BUFFER_SAMPLES = CHUNK_SIZE * 50;
float* audio_buffer = nullptr;
uint64_t tstate_now = 0;
uint64_t last_level_change_tstate = 0;
float current_level = 0.0f;
int buffer_write = 0;
int buffer_read = 0;

void audio_thread_proc();

void audio_init() {

	if (audio_running.load() != 0)
		return;

	audio_buffer = new float[BUFFER_SAMPLES];
	audio_thread = std::thread(audio_thread_proc);
	while (audio_running.load() == 0)
		std::this_thread::sleep_for(std::chrono::milliseconds(1));
}

void audio_end() {

	if (audio_running.load() == 0)
		return;
	audio_running = 0;
	if (audio_thread.joinable())
		audio_thread.join();
	delete[] audio_buffer;
}

void audio_play(uint8_t value) {

	int new_ear = (value >> 4) & 1;
	int new_mic = (value >> 3) & 1;
	float new_level = new_ear * 1.0f;// +new_mic * 0.5f;
	{
		if (current_level != new_level) {
			
			std::lock_guard<std::mutex> lock(audio_buffer_mutex);
			for (int i = 0; i < CHUNK_SIZE; i++) {
				audio_buffer[buffer_write] = new_level;
				buffer_write = (buffer_write + 1) % BUFFER_SAMPLES;

				if (buffer_write == buffer_read) {
					// buffer full
					break;
				}
			}
			current_level = new_level;
		}
		
	}
}	

void audio_thread_proc() {

	float* samples_chunk = new float[CHUNK_SIZE];
	clock_master_handle cmh = clk_master_get("display_sync_clock2");

	audio_render_init(SAMPLE_RATE);
	audio_running++;
	while (true) {

		if (audio_running.load() == 0)
			break;

		clk_master_wait(cmh);

		// here need 20ms of audio data
		{
			std::lock_guard<std::mutex> lock(audio_buffer_mutex);
			memset(samples_chunk, 0, CHUNK_SIZE * sizeof(float));
			int idx = 0;
			for (int i = buffer_read; i < buffer_write; i++) {
				
				samples_chunk[idx++] = audio_buffer[buffer_read];
				buffer_read = (buffer_read + 1) % BUFFER_SAMPLES;
				
			}
		}
		audio_render_play((uint8_t*)samples_chunk, CHUNK_SIZE * sizeof(float));
	}
	audio_render_end();
	delete[] samples_chunk;
}