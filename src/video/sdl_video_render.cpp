#include "video_render.h"
#include "keyboard.h"
#include <SDL3/SDL.h>

 /* We will use this renderer to draw into this window every frame. */
static SDL_Window* window = NULL;
static SDL_Renderer* renderer = NULL;
static SDL_Texture* texture = NULL;
static uint32_t* display_buffer_ptr = nullptr;
static size_t display_buffer_width = 0;
static size_t display_buffer_height = 0;
static size_t window_size_width = 0;
static size_t window_size_height = 0;

/* This function runs once at startup. */
SDL_AppResult SDL_AppInit(void** /*appstate*/, int /*argc*/, char* /*argv[]*/ )
{
    SDL_SetAppMetadata("Example Renderer Streaming Textures", "1.0", "com.example.renderer-streaming-textures");

    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_CreateWindowAndRenderer("spectrum render", (int)window_size_width, (int)window_size_height, SDL_WINDOW_RESIZABLE, &window, &renderer)) {
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    SDL_SetRenderLogicalPresentation(renderer, (int)window_size_width, (int)window_size_height, SDL_LOGICAL_PRESENTATION_STRETCH);

    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_XRGB8888, SDL_TEXTUREACCESS_STREAMING, (int)display_buffer_width, (int)display_buffer_height);
    if (!texture) {
        SDL_Log("Couldn't create streaming texture: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    return SDL_APP_CONTINUE;  /* carry on with the program! */
}

/* This function runs when a new event (mouse input, keypresses, etc) occurs. */
SDL_AppResult SDL_AppEvent(void* /*appstate*/, SDL_Event* event)
{
    if (event->type == SDL_EVENT_QUIT) {
        return SDL_APP_SUCCESS;  /* end the program, reporting success to the OS. */
    }
    return SDL_APP_CONTINUE;  /* carry on with the program! */
}

/* This function runs once per frame, and is the heart of the program. */
SDL_AppResult SDL_AppIterate(void* /*appstate*/)
{
    void* pixels = NULL;
	int pitch = 0;
    if (SDL_LockTexture(texture, NULL, &pixels, &pitch)) {
       
		std::memcpy(pixels, display_buffer_ptr, pitch * display_buffer_height);
        SDL_UnlockTexture(texture);  /* upload the changes (and frees the temporary surface)! */
    }
    
	SDL_RenderClear(renderer);    
    SDL_RenderTexture(renderer, texture, nullptr, nullptr);
    SDL_RenderPresent(renderer);  /* put it all on the screen! */

    return SDL_APP_CONTINUE;  /* carry on with the program! */
}

/* This function runs once at shutdown. */
void SDL_AppQuit(void* /*appstate*/, SDL_AppResult /*result*/)
{
    SDL_DestroyTexture(texture);
    /* SDL will clean up the window/renderer for us. */
}

bool video_render_process() {

    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_EVENT_QUIT) {
            return false;
        }
    }

    SDL_AppIterate(nullptr);
    return true;
}

void video_render_init(uint32_t* display_buffer, size_t buffer_size_x,
    size_t buffer_size_y, size_t window_size_x, size_t window_size_y) {
    
    display_buffer_ptr = display_buffer;
	display_buffer_width = buffer_size_x;
	display_buffer_height = buffer_size_y;
    window_size_width = window_size_x;
    window_size_height = window_size_y;
    SDL_AppInit(nullptr, 0, nullptr);
}

void video_render_end() {

    SDL_AppQuit(nullptr, SDL_APP_SUCCESS);
}
