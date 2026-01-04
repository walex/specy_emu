#include "render.h"
#include "keyboard.h"
#include <thread>
#include <mutex>

/*
 * This example creates an SDL window and renderer, and then draws a streaming
 * texture to it every frame.
 *
 * This code is public domain. Feel free to use it for any purpose!
 */

//#define SDL_MAIN_USE_CALLBACKS 0  /* use the callbacks instead of main() */
#include <SDL3/SDL.h>
//#include <SDL3/SDL_main.h>


 /* We will use this renderer to draw into this window every frame. */
static SDL_Window* window = NULL;
static SDL_Renderer* renderer = NULL;
static SDL_Texture* texture = NULL;
static std::mutex render_mutex;
static std::condition_variable render_signal;
static std::thread render_thread;
static std::atomic<int> render_running{ 0 };
static unsigned long* display_buffer_ptr = nullptr;
static size_t display_buffer_width = 0;
static size_t display_buffer_height = 0;
static size_t window_size_width = 0;
static size_t window_size_height = 0;
static size_t display_width = 0;
static size_t display_height = 0;
Uint32 border_color = 0xFFFFFFFF;

/* This function runs once at startup. */
SDL_AppResult SDL_AppInit(void** appstate, int argc, char* argv[])
{
    SDL_SetAppMetadata("Example Renderer Streaming Textures", "1.0", "com.example.renderer-streaming-textures");

    if (!SDL_Init(SDL_INIT_VIDEO)) {
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_CreateWindowAndRenderer("spectrum render", window_size_width, window_size_height, SDL_WINDOW_RESIZABLE, &window, &renderer)) {
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }
    SDL_SetRenderLogicalPresentation(renderer, window_size_width, window_size_height, SDL_LOGICAL_PRESENTATION_STRETCH);

    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_XRGB8888, SDL_TEXTUREACCESS_STREAMING, display_buffer_width, display_buffer_height);
    if (!texture) {
        SDL_Log("Couldn't create streaming texture: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    return SDL_APP_CONTINUE;  /* carry on with the program! */
}

/* This function runs when a new event (mouse input, keypresses, etc) occurs. */
SDL_AppResult SDL_AppEvent(void* appstate, SDL_Event* event)
{
    if (event->type == SDL_EVENT_QUIT) {
        return SDL_APP_SUCCESS;  /* end the program, reporting success to the OS. */
    }
    return SDL_APP_CONTINUE;  /* carry on with the program! */
}

/* This function runs once per frame, and is the heart of the program. */
SDL_AppResult SDL_AppIterate(void* appstate)
{
    SDL_Surface* surface = NULL;
    void* pixels = NULL;
	int pitch = 0;
    if (SDL_LockTexture(texture, NULL, &pixels, &pitch)) {
       
		std::memcpy(pixels, display_buffer_ptr, pitch * display_buffer_height);
        SDL_UnlockTexture(texture);  /* upload the changes (and frees the temporary surface)! */
    }
    
	Uint8 r = (border_color & 0x00FF0000) >> 16;
	Uint8 g = (border_color & 0x0000FF00) >> 8;
	Uint8 b = (border_color & 0x000000FF);
    SDL_FRect dst_rect;

    SDL_SetRenderDrawColor(renderer, r, g, b, 0);
    SDL_RenderClear(renderer);
    
    float w_factor = (float)display_buffer_width / (float)display_width;
    float h_factor = (float)display_buffer_height / (float)display_height;
	float text_size_w = ((float)window_size_width) * w_factor;
	float text_size_h = ((float)window_size_height) * h_factor;

    dst_rect.x = (((float)window_size_width) - text_size_w) / 2.0f;
    dst_rect.y = (((float)window_size_height) - text_size_h) / 2.0f;
    dst_rect.w = text_size_w;
	dst_rect.h = text_size_h;
    SDL_RenderTexture(renderer, texture, NULL, &dst_rect);
    SDL_RenderPresent(renderer);  /* put it all on the screen! */

    return SDL_APP_CONTINUE;  /* carry on with the program! */
}

/* This function runs once at shutdown. */
void SDL_AppQuit(void* appstate, SDL_AppResult result)
{
    SDL_DestroyTexture(texture);
    /* SDL will clean up the window/renderer for us. */
}

void render_thread_proc() {

    SDL_AppInit(nullptr, 0, nullptr);
    render_running++;
    while (true) {

        std::unique_lock lk(render_mutex);
        render_signal.wait(lk);
        if (render_running.load() == 0)
            break;
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT) {
                break;
            }
            else if (event.type == SDL_EVENT_KEY_DOWN) {
                keyboard_set_input(event.key.key);
            }
            else if (event.type == SDL_EVENT_KEY_UP) {
                keyboard_unset_input(event.key.key);
            }

        }
        
		SDL_AppIterate(nullptr);
    }
	SDL_AppQuit(nullptr, SDL_APP_SUCCESS);
}

void render_init(unsigned long* display_buffer, size_t buffer_size_x,
    size_t buffer_size_y, size_t display_size_x, size_t display_size_y,
    size_t window_size_x, size_t window_size_y) {
    
    if (render_running.load() != 0)
        return;
    display_buffer_ptr = display_buffer;
	display_buffer_width = buffer_size_x;
	display_buffer_height = buffer_size_y;
    display_width = display_size_x;
    display_height = display_size_y;
    window_size_width = window_size_x;
    window_size_height = window_size_y;
    render_thread = std::thread(render_thread_proc);
    while (render_running.load() == 0)
        std::this_thread::sleep_for(std::chrono::microseconds(1));
}

void render_end() {

    if (render_running.load() == 0)
        return;
    {
        std::lock_guard lk(render_mutex);
        render_running = 0;
        render_signal.notify_one();
    }
    if (render_thread.joinable())
        render_thread.join();
}

void render_draw() {
    {
        std::lock_guard lk(render_mutex);
        render_signal.notify_one();
    }
}

void render_set_border_color(uint32_t color) {
    border_color = color;
}