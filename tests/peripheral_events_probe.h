#pragma once
#include <SDL3/SDL.h>
namespace sdl3_test {
inline SDL_Event peripheral_event(uint32_t type) {
    SDL_Event e{};e.type=type;e.common.timestamp=0xfedcba9876543210ull;
    switch(type) {
    case SDL_EVENT_FINGER_DOWN:
    case SDL_EVENT_FINGER_UP:
    case SDL_EVENT_FINGER_MOTION:
    case SDL_EVENT_FINGER_CANCELED:
        e.tfinger.touchID=0xf123456789abcdefull;
        e.tfinger.fingerID=0xe123456789abcdefull;
        e.tfinger.windowID=42;
        e.tfinger.x=-0.25f;
        e.tfinger.y=1.25f;
        e.tfinger.dx=-0.5f;
        e.tfinger.dy=0.75f;
        e.tfinger.pressure=0.5f;
        break;
    case SDL_EVENT_PEN_PROXIMITY_IN:
    case SDL_EVENT_PEN_PROXIMITY_OUT:
        e.pproximity.windowID=42;
        e.pproximity.which=0xf1234567u;
        break;
    case SDL_EVENT_PEN_MOTION:
        e.pmotion.windowID=42;
        e.pmotion.which=0xf1234567u;
        e.pmotion.pen_state=SDL_PEN_INPUT_DOWN|SDL_PEN_INPUT_ERASER_TIP;
        e.pmotion.x=12.5f;
        e.pmotion.y=-2.5f;
        break;
    case SDL_EVENT_PEN_DOWN:
    case SDL_EVENT_PEN_UP:
        e.ptouch.windowID=42;
        e.ptouch.which=0xf1234567u;
        e.ptouch.pen_state=SDL_PEN_INPUT_ERASER_TIP;
        e.ptouch.x=12.5f;
        e.ptouch.y=-2.5f;
        e.ptouch.eraser=true;
        e.ptouch.down=(type==SDL_EVENT_PEN_DOWN);
        break;
    case SDL_EVENT_PEN_BUTTON_DOWN:
    case SDL_EVENT_PEN_BUTTON_UP:
        e.pbutton.windowID=42;
        e.pbutton.which=0xf1234567u;
        e.pbutton.pen_state=SDL_PEN_INPUT_BUTTON_2;
        e.pbutton.x=12.5f;
        e.pbutton.y=-2.5f;
        e.pbutton.button=2;
        e.pbutton.down=(type==SDL_EVENT_PEN_BUTTON_DOWN);
        break;
    case SDL_EVENT_PEN_AXIS:
        e.paxis.windowID=42;
        e.paxis.which=0xf1234567u;
        e.paxis.pen_state=SDL_PEN_INPUT_DOWN;
        e.paxis.x=12.5f;
        e.paxis.y=-2.5f;
        e.paxis.axis=SDL_PEN_AXIS_XTILT;
        e.paxis.value=-45.0f;
        break;
    case SDL_EVENT_SENSOR_UPDATE:
        e.sensor.which=0xf1234567u;
        e.sensor.data[0]=-1.25f;
        e.sensor.data[1]=2.5f;
        e.sensor.data[2]=3.75f;
        e.sensor.data[3]=-4.0f;
        e.sensor.data[4]=5.0f;
        e.sensor.data[5]=6.5f;
        e.sensor.sensor_timestamp=0x123456789abcdef0ull;
        break;
    default:break;
    }
    return e;
}
}
