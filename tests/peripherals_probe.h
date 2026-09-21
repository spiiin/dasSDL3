#pragma once
#include <SDL3/SDL.h>
namespace sdl3_test {
inline wchar_t hid_name[] = L"\u65e5\u672c \U0001f30d";
inline char hid_path[] = "test://owned-path";
inline SDL_hid_device_info hid_info{};
inline SDL_hid_device_info * peripheral_hid_info() {
    hid_info={};hid_info.path=hid_path;hid_info.serial_number=hid_name;
    hid_info.manufacturer_string=hid_name;hid_info.product_string=hid_name;
    hid_info.vendor_id=0xabcd;hid_info.product_id=0x1234;hid_info.release_number=0x2345;
    hid_info.usage_page=0xff00;hid_info.usage=7;hid_info.interface_number=-1;
    hid_info.interface_class=3;hid_info.interface_subclass=1;hid_info.interface_protocol=2;
    hid_info.bus_type=SDL_HID_API_BUS_USB;return &hid_info;
}
inline void mutate_hid_info() {hid_name[0]=L'X';hid_path[0]='X';}
inline int haptic_payload(const SDL_HapticEffect & e) {
    switch(e.type) {
    case SDL_HAPTIC_CONSTANT:return e.constant.level;
    case SDL_HAPTIC_SINE:return e.periodic.offset;
    case SDL_HAPTIC_SPRING:return e.condition.center[2];
    case SDL_HAPTIC_RAMP:return e.ramp.start;
    case SDL_HAPTIC_LEFTRIGHT:return e.leftright.large_magnitude;
    case SDL_HAPTIC_CUSTOM:return e.custom.samples;
    default:return 0;
    }
}
}
