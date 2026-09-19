#pragma once
#include <SDL3/SDL.h>
#include "daScript/daScript.h"

// Copy only the active union member. A mismatch clears output and returns false.
inline bool SDL_ReadKeyEvent(const SDL_Event & event, SDL_KeyboardEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_KEY_DOWN && event.type != SDL_EVENT_KEY_UP) return false;
    out = event.key;
    return true;
}
inline int32_t SDL_KeyScancode(const SDL_KeyboardEvent & key) {
    return static_cast<int32_t>(key.scancode);
}
inline bool SDL_ReadMouseMotionEvent(const SDL_Event & event, SDL_MouseMotionEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_MOUSE_MOTION) return false;
    out = event.motion;
    return true;
}
inline bool SDL_ReadMouseButtonEvent(const SDL_Event & event, SDL_MouseButtonEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_MOUSE_BUTTON_DOWN && event.type != SDL_EVENT_MOUSE_BUTTON_UP) return false;
    out = event.button;
    return true;
}
inline bool SDL_ReadMouseWheelEvent(const SDL_Event & event, SDL_MouseWheelEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_MOUSE_WHEEL) return false;
    out = event.wheel;
    return true;
}
inline bool SDL_MouseWheelFlipped(const SDL_MouseWheelEvent & wheel) {
    return wheel.direction == SDL_MOUSEWHEEL_FLIPPED;
}
inline bool SDL_ReadTextInput(const SDL_Event & event, char * & text,
                              das::Context * context, das::LineInfoArg * at) {
    text = nullptr;
    if (event.type != SDL_EVENT_TEXT_INPUT) return false;
    const char * source = event.text.text;
    if (source) text = context->allocateString(source, uint32_t(SDL_strlen(source)), at);
    return true;
}
inline bool SDL_ReadTextEditing(const SDL_Event & event, char * & text, int32_t & start, int32_t & length,
                                das::Context * context, das::LineInfoArg * at) {
    text = nullptr; start = length = 0;
    if (event.type != SDL_EVENT_TEXT_EDITING) return false;
    const char * source = event.edit.text;
    if (source) text = context->allocateString(source, uint32_t(SDL_strlen(source)), at);
    start = event.edit.start; length = event.edit.length;
    return true;
}
inline uint32_t SDL_InputWindowID(const SDL_Event & event) {
    switch (event.type) {
    case SDL_EVENT_KEY_DOWN: case SDL_EVENT_KEY_UP: return event.key.windowID;
    case SDL_EVENT_TEXT_INPUT: return event.text.windowID;
    case SDL_EVENT_TEXT_EDITING: return event.edit.windowID;
    case SDL_EVENT_MOUSE_MOTION: return event.motion.windowID;
    case SDL_EVENT_MOUSE_BUTTON_DOWN: case SDL_EVENT_MOUSE_BUTTON_UP: return event.button.windowID;
    case SDL_EVENT_MOUSE_WHEEL: return event.wheel.windowID;
    default:
        if (event.type >= SDL_EVENT_WINDOW_FIRST && event.type <= SDL_EVENT_WINDOW_LAST)
            return event.window.windowID;
        return 0;
    }
}
inline bool SDL_IsScancodeDown(int32_t scancode) {
    int count = 0;
    const bool * keys = SDL_GetKeyboardState(&count);
    return keys && scancode >= 0 && scancode < count && keys[scancode];
}
inline uint32_t SDL_GetMouseStateRef(float & x, float & y) {
    return SDL_GetMouseState(&x, &y);
}
