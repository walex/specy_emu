#include "audio.h"
#include "audio_render.h"
#include "display.h"
#include "clk_master.h"
#include "z80.h"

#include <thread>
#include <mutex>
#include <atomic>
#include <cstdint>
#include <cmath>
#include <chrono>

static std::thread audio_thread;
static std::atomic<int> audio_running{ 0 };
static std::mutex audio_buffer_mutex;

// Audio configuration
constexpr size_t SAMPLE_RATE = 44100;
constexpr double SAMPLES_TIME_SECS = DISPLAY_REFRESH_RATE_SECS;
constexpr size_t CHUNK_SIZE = SAMPLES_TIME_SECS * SAMPLE_RATE; // ~20ms de audio
constexpr size_t BUFFER_SAMPLES = CHUNK_SIZE * 50;

// Number of Z80 cycles per audio sample
constexpr double CYCLES_PER_SAMPLE = 3500000.0 / SAMPLE_RATE; // ~79.4 tstates

// Circular audio buffer
static float audio_buffer[BUFFER_SAMPLES];
static int buffer_write = 0;
static int buffer_read = 0;

// Audio state variables
static double tstate_accum = 0.0;
static float current_level = 0.0f;
static uint64_t last_tstate = 0;
static bool first_call = true;

// Forward declaration
void audio_thread_proc();

// Initialize audio system
void audio_init() {
    if (audio_running.load() != 0)
        return;

    audio_thread = std::thread(audio_thread_proc);

    // Wait for audio thread to start
    while (audio_running.load() == 0)
        std::this_thread::sleep_for(std::chrono::milliseconds(1));
}

// Shutdown audio system
void audio_end() {
    if (audio_running.load() == 0)
        return;
    audio_running = 0;
    if (audio_thread.joinable())
        audio_thread.join();
}

// Internal function to push a sample into the circular buffer
static void push_sample(float level) {
    std::lock_guard<std::mutex> lock(audio_buffer_mutex);
    audio_buffer[buffer_write] = level;
    buffer_write = (buffer_write + 1) % BUFFER_SAMPLES;
    // Si se llena, se descarta el sample más antiguo
    if (buffer_write == buffer_read)
        buffer_read = (buffer_read + 1) % BUFFER_SAMPLES;
}

// Main function to send audio samples, called from the ULA emulation
// `tstates_cpu_total` is the accumulated Z80 cycles since emulation start
void audio_play(uint64_t tstates_cpu_total, uint8_t value) {
    int new_ear = (value >> 4) & 1;
    int new_mic = (value >> 3) & 1;
    float new_level = new_ear * 1.0f; // Puedes sumar new_mic * 0.5f si quieres

    if (first_call) {
        // Primera llamada: generar al menos un sample
        last_tstate = tstates_cpu_total;
        first_call = false;
        tstate_accum = 0;
        current_level = new_level;
        push_sample(current_level);
        return;
    }

    // Compute delta cycles since last call
    uint64_t delta_tstates = tstates_cpu_total - last_tstate;
    last_tstate = tstates_cpu_total;

    // Limit large delta to avoid clicks due to lag
    const uint64_t MAX_DELTA = 10000; // aprox 2.85ms a 3.5MHz
    if (delta_tstates > MAX_DELTA)
        delta_tstates = MAX_DELTA;

    // Compute number of audio samples to generate
    tstate_accum += delta_tstates;
    while (tstate_accum >= CYCLES_PER_SAMPLE) {
        // Push samples with current level(no filtering)
        push_sample(current_level);
        tstate_accum -= CYCLES_PER_SAMPLE;
    }

    current_level = new_level;
}

// Audio thread: reads buffer and sends to audio render
void audio_thread_proc() {
    audio_running++;
    float* samples_chunk = new float[CHUNK_SIZE];
    int16_t* sdl_chunk = new int16_t[CHUNK_SIZE];

    clock_master_handle cmh = clk_master_get("display_sync_clock2");
    audio_render_init(SAMPLE_RATE);

    while (audio_running.load() != 0) {
        clk_master_wait(cmh);

        // Llenar chunk con samples del buffer
        size_t fill_len = 0;
        {
            std::lock_guard<std::mutex> lock(audio_buffer_mutex);
            while (buffer_read != buffer_write && fill_len < CHUNK_SIZE) {
                samples_chunk[fill_len++] = audio_buffer[buffer_read];
                buffer_read = (buffer_read + 1) % BUFFER_SAMPLES;
            }
        }

        // Si no hay suficientes samples, rellenar con el último nivel
        for (size_t i = fill_len; i < CHUNK_SIZE; i++)
            samples_chunk[i] = current_level;

        // Convertir float 0.0-1.0 a int16_t para SDL
        for (size_t i = 0; i < CHUNK_SIZE; i++) {
            sdl_chunk[i] = static_cast<int16_t>(std::round(samples_chunk[i] * 32767.0f));
        }

        // Enviar a SDL
        audio_render_play((uint8_t*)sdl_chunk, CHUNK_SIZE * sizeof(int16_t));
    }

    audio_render_end();
    delete[] samples_chunk;
    delete[] sdl_chunk;
}
