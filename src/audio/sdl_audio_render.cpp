#include "audio_render.h"
#include <SDL3/SDL.h>

static SDL_AudioStream* audio_stream;
static audio_render_callback user_callback = nullptr;
static uint8_t buffer[1024];

void audio_cb(void* userdata, SDL_AudioStream* stream, int additional_amount, int /*total_amount*/) {
	
	if (user_callback) {
		user_callback((uint8_t*)userdata, additional_amount);
		SDL_PutAudioStreamData(stream, buffer, additional_amount);
	}
}

void audio_render_init(uint32_t sample_rate, audio_render_callback cb) {

	SDL_Init(SDL_INIT_AUDIO);
	SDL_AudioSpec spec;
	SDL_zero(spec);
	spec.format = SDL_AUDIO_S16;
	spec.channels = 1;
	spec.freq = sample_rate;
	user_callback = cb;

	audio_stream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, NULL, NULL);
	if (!audio_stream) {
		SDL_Log("Couldn't create audio stream: %s", SDL_GetError());
		return;
	}
	if (cb != nullptr)
		SDL_SetAudioStreamGetCallback(audio_stream, audio_cb, buffer);
	SDL_ResumeAudioStreamDevice(audio_stream);
}

void audio_render_end() {

	if (audio_stream) {
		SDL_DestroyAudioStream(audio_stream);
		SDL_QuitSubSystem(SDL_INIT_AUDIO);
	}
}

void audio_render_play(uint8_t* buff, size_t buffer_size) {

	SDL_PutAudioStreamData(audio_stream, buff, (int)buffer_size);
}

void audio_render_load_wav(const char* filename, uint8_t** out_buffer, size_t& out_size, int& freq) {
	SDL_AudioSpec wav_spec;
	uint8_t* wav_buffer;
	uint32_t wav_length;
	if (SDL_LoadWAV(filename, &wav_spec, &wav_buffer, &wav_length) == NULL) {
		SDL_Log("Couldn't load WAV file: %s", SDL_GetError());
		*out_buffer = nullptr;
		out_size = 0;
		freq = 0;
		return;
	}
	*out_buffer = wav_buffer;
	out_size = wav_length;
	freq = wav_spec.freq;
}

void audio_render_free_wav(uint8_t* buff) {
	SDL_free(buff);
}