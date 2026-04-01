#include "keyboard.h"
#include "system_memory.h"

#define ZX_KEYCODE_LSHIFT { 0xFE,0 }
#define ZX_KEYCODE_RSHIFT { 0x7F,1 }
#define ZX_KEYCODE_SPACE { 0x7F,0 }
#define ZX_KEYCODE_RETURN { 0xBF,0 }
#define ZX_KEYCODE_0 { 0xEF,0 }
#define ZX_KEYCODE_1 { 0xF7,0 }
#define ZX_KEYCODE_2 { 0xF7,1 }
#define ZX_KEYCODE_3 { 0xF7,2 }
#define ZX_KEYCODE_4 { 0xF7,3 }
#define ZX_KEYCODE_5 { 0xF7,4 }
#define ZX_KEYCODE_6 { 0xEF,4 }
#define ZX_KEYCODE_7 { 0xEF,3 }
#define ZX_KEYCODE_8 { 0xEF,2 }
#define ZX_KEYCODE_9 { 0xEF,1 }
#define ZX_KEYCODE_A { 0xFD,0 }
#define ZX_KEYCODE_B { 0x7F,4 }
#define ZX_KEYCODE_C { 0xFE,3 }
#define ZX_KEYCODE_D { 0xFD,2 }
#define ZX_KEYCODE_E { 0xFB,2 }
#define ZX_KEYCODE_F { 0xFD,3 }
#define ZX_KEYCODE_G { 0xFD,4 }
#define ZX_KEYCODE_H { 0xBF,4 }
#define ZX_KEYCODE_I { 0xDF,2 }
#define ZX_KEYCODE_J { 0xBF,3 }
#define ZX_KEYCODE_K { 0xBF,2 }
#define ZX_KEYCODE_L { 0xBF,1 }
#define ZX_KEYCODE_M { 0x7F,2 }
#define ZX_KEYCODE_N { 0x7F,3 }
#define ZX_KEYCODE_O { 0xDF,1 }
#define ZX_KEYCODE_P { 0xDF,0 }
#define ZX_KEYCODE_Q { 0xFB,0 }
#define ZX_KEYCODE_R { 0xFB,3 }
#define ZX_KEYCODE_S { 0xFD,1 }
#define ZX_KEYCODE_T { 0xFB,4 }
#define ZX_KEYCODE_U { 0xDF,3 }
#define ZX_KEYCODE_V { 0xFE,4 }
#define ZX_KEYCODE_W { 0xFB,1 }
#define ZX_KEYCODE_X { 0xFE,2 }
#define ZX_KEYCODE_Y { 0xDF,4 }
#define ZX_KEYCODE_Z { 0xFE,1 }

#define EDITOR_MODE_ALL -1
#define EDITOR_MODE_CKL 0
#define EDITOR_MODE_E   1
#define EDITOR_MODE_G   2

struct KeyMapping {
    uint8_t pos;
    uint8_t shift;
};
struct KeyMappingExt {

    std::vector<KeyMapping> key_mapping;
    int editor_mode = EDITOR_MODE_ALL;
    bool shift_mode = false;
    std::vector<KeyMapping> shift_key_mapping;
};

static const std::map<int, KeyMapping> key_mapping_direct = {

    { HOST_KEY_LCONTROL, ZX_KEYCODE_LSHIFT },
    { HOST_KEY_RCONTROL, ZX_KEYCODE_RSHIFT },
    { HOST_KEY_SPACE, ZX_KEYCODE_SPACE },
    { HOST_KEY_RETURN, ZX_KEYCODE_RETURN },
    { HOST_KEY_0, ZX_KEYCODE_0 },
    { HOST_KEY_1, ZX_KEYCODE_1 },
    { HOST_KEY_2, ZX_KEYCODE_2 },
    { HOST_KEY_3, ZX_KEYCODE_3 },
    { HOST_KEY_4, ZX_KEYCODE_4 },
    { HOST_KEY_5, ZX_KEYCODE_5 },
    { HOST_KEY_6, ZX_KEYCODE_6 },
    { HOST_KEY_7, ZX_KEYCODE_7 },
    { HOST_KEY_8, ZX_KEYCODE_8 },
    { HOST_KEY_9, ZX_KEYCODE_9 },
    { HOST_KEY_0, ZX_KEYCODE_0 },
    { HOST_KEY_Q, ZX_KEYCODE_Q },
    { HOST_KEY_W, ZX_KEYCODE_W },
    { HOST_KEY_E, ZX_KEYCODE_E },
    { HOST_KEY_R, ZX_KEYCODE_R },
    { HOST_KEY_T, ZX_KEYCODE_T },
    { HOST_KEY_Y, ZX_KEYCODE_Y },
    { HOST_KEY_U, ZX_KEYCODE_U },
    { HOST_KEY_I, ZX_KEYCODE_I },
    { HOST_KEY_O, ZX_KEYCODE_O },
    { HOST_KEY_P, ZX_KEYCODE_P },
    { HOST_KEY_A, ZX_KEYCODE_A },
    { HOST_KEY_S, ZX_KEYCODE_S },
    { HOST_KEY_D, ZX_KEYCODE_D },
    { HOST_KEY_F, ZX_KEYCODE_F },
    { HOST_KEY_G, ZX_KEYCODE_G },
    { HOST_KEY_H, ZX_KEYCODE_H },
    { HOST_KEY_J, ZX_KEYCODE_J },
    { HOST_KEY_K, ZX_KEYCODE_K },
    { HOST_KEY_L, ZX_KEYCODE_L },
    { HOST_KEY_Z, ZX_KEYCODE_Z },
    { HOST_KEY_X, ZX_KEYCODE_X },
    { HOST_KEY_C, ZX_KEYCODE_C },
    { HOST_KEY_V, ZX_KEYCODE_V },
    { HOST_KEY_B, ZX_KEYCODE_B },
    { HOST_KEY_N, ZX_KEYCODE_N },
    { HOST_KEY_M, ZX_KEYCODE_M }
};

static const std::map<int, KeyMappingExt> key_mapping_extra = {
    {HOST_KEY_BACKSPACE, {{{ZX_KEYCODE_0, ZX_KEYCODE_LSHIFT}}}},
    {HOST_KEY_MINUS, {{{ZX_KEYCODE_J, ZX_KEYCODE_RSHIFT}}, EDITOR_MODE_ALL, true,  {{ZX_KEYCODE_0, ZX_KEYCODE_RSHIFT}}}},
    {HOST_KEY_EQUALS, {{{ZX_KEYCODE_L, ZX_KEYCODE_RSHIFT}}, EDITOR_MODE_ALL, true,  {{ZX_KEYCODE_K, ZX_KEYCODE_RSHIFT}}}},
    {HOST_KEY_SEMICOLON, {{{ZX_KEYCODE_O, ZX_KEYCODE_RSHIFT}}, EDITOR_MODE_ALL, true,  {{ZX_KEYCODE_Z, ZX_KEYCODE_RSHIFT}}}},
    {HOST_KEY_COMMA, {{{ZX_KEYCODE_N, ZX_KEYCODE_RSHIFT}}, EDITOR_MODE_ALL, true,  {{ZX_KEYCODE_R, ZX_KEYCODE_RSHIFT}}}},
    {HOST_KEY_PERIOD, {{{ZX_KEYCODE_M, ZX_KEYCODE_RSHIFT}}, EDITOR_MODE_ALL, true, {{ZX_KEYCODE_T, ZX_KEYCODE_RSHIFT}}}},
    {HOST_KEY_SLASH, {{{ZX_KEYCODE_V, ZX_KEYCODE_RSHIFT}}, EDITOR_MODE_ALL, true, {{ZX_KEYCODE_C, ZX_KEYCODE_RSHIFT}}}},
    {HOST_KEY_BACKSLASH, {{{ZX_KEYCODE_D, ZX_KEYCODE_RSHIFT}}, EDITOR_MODE_E, true,  {{ZX_KEYCODE_S, ZX_KEYCODE_RSHIFT}} }},
    {HOST_KEY_LEFTBRACKET, {{{ZX_KEYCODE_Y, ZX_KEYCODE_RSHIFT}}, EDITOR_MODE_E}},
    {HOST_KEY_RIGHTBRACKET, {{{ZX_KEYCODE_U, ZX_KEYCODE_RSHIFT}}, EDITOR_MODE_E}},
    {HOST_KEY_SINGLE_QUOTE, {{{ZX_KEYCODE_P, ZX_KEYCODE_RSHIFT}}, EDITOR_MODE_ALL, true,  {{ZX_KEYCODE_P, ZX_KEYCODE_RSHIFT}}}},
    {HOST_KEY_GRAVE, {{{ZX_KEYCODE_A, ZX_KEYCODE_RSHIFT}}, EDITOR_MODE_E}},
    {HOST_KEY_LEFT, {{{ZX_KEYCODE_5, ZX_KEYCODE_LSHIFT}}}},
    {HOST_KEY_RIGHT, {{{ZX_KEYCODE_8, ZX_KEYCODE_LSHIFT}}}},
    {HOST_KEY_UP, {{{ZX_KEYCODE_7, ZX_KEYCODE_LSHIFT}}}},
    {HOST_KEY_DOWN, {{{ZX_KEYCODE_6, ZX_KEYCODE_LSHIFT}}}}
};

static UlaKeyboardKeysCallback keyboard_keys_callback = nullptr;
static uint16_t forced_edit_mode_addr = 0xFFFF;

void keyboard_init(UlaKeyboardKeysCallback cb) {
    keyboard_keys_callback = cb;
    keyboard_reset();
}

void keyboard_end() {

    keyboard_keys_callback = nullptr;
}

void keyboard_update_map(const bool* keys, uint8_t key, uint8_t& value) {
    
    value = 0;
    for (auto& [i, k] : key_mapping_direct) {
        if (keys[i] == true && k.pos == key) {
            value |= (uint8_t)(1 << k.shift);
        }
    }
}

void keyboard_update_map_extra(const bool* keys, uint8_t key, uint8_t& value) {

    value = 0;
    for (auto& [i, k] : key_mapping_extra) {
        if (keys[i] == true) {
			if (k.editor_mode == EDITOR_MODE_E) {
                int editor_mode = system_memory_get_system_var_value_8(kMODE);
                if (k.editor_mode != editor_mode) {
                    system_memory_set_system_var_value_8(kMODE, EDITOR_MODE_E);
                    forced_edit_mode_addr = key;
                }
            }
            bool sm =
                (k.shift_mode == true
                    && (keys[SDL_SCANCODE_LSHIFT] == true
                        || keys[SDL_SCANCODE_RSHIFT] == true));
		    auto& km = sm ? k.shift_key_mapping : k.key_mapping;
            for (auto& vk : km) {
                if (vk.pos == key) {
                    value |= (uint8_t)(1 << vk.shift);
				}
            }
            break;
        }
    }
}

uint8_t keyboard_get_map_addr(uint8_t addr) {
    
    const bool* keys = keyboard_get_state();
    
    // process keyboard callbacks
    if (keyboard_keys_callback) {
        if (keyboard_keys_callback(keys)) {
            // reset keyboard
            keyboard_reset();
        }
    }

	// if edit mode was forced and we finished to scan all keyboard lines then reset edit mode
    if (forced_edit_mode_addr == (uint16_t)addr) {
        system_memory_set_system_var_value_8(kMODE, EDITOR_MODE_CKL);
        forced_edit_mode_addr = 0xFFFF;
    }    

	// read pc keyboard that maps directs to zx keyboard 
    uint8_t mapped_value;
    keyboard_update_map(keys, addr, mapped_value);
    if (mapped_value == 0) {
        // read pc keyboard shortcuts that are not directly mapped to the zx keyboard
        keyboard_update_map_extra(keys, addr, mapped_value);
    }
    return (uint8_t)(~mapped_value);
}

void keyboard_tick(uint64_t /*delta_cycles*/) {
}
