#include "keyboard.h"

#include <SDL3/SDL_keycode.h>

std::map<uint8_t, uint8_t> keyboard_map = {
{0xFE, 0},
{0xFD, 0},
{0xFB, 0},
{0xF7, 0},
{0xEF, 0},
{0xDF, 0},
{0xBF, 0},
{0x7F, 0}
};

bool evaluate_keyboard_input(uint32_t key, uint8_t& pos, unsigned int& shift) {

    switch (key) {

    case SDLK_LSHIFT:
    case SDLK_RSHIFT:
        pos = 0xFE;
        shift = 0;
        break;
    case SDLK_LCTRL:
    case SDLK_RCTRL:
        pos = 0x7F;
        shift = 1;
        break;
    case SDLK_SPACE:
        pos = 0x7F;
        shift = 0;
        break;
    case SDLK_RETURN:
        pos = 0xBF;
        shift = 0;
        break;
    case SDLK_0:
        pos = 0xEF;
        shift = 0;
        break;
    case SDLK_1:
        pos = 0xF7;
        shift = 0;
        break;
    case SDLK_2:
        pos = 0xF7;
        shift = 1;
        break;
    case SDLK_3:
        pos = 0xF7;
        shift = 2;
        break;
    case SDLK_4:
        pos = 0xF7;
        shift = 3;
        break;
    case SDLK_5:
        pos = 0xF7;
        shift = 4;
        break;
    case SDLK_6:
        pos = 0xEF;
        shift = 4;
        break;
    case SDLK_7:
        pos = 0xEF;
        shift = 3;
        break;
    case SDLK_8:
        pos = 0xEF;
        shift = 2;
        break;
    case SDLK_9:
        pos = 0xEF;
        shift = 1;
        break;
    case SDLK_A:
        pos = 0xFD;
        shift = 0;
        break;
    case SDLK_B:
        pos = 0x7F;
        shift = 4;
        break;
    case SDLK_C:
        pos = 0xFE;
        shift = 3;
        break;
    case SDLK_D:
        pos = 0xFD;
        shift = 2;
        break;
    case SDLK_E:
        pos = 0xFB;
        shift = 2;
        break;
    case SDLK_F:
        pos = 0xFD;
        shift = 3;
        break;
    case SDLK_G:
        pos = 0xFD;
        shift = 4;
        break;
    case SDLK_H:
        pos = 0xBF;
        shift = 4;
        break;
    case SDLK_I:
        pos = 0xDF;
        shift = 2;
        break;
    case SDLK_J:
        pos = 0xBF;
        shift = 3;
        break;
    case SDLK_K:
        pos = 0xBF;
        shift = 2;
        break;
    case SDLK_L:
        pos = 0xBF;
        shift = 1;
        break;
    case SDLK_M:
        pos = 0x7F;
        shift = 2;
        break;
    case SDLK_N:
        pos = 0x7F;
        shift = 3;
        break;
    case SDLK_O:
        pos = 0xDF;
        shift = 1;
        break;
    case SDLK_P:
        pos = 0xDF;
        shift = 0;
        break;
    case SDLK_Q:
        pos = 0xFB;
        shift = 0;
        break;
    case SDLK_R:
        pos = 0xFB;
        shift = 3;
        break;
    case SDLK_S:
        pos = 0xFD;
        shift = 1;
        break;
    case SDLK_T:
        pos = 0xFB;
        shift = 4;
        break;
    case SDLK_U:
        pos = 0xFB;
        shift = 3;
        break;
    case SDLK_V:
        pos = 0xFE;
        shift = 4;
        break;
    case SDLK_W:
        pos = 0xFB;
        shift = 1;
        break;
    case SDLK_X:
        pos = 0xFE;
        shift = 2;
        break;
    case SDLK_Y:
        pos = 0xDF;
        shift = 4;
        break;
    case SDLK_Z:
        pos = 0xFE;
        shift = 1;
        break;
    default:
        return false;
    }

    return true;
}

void keyboard_set_input(uint32_t key) {

    uint8_t pos;
    unsigned int shift;
    
    evaluate_keyboard_input(key, pos, shift);
    keyboard_map[pos] |= (uint8_t)(1 << shift);
}

void keyboard_unset_input(uint32_t key) {

    uint8_t pos;
    unsigned int shift;

    evaluate_keyboard_input(key, pos, shift);
	keyboard_map[pos] &= (uint8_t)~(1 << shift);
}

uint8_t keyboard_get_map_addr(uint8_t addr) {
    if (keyboard_map.find(addr) == keyboard_map.end()) {
        return 0xFF;
	}
    return ~(keyboard_map[addr]);
}
