#include "audio_render.h"
#include <SDL3/SDL.h>

static SDL_AudioStream* audio_stream;

void audio_render_init(uint32_t sample_rate) {

	SDL_Init(SDL_INIT_AUDIO);
	SDL_AudioSpec spec;
	SDL_zero(spec);
	spec.format = SDL_AUDIO_S16;
	spec.channels = 1;
	spec.freq = sample_rate;
	
	audio_stream = SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, &spec, NULL, NULL);
	if (!audio_stream) {
		SDL_Log("Couldn't create audio stream: %s", SDL_GetError());
		return;
	}
	SDL_ResumeAudioStreamDevice(audio_stream);
}

void audio_render_end() {

	if (audio_stream) {
		SDL_DestroyAudioStream(audio_stream);
		SDL_QuitSubSystem(SDL_INIT_AUDIO);
	}
}

void audio_render_play(uint8_t* buffer, size_t buffer_size) {

	if (SDL_GetAudioStreamQueued(audio_stream) < buffer_size) {

		/* feed the new data to the stream. It will queue at the end, and trickle out as the hardware needs more data. */
		SDL_PutAudioStreamData(audio_stream, buffer, buffer_size);
	}
}

void audio_render_load_wav(const char* filename, uint8_t** out_buffer, size_t* out_size) {
	SDL_AudioSpec wav_spec;
	uint8_t* wav_buffer;
	uint32_t wav_length;
	if (SDL_LoadWAV(filename, &wav_spec, &wav_buffer, &wav_length) == NULL) {
		SDL_Log("Couldn't load WAV file: %s", SDL_GetError());
		*out_buffer = nullptr;
		*out_size = 0;
		return;
	}
	*out_buffer = wav_buffer;
	*out_size = wav_length;
}

void audio_render_free_wav(uint8_t* buffer) {
	SDL_free(buffer);
}