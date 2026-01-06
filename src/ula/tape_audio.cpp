#include "tape_audio.h"

static uint8_t* pulse_buffer = nullptr;

uint8_t tape_audio_read() {
	
	return 0x00;
}

void tape_audio_free_pulse_buffer() {

	if (pulse_buffer != nullptr) {
		delete[] pulse_buffer;
		pulse_buffer = nullptr;
	}
}

void tape_audio_reset_pulse_buffer(size_t new_size) {
	
	tape_audio_free_pulse_buffer();
	pulse_buffer = new uint8_t[new_size];
}

uint8_t* tape_audio_get_pulse_buffer() {

	return pulse_buffer;
}