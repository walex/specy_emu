#include "audio.h"
#include "audio_render.h"
#include <thread>
#include <mutex> 

static std::thread audio_thread;
static std::atomic<int> audio_running{ 0 };
static std::mutex audio_buffer_mutex;

const size_t SAMPLE_RATE = 44100;
const size_t BUFFER_SAMPLES = 65536;
const size_t CHUNK_SIZE = 1024;
float audio_buffer[BUFFER_SAMPLES];
uint64_t tstate_now = 0;
uint64_t last_level_change_tstate = 0;
float current_level = 0.0f;
int buffer_write = 0;
int buffer_read = 0;

void audio_thread_proc();

void audio_init() {

	if (audio_running.load() != 0)
		return;

	audio_thread = std::thread(audio_thread_proc);
	while (audio_running.load() == 0)
		std::this_thread::sleep_for(std::chrono::microseconds(1));
}

void audio_end() {

	if (audio_running.load() == 0)
		return;
	audio_running = 0;
	if (audio_thread.joinable())
		audio_thread.join();
}

void audio_play(uint8_t value) {

	int new_ear = (value >> 4) & 1;
	int new_mic = (value >> 3) & 1;
	float new_level = new_ear * 1.0f + new_mic * 0.5f;

	if (new_level != current_level) {
		uint64_t dt = tstate_now - last_level_change_tstate;
		int samples = (int)(dt * SAMPLE_RATE / 3500000.0); // 3.5MHz CPU
		{
			std::lock_guard<std::mutex> lock(audio_buffer_mutex);
			for (int i = 0; i < samples; i++) {
				audio_buffer[buffer_write] = current_level;
				buffer_write = (buffer_write + 1) % BUFFER_SAMPLES;

				// opcional: evitar sobrescribir buffer_read
				if (buffer_write == buffer_read) {
					// buffer lleno, se puede descartar o bloquear
					break;
				}
			}
		}
		current_level = new_level;
		last_level_change_tstate = tstate_now;
	}
}	

void audio_thread_proc() {

	float samples_chunk[CHUNK_SIZE];
	uint32_t buffer_write = 0;
	uint32_t buffer_read = 0;

	audio_render_init();
	audio_running++;
	while (true) {

		if (audio_running.load() == 0)
			break;

		{
			std::lock_guard<std::mutex> lock(audio_buffer_mutex);
			for (int i = 0; i < CHUNK_SIZE; i++) {

				samples_chunk[i] = audio_buffer[buffer_read];
				buffer_read = (buffer_read + 1) % BUFFER_SAMPLES;

				// Si llegamos al write pointer
				if (buffer_read == buffer_write) {

					memset(&samples_chunk[i], 0, (CHUNK_SIZE - i - 1) * sizeof(float));
					break;
				}
			}
			audio_render_play((uint8_t*)samples_chunk, CHUNK_SIZE * sizeof(float));
		}
	}
	audio_render_end();
}