#include "audio.h"
#include "circular_buffer.h"
#include "audio_render.h"
#include "display.h"
#include "clk_master.h"
#include "z80.h"

// Sample rate
constexpr double kAudioSampleRate = 44100.0;
// Number of Z80 cycles per audio sample (keep as double for precision)
constexpr double kAudioSamplesCyclesCount = (double)Z80_CPU_FREQ_HZ / kAudioSampleRate;

// Increased buffer to ~100ms to handle timing variations from yield()
constexpr size_t kAudioSamplesBuffer = (size_t)(kAudioSampleRate*0.1);

// Audio state variables
static std::atomic<float> current_level(0.0);

// audio thread
static std::thread audio_thread;
static std::atomic<bool> audio_thread_running{ false };
using audio_push_sample_ptr = void(*)(float);

void audio_push_sample(float sample) {
    circular_buffer_push_sample(sample);
}

void audio_push_sample_none(float) {

}

static audio_push_sample_ptr audio_push_sample_func = audio_push_sample;

inline float tv_saturate(float x) {
    // Saturación suave, simula transistor barato de TV
    return std::tanh(x * 1.8f);
}

void audio_render_cb(uint8_t* buffer_out, int len) {

    int16_t* buffer16 = (int16_t*)buffer_out;
    for (int i = 0; i < len / 2; i++) 
        buffer16[i] = (int16_t)(circular_buffer_pop_sample() * 32767.0f);
}

void audio_thread_proc() {
    constexpr size_t buffsiz = (size_t)(kAudioSamplesBuffer * 0.1);
    int16_t buffer16[buffsiz];
    circular_buffer_init(kAudioSamplesBuffer);
    audio_render_init((uint32_t)kAudioSampleRate, nullptr);
    audio_thread_running.store(true);
    while (audio_thread_running.load()) {
        for (int i = 0; i < buffsiz; i++)
            buffer16[i] = (int16_t)(tv_saturate(circular_buffer_pop_sample()) * 32767.0f);
        audio_render_play((uint8_t*)buffer16, buffsiz * 2);
        std::this_thread::yield();
    }
}

void audio_init() {
	
    if (audio_thread_running.load())
        return;

    audio_thread = std::thread(audio_thread_proc);
    while (!audio_thread_running.load())
		std::this_thread::yield();
    audio_thread.detach();
}

// Shutdown audio system
void audio_end() {

    if (audio_thread_running.load())
        audio_thread_running.store(false);
    if (audio_thread.joinable())
        audio_thread.join();
    audio_render_end();
    circular_buffer_end();
}

// Main function to send audio samples, called from the ULA emulation
// `tstates_cpu_total` is the accumulated Z80 cycles since emulation start
void audio_set_level(uint8_t value) {
#ifdef CPU_CLOCK_SYNC
    //int new_mic = (value >> 3) & 1;
    int new_ear = (value >> 4) & 1;
    float lvl = new_ear ? 1.0f : 0.0f;
    current_level.store(lvl, std::memory_order_relaxed);
#endif
}

void audio_tick(uint64_t delta_tstates) {

    static double tstate_accum = 0.0;
    double accum = tstate_accum;
    accum += (double)delta_tstates;
    while (accum >= kAudioSamplesCyclesCount) {
        auto level = current_level.load(std::memory_order_relaxed);
        accum -= kAudioSamplesCyclesCount;
        audio_push_sample_func(level);
    }
    tstate_accum = accum;
}

void audio_enable(bool enable) {

    if (enable)
        audio_push_sample_func = audio_push_sample;
    else
        audio_push_sample_func = audio_push_sample_none;
    memset(&current_level, 0, sizeof(current_level));
    circular_buffer_clear();
}