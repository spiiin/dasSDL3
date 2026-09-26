#pragma once
#include <SDL3/SDL.h>

// Active-member copies only; a mismatched tag clears output.
inline bool SDL_ReadJoyAxisEvent(const SDL_Event & event, SDL_JoyAxisEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_JOYSTICK_AXIS_MOTION) return false;
    out = event.jaxis;
    return true;
}
inline bool SDL_ReadJoyBallEvent(const SDL_Event & event, SDL_JoyBallEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_JOYSTICK_BALL_MOTION) return false;
    out = event.jball;
    return true;
}
inline bool SDL_ReadJoyHatEvent(const SDL_Event & event, SDL_JoyHatEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_JOYSTICK_HAT_MOTION) return false;
    out = event.jhat;
    return true;
}
inline bool SDL_ReadJoyButtonEvent(const SDL_Event & event, SDL_JoyButtonEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_JOYSTICK_BUTTON_DOWN && event.type != SDL_EVENT_JOYSTICK_BUTTON_UP) return false;
    out = event.jbutton;
    return true;
}
inline bool SDL_ReadJoyDeviceEvent(const SDL_Event & event, SDL_JoyDeviceEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_JOYSTICK_ADDED && event.type != SDL_EVENT_JOYSTICK_REMOVED && event.type != SDL_EVENT_JOYSTICK_UPDATE_COMPLETE) return false;
    out = event.jdevice;
    return true;
}
inline bool SDL_ReadJoyBatteryEvent(const SDL_Event & event, SDL_JoyBatteryEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_JOYSTICK_BATTERY_UPDATED) return false;
    out = event.jbattery;
    return true;
}
inline bool SDL_ReadGamepadAxisEvent(const SDL_Event & event, SDL_GamepadAxisEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_GAMEPAD_AXIS_MOTION) return false;
    out = event.gaxis;
    return true;
}
inline bool SDL_ReadGamepadButtonEvent(const SDL_Event & event, SDL_GamepadButtonEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_GAMEPAD_BUTTON_DOWN && event.type != SDL_EVENT_GAMEPAD_BUTTON_UP) return false;
    out = event.gbutton;
    return true;
}
inline bool SDL_ReadGamepadDeviceEvent(const SDL_Event & event, SDL_GamepadDeviceEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_GAMEPAD_ADDED && event.type != SDL_EVENT_GAMEPAD_REMOVED && event.type != SDL_EVENT_GAMEPAD_REMAPPED && event.type != SDL_EVENT_GAMEPAD_UPDATE_COMPLETE && event.type != SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED) return false;
    out = event.gdevice;
    return true;
}
inline bool SDL_ReadGamepadTouchpadEvent(const SDL_Event & event, SDL_GamepadTouchpadEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN && event.type != SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION && event.type != SDL_EVENT_GAMEPAD_TOUCHPAD_UP) return false;
    out = event.gtouchpad;
    return true;
}
inline bool SDL_ReadGamepadSensorEvent(const SDL_Event & event, SDL_GamepadSensorEvent & out) {
    out = {};
    if (event.type != SDL_EVENT_GAMEPAD_SENSOR_UPDATE) return false;
    out = event.gsensor;
    return true;
}

// Touch, pen and standalone sensor active union copies.
inline bool SDL_ReadTouchFingerEvent(const SDL_Event & event,SDL_TouchFingerEvent & out) {
    out={};
    if (event.type!=SDL_EVENT_FINGER_DOWN && event.type!=SDL_EVENT_FINGER_UP && event.type!=SDL_EVENT_FINGER_MOTION && event.type!=SDL_EVENT_FINGER_CANCELED)return false;
    out=event.tfinger;return true;
}
inline bool SDL_ReadPenProximityEvent(const SDL_Event & event,SDL_PenProximityEvent & out) {
    out={};
    if (event.type!=SDL_EVENT_PEN_PROXIMITY_IN && event.type!=SDL_EVENT_PEN_PROXIMITY_OUT)return false;
    out=event.pproximity;return true;
}
inline bool SDL_ReadPenMotionEvent(const SDL_Event & event,SDL_PenMotionEvent & out) {
    out={};
    if (event.type!=SDL_EVENT_PEN_MOTION)return false;
    out=event.pmotion;return true;
}
inline bool SDL_ReadPenTouchEvent(const SDL_Event & event,SDL_PenTouchEvent & out) {
    out={};
    if (event.type!=SDL_EVENT_PEN_DOWN && event.type!=SDL_EVENT_PEN_UP)return false;
    out=event.ptouch;return true;
}
inline bool SDL_ReadPenButtonEvent(const SDL_Event & event,SDL_PenButtonEvent & out) {
    out={};
    if (event.type!=SDL_EVENT_PEN_BUTTON_DOWN && event.type!=SDL_EVENT_PEN_BUTTON_UP)return false;
    out=event.pbutton;return true;
}
inline bool SDL_ReadPenAxisEvent(const SDL_Event & event,SDL_PenAxisEvent & out) {
    out={};
    if (event.type!=SDL_EVENT_PEN_AXIS)return false;
    out=event.paxis;return true;
}
inline bool SDL_ReadSensorEvent(const SDL_Event & event,SDL_SensorEvent & out) {
    out={};
    if (event.type!=SDL_EVENT_SENSOR_UPDATE)return false;
    out=event.sensor;return true;
}

inline bool SDL_ReadKeyboardDeviceEvent(const SDL_Event & event,SDL_KeyboardDeviceEvent & out) {
    out={};
    if (event.type != SDL_EVENT_KEYBOARD_ADDED && event.type != SDL_EVENT_KEYBOARD_REMOVED) return false;
    out=event.kdevice;
    return true;
}

inline bool SDL_ReadMouseDeviceEvent(const SDL_Event & event,SDL_MouseDeviceEvent & out) {
    out={};
    if (event.type != SDL_EVENT_MOUSE_ADDED && event.type != SDL_EVENT_MOUSE_REMOVED) return false;
    out=event.mdevice;
    return true;
}

inline bool SDL_ReadAudioDeviceEvent(const SDL_Event & event,SDL_AudioDeviceEvent & out) {
    out={};
    if (event.type != SDL_EVENT_AUDIO_DEVICE_ADDED && event.type != SDL_EVENT_AUDIO_DEVICE_REMOVED && event.type != SDL_EVENT_AUDIO_DEVICE_FORMAT_CHANGED) return false;
    out=event.adevice;
    return true;
}

inline bool SDL_ReadCameraDeviceEvent(const SDL_Event & event,SDL_CameraDeviceEvent & out) {
    out={};
    if (event.type != SDL_EVENT_CAMERA_DEVICE_ADDED && event.type != SDL_EVENT_CAMERA_DEVICE_REMOVED && event.type != SDL_EVENT_CAMERA_DEVICE_APPROVED && event.type != SDL_EVENT_CAMERA_DEVICE_DENIED) return false;
    out=event.cdevice;
    return true;
}

inline bool SDL_ReadDisplayEvent(const SDL_Event & event,SDL_DisplayEvent & out) {
    out={};
    if (event.type!=SDL_EVENT_DISPLAY_ORIENTATION && event.type!=SDL_EVENT_DISPLAY_ADDED && event.type!=SDL_EVENT_DISPLAY_REMOVED && event.type!=SDL_EVENT_DISPLAY_MOVED && event.type!=SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED && event.type!=SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED && event.type!=SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED && event.type!=SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED) return false;
    out=event.display; return true;
}

inline bool SDL_ReadRenderEvent(const SDL_Event & event,SDL_RenderEvent & out) {
    out={};
    if (event.type!=SDL_EVENT_RENDER_TARGETS_RESET && event.type!=SDL_EVENT_RENDER_DEVICE_RESET && event.type!=SDL_EVENT_RENDER_DEVICE_LOST) return false;
    out=event.render; return true;
}

inline bool SDL_ReadPinchEvent(const SDL_Event & event,SDL_PinchFingerEvent & out) {
    out={};
    if (event.type!=SDL_EVENT_PINCH_BEGIN && event.type!=SDL_EVENT_PINCH_UPDATE && event.type!=SDL_EVENT_PINCH_END) return false;
    out=event.pinch; return true;
}
