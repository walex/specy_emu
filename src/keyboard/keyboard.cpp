#include "keyboard.h"

#include "sdl_keyboard.h"

#include <queue>

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

#define ZX_KEYCODE_LSHIFT { pos = 0xFE; shift = 0; }
#define ZX_KEYCODE_RSHIFT { pos = 0x7F; shift = 1; }
#define ZX_KEYCODE_SPACE { pos = 0x7F; shift = 0; }
#define ZX_KEYCODE_RETURN { pos = 0xBF; shift = 0; }
#define ZX_KEYCODE_0 { pos = 0xEF; shift = 0; }
#define ZX_KEYCODE_1 { pos = 0xF7; shift = 0; }
#define ZX_KEYCODE_2 { pos = 0xF7; shift = 1; }
#define ZX_KEYCODE_3 { pos = 0xF7; shift = 2; }
#define ZX_KEYCODE_4 { pos = 0xF7; shift = 3; }
#define ZX_KEYCODE_5 { pos = 0xF7; shift = 4; }
#define ZX_KEYCODE_6 { pos = 0xEF; shift = 4; }
#define ZX_KEYCODE_7 { pos = 0xEF; shift = 3; }
#define ZX_KEYCODE_8 { pos = 0xEF; shift = 2; }
#define ZX_KEYCODE_9 { pos = 0xEF; shift = 1; }
#define ZX_KEYCODE_A { pos = 0xFD; shift = 0; }
#define ZX_KEYCODE_B { pos = 0x7F; shift = 4; }
#define ZX_KEYCODE_C { pos = 0xFE; shift = 3; }
#define ZX_KEYCODE_D { pos = 0xFD; shift = 2; }
#define ZX_KEYCODE_E { pos = 0xFB; shift = 2; }
#define ZX_KEYCODE_F { pos = 0xFD; shift = 3; }
#define ZX_KEYCODE_G { pos = 0xFD; shift = 4; }
#define ZX_KEYCODE_H { pos = 0xBF; shift = 4; }
#define ZX_KEYCODE_I { pos = 0xDF; shift = 2; }
#define ZX_KEYCODE_J { pos = 0xBF; shift = 3; }
#define ZX_KEYCODE_K { pos = 0xBF; shift = 2; }
#define ZX_KEYCODE_L { pos = 0xBF; shift = 1; }
#define ZX_KEYCODE_M { pos = 0x7F; shift = 2; }
#define ZX_KEYCODE_N { pos = 0x7F; shift = 3; }
#define ZX_KEYCODE_O { pos = 0xDF; shift = 1; }
#define ZX_KEYCODE_P { pos = 0xDF; shift = 0; }
#define ZX_KEYCODE_Q { pos = 0xFB; shift = 0; }
#define ZX_KEYCODE_R { pos = 0xFB; shift = 3; }
#define ZX_KEYCODE_S { pos = 0xFD; shift = 1; }
#define ZX_KEYCODE_T { pos = 0xFB; shift = 4; }
#define ZX_KEYCODE_U { pos = 0xFB; shift = 3; }
#define ZX_KEYCODE_V { pos = 0xFE; shift = 4; }
#define ZX_KEYCODE_W { pos = 0xFB; shift = 1; }
#define ZX_KEYCODE_X { pos = 0xFE; shift = 2; }
#define ZX_KEYCODE_Y { pos = 0xDF; shift = 4; }
#define ZX_KEYCODE_Z { pos = 0xFE; shift = 1; }


#define ZX_KEYCODE_ADD(a) {key = a; q.push(a);}
#define ZX_KEYCODE_OVERRIDE_IF_NOT_MOD(a,b) {if (!(mod & a)) { b; break; }}
#define ZX_KEYCODE_OVERRIDE_IF_MOD(a,b) {if ((mod & a)) { b; break; }}

void evaluate_keyboard_input(uint32_t key, uint16_t mod, bool pressed) {

    std::queue<uint32_t> q;
    uint8_t pos;
    unsigned int shift;

    do {

        switch (key) {

        case HOST_KEY_BACKSPACE:
            ZX_KEYCODE_LSHIFT
            ZX_KEYCODE_ADD(HOST_KEY_0)
            break;
        case HOST_KEY_LSHIFT:
            ZX_KEYCODE_LSHIFT
            break;
        case HOST_KEY_RSHIFT:
            ZX_KEYCODE_RSHIFT
            break;
        case HOST_KEY_SPACE:
            ZX_KEYCODE_SPACE
            break;
        case HOST_KEY_RETURN:
            ZX_KEYCODE_RETURN
            break;
        case HOST_KEY_0:
            ZX_KEYCODE_0
            break;
        case HOST_KEY_EXCLAIM:
            ZX_KEYCODE_ADD(HOST_KEY_LSHIFT)
        case HOST_KEY_1:
            ZX_KEYCODE_1
            break;
        case HOST_KEY_2:
            ZX_KEYCODE_2
            break;
        case HOST_KEY_3:
            ZX_KEYCODE_3
            break;
        case HOST_KEY_4:
            ZX_KEYCODE_4
            break;
        case HOST_KEY_LEFT:
            ZX_KEYCODE_ADD(HOST_KEY_LSHIFT)
        case HOST_KEY_5:
            ZX_KEYCODE_5
            break;
        case HOST_KEY_DOWN:
            ZX_KEYCODE_ADD(HOST_KEY_LSHIFT)
        case HOST_KEY_6:
            ZX_KEYCODE_6
            break;
        case HOST_KEY_UP:
            ZX_KEYCODE_ADD(HOST_KEY_LSHIFT)
        case HOST_KEY_7:
            ZX_KEYCODE_7
            break;
        case HOST_KEY_RIGHT:
            ZX_KEYCODE_ADD(HOST_KEY_LSHIFT)
        case HOST_KEY_8:
            ZX_KEYCODE_8
            break;
        case HOST_KEY_9:
            ZX_KEYCODE_7
            break;
        case HOST_KEY_A:
            ZX_KEYCODE_A
            break;
        case HOST_KEY_B:
            ZX_KEYCODE_B
            break;
        case HOST_KEY_C:
            ZX_KEYCODE_C
            break;
        case HOST_KEY_D:
            ZX_KEYCODE_D
            break;
        case HOST_KEY_E:
            ZX_KEYCODE_E
            break;
        case HOST_KEY_F:
            ZX_KEYCODE_F
            break;
        case HOST_KEY_G:
            ZX_KEYCODE_G
            break;
        case HOST_KEY_H:
            ZX_KEYCODE_H
            break;
        case HOST_KEY_I:
            ZX_KEYCODE_I
            break;
        case HOST_KEY_MINUS:
            ZX_KEYCODE_ADD(HOST_KEY_RSHIFT)
            ZX_KEYCODE_OVERRIDE_IF_MOD(HOST_KEY_MOD_RSHIFT, ZX_KEYCODE_0)
        case HOST_KEY_J:
            ZX_KEYCODE_J
            break;
        case HOST_KEY_EQUALS:
            ZX_KEYCODE_ADD(HOST_KEY_RSHIFT)
            ZX_KEYCODE_OVERRIDE_IF_NOT_MOD(HOST_KEY_MOD_RSHIFT, ZX_KEYCODE_L)
        case HOST_KEY_K:
            ZX_KEYCODE_K
            break;
        case HOST_KEY_L:
            ZX_KEYCODE_L
            break;
        case HOST_KEY_PERIOD:
            ZX_KEYCODE_ADD(HOST_KEY_RSHIFT)
            ZX_KEYCODE_OVERRIDE_IF_MOD(HOST_KEY_MOD_RSHIFT, ZX_KEYCODE_T)
        case HOST_KEY_M:
            ZX_KEYCODE_M
            break;
        case HOST_KEY_COMMA:
            ZX_KEYCODE_ADD(HOST_KEY_RSHIFT)
            ZX_KEYCODE_OVERRIDE_IF_MOD(HOST_KEY_MOD_RSHIFT, ZX_KEYCODE_R)
        case HOST_KEY_N:
            ZX_KEYCODE_N
            break;
        case HOST_KEY_O:
            ZX_KEYCODE_O
            break;
        case HOST_KEY_APOSTROPHE:
            ZX_KEYCODE_ADD(HOST_KEY_RSHIFT)
            ZX_KEYCODE_OVERRIDE_IF_NOT_MOD(HOST_KEY_MOD_RSHIFT, ZX_KEYCODE_7)
        case HOST_KEY_P:
            ZX_KEYCODE_P
            break;
        case HOST_KEY_Q:
            ZX_KEYCODE_Q
            break;
        case HOST_KEY_R:
            ZX_KEYCODE_R
            break;
        case HOST_KEY_S:
            ZX_KEYCODE_S
            break;
        case HOST_KEY_T:
            ZX_KEYCODE_T
            break;
        case HOST_KEY_U:
            ZX_KEYCODE_U
            break;
        case HOST_KEY_SLASH:
            ZX_KEYCODE_ADD(HOST_KEY_RSHIFT)
            ZX_KEYCODE_OVERRIDE_IF_MOD(HOST_KEY_MOD_RSHIFT, ZX_KEYCODE_C)
        case HOST_KEY_V:
            ZX_KEYCODE_V
            break;
        case HOST_KEY_W:
            ZX_KEYCODE_W
            break;
        case HOST_KEY_X:
            ZX_KEYCODE_X
            break;
        case HOST_KEY_LEFTBRACKET:
        case HOST_KEY_RIGHTBRACKET:
            break;
        case HOST_KEY_Y:
            ZX_KEYCODE_Y
            break;
        case HOST_KEY_SEMICOLON:
            ZX_KEYCODE_ADD(HOST_KEY_RSHIFT)
            ZX_KEYCODE_OVERRIDE_IF_NOT_MOD(HOST_KEY_MOD_RSHIFT, ZX_KEYCODE_O)
        case HOST_KEY_Z:
            ZX_KEYCODE_Z
            break;
        default:
            return;
        }

        if ((mod & HOST_KEY_MOD_CAPS) != 0 && (key >= HOST_KEY_A && key <= HOST_KEY_Z)) {

            ZX_KEYCODE_ADD(HOST_KEY_LSHIFT)
        }

        if (pressed)
            keyboard_map[pos] |= (uint8_t)(1 << shift);
        else
            keyboard_map[pos] &= (uint8_t)~(1 << shift);


        if (q.size() > 0) {
            key = q.front();
            q.pop();
        }
        else
            break;

    } while (true);
}

void keyboard_set_input(uint32_t key, uint16_t mod) {

    evaluate_keyboard_input(key, mod, true);
    
}

void keyboard_unset_input(uint32_t key, uint16_t mod) {

    evaluate_keyboard_input(key, mod, false);
}

uint8_t keyboard_get_map_addr(uint8_t addr) {
    if (keyboard_map.find(addr) == keyboard_map.end()) {
        return 0xFF;
	}
    return ~(keyboard_map[addr]);
}
