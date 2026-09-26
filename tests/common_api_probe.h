#pragma once
#include <SDL3/SDL.h>
inline bool SDLTestOpenURLNull() {return SDL_OpenURL(nullptr);}
inline char * SDLTestGUIDBuffer() {static thread_local char text[33]{};return text;}
inline SDL_Event SDLTestCommonEvent(uint32_t type) {
    SDL_Event event{}; event.type=type;event.common.timestamp=0xfedcba9876543210ULL;
    switch(type) {
    case SDL_EVENT_DISPLAY_ORIENTATION:
    case SDL_EVENT_DISPLAY_ADDED:
    case SDL_EVENT_DISPLAY_REMOVED:
    case SDL_EVENT_DISPLAY_MOVED:
    case SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED:
    case SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED:
    case SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED:
    case SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED:
        event.display.displayID=0xf1234567u;event.display.data1=-123;event.display.data2=456;break;
    case SDL_EVENT_RENDER_TARGETS_RESET:
    case SDL_EVENT_RENDER_DEVICE_RESET:
    case SDL_EVENT_RENDER_DEVICE_LOST:
        event.render.windowID=0xf1234567u;break;
    case SDL_EVENT_PINCH_BEGIN:
    case SDL_EVENT_PINCH_UPDATE:
    case SDL_EVENT_PINCH_END:
        event.pinch.windowID=0xf1234567u;event.pinch.scale=0.75f;break;
    default:break;
    }
    return event;
}
