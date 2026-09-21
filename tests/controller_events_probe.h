#pragma once
#include <SDL3/SDL.h>
namespace sdl3_test {
inline SDL_Event controller_event(uint32_t type) {
    SDL_Event event{};
    event.type = type;
    event.common.timestamp = 0xfedcba9876543210ull;
    switch (type) {
    case SDL_EVENT_JOYSTICK_AXIS_MOTION:
        event.jaxis.which = 0xf1234567u;
        event.jaxis.axis = 7;
        event.jaxis.value = -32768;
        break;
    case SDL_EVENT_JOYSTICK_BALL_MOTION:
        event.jball.which = 0xf1234567u;
        event.jball.ball = 3;
        event.jball.xrel = -32768;
        event.jball.yrel = 32767;
        break;
    case SDL_EVENT_JOYSTICK_HAT_MOTION:
        event.jhat.which = 0xf1234567u;
        event.jhat.hat = 2;
        event.jhat.value = SDL_HAT_LEFTUP;
        break;
    case SDL_EVENT_JOYSTICK_BUTTON_DOWN:
    case SDL_EVENT_JOYSTICK_BUTTON_UP:
        event.jbutton.which = 0xf1234567u;
        event.jbutton.button = 9;
        event.jbutton.down = (type == SDL_EVENT_JOYSTICK_BUTTON_DOWN);
        break;
    case SDL_EVENT_JOYSTICK_ADDED:
    case SDL_EVENT_JOYSTICK_REMOVED:
    case SDL_EVENT_JOYSTICK_UPDATE_COMPLETE:
        event.jdevice.which = 0xf1234567u;
        break;
    case SDL_EVENT_JOYSTICK_BATTERY_UPDATED:
        event.jbattery.which = 0xf1234567u;
        event.jbattery.state = SDL_POWERSTATE_UNKNOWN;
        event.jbattery.percent = -1;
        break;
    case SDL_EVENT_GAMEPAD_AXIS_MOTION:
        event.gaxis.which = 0xf1234567u;
        event.gaxis.axis = SDL_GAMEPAD_AXIS_RIGHTY;
        event.gaxis.value = -32768;
        break;
    case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
    case SDL_EVENT_GAMEPAD_BUTTON_UP:
        event.gbutton.which = 0xf1234567u;
        event.gbutton.button = SDL_GAMEPAD_BUTTON_EAST;
        event.gbutton.down = (type == SDL_EVENT_GAMEPAD_BUTTON_DOWN);
        break;
    case SDL_EVENT_GAMEPAD_ADDED:
    case SDL_EVENT_GAMEPAD_REMOVED:
    case SDL_EVENT_GAMEPAD_REMAPPED:
    case SDL_EVENT_GAMEPAD_UPDATE_COMPLETE:
    case SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED:
        event.gdevice.which = 0xf1234567u;
        break;
    case SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN:
    case SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION:
    case SDL_EVENT_GAMEPAD_TOUCHPAD_UP:
        event.gtouchpad.which = 0xf1234567u;
        event.gtouchpad.touchpad = 2;
        event.gtouchpad.finger = 3;
        event.gtouchpad.x = 0.25f;
        event.gtouchpad.y = 0.75f;
        event.gtouchpad.pressure = 0.5f;
        break;
    case SDL_EVENT_GAMEPAD_SENSOR_UPDATE:
        event.gsensor.which = 0xf1234567u;
        event.gsensor.sensor = SDL_SENSOR_GYRO;
        event.gsensor.data[0] = -1.25f;
        event.gsensor.data[1] = 2.5f;
        event.gsensor.data[2] = 3.75f;
        event.gsensor.sensor_timestamp = 0x123456789abcdef0ull;
        break;
    default: break;
    }
    return event;
}
}
