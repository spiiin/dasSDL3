#pragma once
// Only compiled into test builds. Static text storage stays alive while queued;
// mutating it after decoding proves that script text is an independent copy.
namespace sdl3_test {
inline char input_text[64] = u8"\u041f\u0440\u0438\u0432\u0435\u0442 \U0001f30d";
inline char editing_text[64] = u8"\u65e5\u672c";
inline void mutate_input_text() {
    SDL_strlcpy(input_text, "changed", sizeof(input_text));
    SDL_strlcpy(editing_text, "changed", sizeof(editing_text));
}
inline SDL_Event input_event(uint32_t type, uint32_t window_id) {
    SDL_Event event{};
    event.type = type;
    event.common.timestamp = 0xfedcba9876543210ull;
    switch (type) {
    case SDL_EVENT_KEY_DOWN: case SDL_EVENT_KEY_UP:
        event.key.windowID = window_id; event.key.which = 4242;
        event.key.scancode = SDL_SCANCODE_A; event.key.key = SDLK_A;
        event.key.mod = SDL_KMOD_CTRL; event.key.raw = 30;
        event.key.down = type == SDL_EVENT_KEY_DOWN; event.key.repeat = event.key.down;
        break;
    case SDL_EVENT_MOUSE_MOTION:
        event.motion.windowID = window_id; event.motion.which = 4242;
        event.motion.state = SDL_BUTTON_LMASK;
        event.motion.x = 12.5f; event.motion.y = 24.5f;
        event.motion.xrel = -2.0f; event.motion.yrel = 3.0f;
        break;
    case SDL_EVENT_MOUSE_BUTTON_DOWN: case SDL_EVENT_MOUSE_BUTTON_UP:
        event.button.windowID = window_id; event.button.which = 4242;
        event.button.button = SDL_BUTTON_LEFT; event.button.clicks = 2;
        event.button.down = type == SDL_EVENT_MOUSE_BUTTON_DOWN;
        event.button.x = 12.5f; event.button.y = 24.5f;
        break;
    case SDL_EVENT_MOUSE_WHEEL:
        event.wheel.windowID = window_id; event.wheel.which = 4242;
        event.wheel.x = 1.5f; event.wheel.y = -2.5f;
        event.wheel.direction = SDL_MOUSEWHEEL_FLIPPED;
        event.wheel.mouse_x = 12.5f; event.wheel.mouse_y = 24.5f;
        event.wheel.integer_x = 1; event.wheel.integer_y = -2;
        break;
    case SDL_EVENT_TEXT_INPUT:
        event.text.windowID = window_id; event.text.text = input_text;
        break;
    case SDL_EVENT_TEXT_EDITING:
        event.edit.windowID = window_id; event.edit.text = editing_text;
        event.edit.start = 1; event.edit.length = 1;
        break;
    case SDL_EVENT_WINDOW_CLOSE_REQUESTED:
        event.window.windowID = window_id;
        event.window.data1 = -17; event.window.data2 = 29;
        break;
    default: break;
    }
    return event;
}
inline SDL_Event poison_event() {
    SDL_Event event{};
    event.text.text = reinterpret_cast<const char *>(uintptr_t(1));
    event.type = SDL_EVENT_QUIT;
    return event;
}
}
