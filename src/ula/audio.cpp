
//// BEST VERSION UNTIL NOW


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

static std::mutex audio_buffer_mutex;

// Sample rate
constexpr uint32_t SAMPLE_RATE = 44100.0;

// Number of Z80 cycles per audio sample
constexpr uint64_t CYCLES_PER_SAMPLE = (uint64_t)(Z80_CPU_FREQ_HZ / SAMPLE_RATE);

// Chunk pequeño → baja latencia
constexpr size_t CHUNK_MS = 5;
constexpr size_t CHUNK_SAMPLES = (SAMPLE_RATE * CHUNK_MS) / 1000;

// Buffer circular grande (≈100 ms)
constexpr size_t BUFFER_SAMPLES = SAMPLE_RATE / 10;

// Circular audio buffer
static float audio_buffer[BUFFER_SAMPLES];
static std::atomic<size_t> buffer_write{ 0 };
static std::atomic<size_t> buffer_read{ 0 };

// Audio state variables
static std::atomic<float> current_level{ 0.0f };
static uint64_t tstate_accum = 0;
static float last_sample = 0.0f;


void audio_render_cb(uint8_t* buffer_out, int len) {

    int16_t* buffer16 = (int16_t*)buffer_out;
    for (int i = 0; i < len / 2; i++) {

        size_t r = buffer_read.load(std::memory_order_relaxed);

        if (r == buffer_write.load(std::memory_order_acquire)) {
            // buffer vacío → HOLD (nunca cero)
            buffer16[i] = (int16_t)(last_sample * 32767.0f);
            continue;
        }

        float s = audio_buffer[r];
        last_sample = s;
        buffer_read.store((r + 1) % BUFFER_SAMPLES,
            std::memory_order_release);

        buffer16[i] = (int16_t)(s * 32767.0f);
    }
}

// Initialize audio system
void audio_init() {

    audio_render_init(SAMPLE_RATE, audio_render_cb);
}

// Shutdown audio system
void audio_end() {

    audio_render_end();
}

inline float tv_saturate(float x) {
    // Saturación suave, simula transistor barato de TV
    return std::tanh(x * 1.8f);
}

// Internal function to push a sample into the circular buffer
static inline void push_sample(float level) {
    size_t w = buffer_write.load(std::memory_order_relaxed);
    size_t next = (w + 1) % BUFFER_SAMPLES;

    if (next == buffer_read.load(std::memory_order_acquire)) {
        // overflow  descartar el sample más viejo
        buffer_read.store(
            (buffer_read.load() + 1) % BUFFER_SAMPLES,
            std::memory_order_release
        );
    }

    audio_buffer[w] = level;
    buffer_write.store(next, std::memory_order_release);
}

// Main function to send audio samples, called from the ULA emulation
// `tstates_cpu_total` is the accumulated Z80 cycles since emulation start
void audio_set_level(uint8_t value) {
    int new_mic = (value >> 3) & 1;
    int new_ear = (value >> 4) & 1;
    float lvl = new_ear ? 1.0f : -1.0f;
    current_level.store(lvl, std::memory_order_relaxed);
}

void audio_tick(uint64_t delta_tstates) {

    tstate_accum += delta_tstates;

    while (tstate_accum >= CYCLES_PER_SAMPLE) {

        // sample & hold del EAR (1-bit real)
        float s = current_level.load(std::memory_order_relaxed);

        // 0..1 → -1..1
        s = s * 2.0f - 1.0f;

        push_sample(s);

        tstate_accum -= CYCLES_PER_SAMPLE;
    }
}


