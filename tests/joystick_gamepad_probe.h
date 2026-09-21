#pragma once
#include <SDL3/SDL.h>
namespace sdl3_test {
inline int virtual_cleanup_count=0, virtual_effect_count=0, virtual_rumble_count=0, virtual_led_count=0;
inline bool SDLCALL virtual_rumble(void *,uint16_t a,uint16_t b) {if(a==123 && b==456)++virtual_rumble_count;return true;}
inline bool SDLCALL virtual_led(void *,uint8_t r,uint8_t g,uint8_t b) {if(r==12 && g==34 && b==56)++virtual_led_count;return true;}
inline bool SDLCALL virtual_effect(void *,const void * data,int size) {
    if(size==3 && data && static_cast<const uint8_t *>(data)[0]==42)++virtual_effect_count;
    return true;
}
inline bool SDLCALL virtual_sensors(void *,bool) {return true;}
inline void SDLCALL virtual_cleanup(void *) {++virtual_cleanup_count;}
inline SDL_VirtualJoystickDesc virtual_desc() {
    static const SDL_VirtualJoystickTouchpadDesc pad{2,{0,0,0}};
    static const SDL_VirtualJoystickSensorDesc sensor{SDL_SENSOR_ACCEL,120.0f};
    SDL_VirtualJoystickDesc d{};d.version=sizeof(d);d.type=SDL_JOYSTICK_TYPE_GAMEPAD;
    d.vendor_id=0x1234;d.product_id=0x5678;d.name="dasSDL3 virtual test";
    d.naxes=6;d.nbuttons=16;d.nhats=1;d.nballs=1;d.ntouchpads=1;d.touchpads=&pad;d.nsensors=1;d.sensors=&sensor;
    d.Rumble=virtual_rumble;d.RumbleTriggers=virtual_rumble;d.SetLED=virtual_led;d.SendEffect=virtual_effect;
    d.SetSensorsEnabled=virtual_sensors;d.Cleanup=virtual_cleanup;return d;
}
inline das::int4 virtual_counts() {return {virtual_cleanup_count,virtual_effect_count,virtual_rumble_count,virtual_led_count};}
}
