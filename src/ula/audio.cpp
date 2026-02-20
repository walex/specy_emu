//// BEST VERSION UNTIL NOW


#include "audio.h"
#include "circular_buffer.h"
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
#include <semaphore>

namespace chrono = std::chrono;

struct audio_level {
    uint64_t cycles = 0;
    float value = 0.0f;
};

// Sample rate
constexpr double SAMPLE_RATE = 44100.0;
// Number of Z80 cycles per audio sample (keep as double for precision)
constexpr double CYCLES_PER_SAMPLE = (double)Z80_CPU_FREQ_HZ / SAMPLE_RATE;

// Increased buffer to ~100ms to handle timing variations from yield()
constexpr size_t BUFFER_SAMPLES = (size_t)(SAMPLE_RATE*0.1);

// Audio state variables
static std::atomic<audio_level> current_level;

void audio_render_cb(uint8_t* buffer_out, int len) {

    int16_t* buffer16 = (int16_t*)buffer_out;
    for (int i = 0; i < len / 2; i++) 
        buffer16[i] = (int16_t)(circular_buffer_pop_sample() * 32767.0f);
}

void audio_init() {

    
    static std::thread t = std::thread([]() {
        constexpr size_t buffsiz = BUFFER_SAMPLES * 0.1;
        int16_t buffer16[buffsiz];
        circular_buffer_init(BUFFER_SAMPLES);
        audio_render_init((uint32_t)SAMPLE_RATE, nullptr);
        while (true) {
            for (int i = 0; i < buffsiz; i++)
                buffer16[i] = (int16_t)(circular_buffer_pop_sample() * 32767.0f);
			audio_render_play((uint8_t*)buffer16, buffsiz * 2);    
            std::this_thread::yield();
        }
		});
    t.detach();
}

// Shutdown audio system
void audio_end() {

    audio_render_end();
    circular_buffer_end();
}

inline float tv_saturate(float x) {
    // Saturación suave, simula transistor barato de TV
    return std::tanh(x * 1.8f);
}

// Main function to send audio samples, called from the ULA emulation
// `tstates_cpu_total` is the accumulated Z80 cycles since emulation start
void audio_set_level(uint64_t total_cycles, uint8_t value) {
#ifdef CPU_CLOCK_SYNC
    int new_mic = (value >> 3) & 1;
    int new_ear = (value >> 4) & 1;
    float lvl = new_ear ? 1.0f : 0.0f;
    if (lvl == 0)
        lvl = 0;
    current_level.store({ total_cycles, lvl }, std::memory_order_relaxed);
#endif
}

void audio_tick(uint64_t delta_tstates) {

    static double tstate_accum = 0.0;
    double accum = tstate_accum;
    accum += (double)delta_tstates;
    while (accum >= CYCLES_PER_SAMPLE) {
        auto level = current_level.load(std::memory_order_relaxed);
        double level_event = (double)level.cycles;
        float level_value = level.value;
        accum -= CYCLES_PER_SAMPLE;
        circular_buffer_push_sample(level_value);
    }
    tstate_accum = accum;
}