#include "circular_buffer.h"
#include <atomic>
#include <thread>

static float *audio_buffer;
static size_t buffer_size{ 0 };
static std::atomic<size_t> buffer_write{ 0 };
static std::atomic<size_t> buffer_read{ 0 };
static std::atomic<size_t> buffer_count{ 0 };

void circular_buffer_init(size_t size) {

    buffer_size = size;
    audio_buffer = new float[buffer_size];    
}

void circular_buffer_end() {

    delete[] audio_buffer;
    audio_buffer = nullptr;
    buffer_size = 0;
}

void circular_buffer_clear() {
    buffer_write.store(0, std::memory_order_relaxed);
    buffer_read.store(0, std::memory_order_relaxed);
    buffer_count.store(0, std::memory_order_relaxed);
    if (audio_buffer)
        memset(audio_buffer, 0, sizeof(float) * buffer_size);
}

// Internal function to push a sample into the circular buffer
void circular_buffer_push_sample(float level) {

    size_t w = buffer_write.load(std::memory_order_relaxed);
    size_t r = buffer_read.load(std::memory_order_acquire);
    size_t next = (w + 1) % buffer_size;

    // Always write the sample
    audio_buffer[w] = level;
    buffer_write.store(next, std::memory_order_release);

    // If buffer was full, discard oldest sample by advancing read pointer
    if (next == r) {
        buffer_read.store((r + 1) % buffer_size, std::memory_order_release);
    }
    else {
        buffer_count++;
    }
}

float circular_buffer_pop_sample() {

    while (buffer_count.load() < buffer_size * 0.7)
        std::this_thread::yield();
    size_t r = buffer_read.load(std::memory_order_relaxed);
    if (buffer_size <= 0)
        return 0.0f;
    buffer_read.store((r + 1) % buffer_size,
        std::memory_order_release);
    buffer_count--;
    return audio_buffer[r];
}