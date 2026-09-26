#pragma once
#include <SDL3/SDL.h>
inline SDL_Event SDLTestHotplugEvent(uint32_t type) {
    SDL_Event event{};
    switch(type) {
    case SDL_EVENT_KEYBOARD_ADDED:
    case SDL_EVENT_KEYBOARD_REMOVED:
        event.kdevice.type=static_cast<SDL_EventType>(type); event.kdevice.timestamp=0xfedcba9876543210ULL; event.kdevice.which=0xf1234567u;
        break;
    case SDL_EVENT_MOUSE_ADDED:
    case SDL_EVENT_MOUSE_REMOVED:
        event.mdevice.type=static_cast<SDL_EventType>(type); event.mdevice.timestamp=0xfedcba9876543210ULL; event.mdevice.which=0xf1234567u;
        break;
    case SDL_EVENT_AUDIO_DEVICE_ADDED:
    case SDL_EVENT_AUDIO_DEVICE_REMOVED:
    case SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED:
        event.adevice.type=static_cast<SDL_EventType>(type); event.adevice.timestamp=0xfedcba9876543210ULL; event.adevice.which=0xf1234567u;
        event.adevice.recording=true;
        break;
    case SDL_EVENT_CAMERA_DEVICE_ADDED:
    case SDL_EVENT_CAMERA_DEVICE_REMOVED:
    case SDL_EVENT_CAMERA_DEVICE_APPROVED:
    case SDL_EVENT_CAMERA_DEVICE_DENIED:
        event.cdevice.type=static_cast<SDL_EventType>(type); event.cdevice.timestamp=0xfedcba9876543210ULL; event.cdevice.which=0xf1234567u;
        break;
    default: event.type=type; break;
    }
    return event;
}
