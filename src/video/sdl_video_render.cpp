#include "video_render.h"
#include "keyboard.h"
#include <SDL3/SDL.h>

#define MAIN_WINDOW_NAME "Specy Emulator"
#define ON_DIALOG_OK() { \
    auto callback_ptr = static_cast<file_dialog_func_ptr*>(userdata); \
    if (callback_ptr) { \
        if (*callback_ptr) { \
            (*callback_ptr)(filelist); \
        } \
        delete callback_ptr; \
    } \
}

enum SDL_EventTypeExt {
SDL_EVENT_MESSAGE_BOX = SDL_EVENT_USER + 1,
SDL_EVENT_OPEN_FILE_DIALOG = SDL_EVENT_USER + 2,
SDL_EVENT_SAVE_FILE_DIALOG = SDL_EVENT_USER + 3
};

 /* We will use this renderer to draw into this window every frame. */
static SDL_Window* window = nullptr;
static SDL_Renderer* renderer = nullptr;
static SDL_Texture* texture = nullptr;
static uint32_t* display_buffer_ptr = nullptr;
static size_t display_buffer_width = 0;
static size_t display_buffer_height = 0;
static size_t window_size_width = 0;
static size_t window_size_height = 0;
static uint64_t window_id = 0;

/* This function runs once at startup. */
SDL_AppResult SDL_AppInit(void** /*appstate*/, int /*argc*/, char* /*argv[]*/ )
{
    SDL_SetAppMetadata("Example Renderer Streaming Textures", "1.0", "com.example.renderer-streaming-textures");

    if (!SDL_InitSubSystem(SDL_INIT_VIDEO)) {
        SDL_Log("Couldn't initialize SDL: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    if (!SDL_CreateWindowAndRenderer(MAIN_WINDOW_NAME, (int)window_size_width, (int)window_size_height, SDL_WINDOW_RESIZABLE, &window, &renderer)) {
        SDL_Log("Couldn't create window/renderer: %s", SDL_GetError());
        return SDL_APP_FAILURE;
    }

    window_id = (uint64_t)SDL_GetWindowID(window);

    SDL_SetRenderLogicalPresentation(renderer, (int)window_size_width, (int)window_size_height, SDL_LOGICAL_PRESENTATION_STRETCH);

    texture = SDL_CreateTexture(renderer, SDL_PIXELFORMAT_XRGB8888, SDL_TEXTUREACCESS_STREAMING, (int)display_buffer_width, (int)display_buffer_height);
    if (!texture) {
        SDL_Log("Couldn't create streaming texture: %s", SDL_GetError());
        return SDL_APP_FAILURE;
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

    if (renderer) {
        SDL_DestroyRenderer(renderer);
        renderer = nullptr;
    }

    if (window) {
        SDL_DestroyWindow(window);
        window = nullptr;
    }

    SDL_QuitSubSystem(SDL_INIT_VIDEO);
}

bool video_render_process() {

    SDL_Event event;
    while (SDL_PollEvent(&event)) {
        if (event.type == SDL_EVENT_QUIT) {
            return false;
        } else if (event.type == SDL_EVENT_MESSAGE_BOX) {
            
            SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_INFORMATION, (const char*)event.user.data1, (const char*)event.user.data2, window);
            delete[] (char*)event.user.data1;
            delete[] (char*)event.user.data2;
        }
        else if (event.type == SDL_EVENT_OPEN_FILE_DIALOG) {

            SDL_ShowOpenFileDialog(
                [](void* userdata, const char* const* filelist, int /*filter*/) {

                    ON_DIALOG_OK();
                },
                event.user.data1, nullptr, nullptr, 0, nullptr, false);
        }
        else if (event.type == SDL_EVENT_SAVE_FILE_DIALOG) {
                       
            SDL_ShowSaveFileDialog([](void* userdata, const char* const* filelist, int /*filter*/) {

                    ON_DIALOG_OK();
                },
                event.user.data1, nullptr, nullptr, 0, nullptr);
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

uint64_t video_render_get_window_id() {
    return (uint64_t)window_id;
}

void* video_render_get_window() {
    return (void*)window;
}

void video_render_show_message(const char* title, const char* message) {
    
    const size_t len_title = strlen(title) + 1;
    const size_t len_message = strlen(message) + 1;
    SDL_Event evt;
    evt.type = SDL_EVENT_MESSAGE_BOX;
    evt.user.data1 = new char[len_title];
    evt.user.data2 = new char[len_message];
	strcpy_s((char*)evt.user.data1, len_title, title);
    strcpy_s((char*)evt.user.data2, len_message, message);
	SDL_PushEvent(&evt);
}

void video_render_open_file_dialog(file_dialog_func_ptr callback) {

    SDL_Event evt;
    evt.type = SDL_EVENT_OPEN_FILE_DIALOG;
    // allocate a copy of the std::function on the heap and pass its pointer through userdata
    evt.user.data1 = static_cast<void*>(new file_dialog_func_ptr(callback));
    evt.user.data2 = nullptr;
    SDL_PushEvent(&evt);
}

void video_render_save_file_dialog(file_dialog_func_ptr callback) {

    SDL_Event evt;
    evt.type = SDL_EVENT_SAVE_FILE_DIALOG;
    // allocate a copy of the std::function on the heap and pass its pointer through userdata
    evt.user.data1 = static_cast<void*>(new file_dialog_func_ptr(callback));
    evt.user.data2 = nullptr;
    SDL_PushEvent(&evt);
}