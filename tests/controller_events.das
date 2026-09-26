options gen2
require dassdl3/sdl3_events
require daslib/match

def check(event : SdlEvent) : uint {
    match (event) {
        if (SdlEvent(joystick_axis_motion = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.axis == uint8(7) && int(v.value) == -32768)
            return SDL_EVENT_JOYSTICK_AXIS_MOTION
        }
        if (SdlEvent(joystick_ball_motion = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.ball == uint8(3) && v.delta == int2(-32768, 32767))
            return SDL_EVENT_JOYSTICK_BALL_MOTION
        }
        if (SdlEvent(joystick_hat_motion = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.hat == uint8(2) && uint(v.value) == SDL_HAT_LEFTUP)
            return SDL_EVENT_JOYSTICK_HAT_MOTION
        }
        if (SdlEvent(joystick_button_down = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.button == uint8(9))
            return SDL_EVENT_JOYSTICK_BUTTON_DOWN
        }
        if (SdlEvent(joystick_button_up = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.button == uint8(9))
            return SDL_EVENT_JOYSTICK_BUTTON_UP
        }
        if (SdlEvent(joystick_added = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(true)
            return SDL_EVENT_JOYSTICK_ADDED
        }
        if (SdlEvent(joystick_removed = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(true)
            return SDL_EVENT_JOYSTICK_REMOVED
        }
        if (SdlEvent(joystick_update_complete = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(true)
            return SDL_EVENT_JOYSTICK_UPDATE_COMPLETE
        }
        if (SdlEvent(joystick_battery_updated = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.state == SDL_PowerState.POWERSTATE_UNKNOWN && v.percent == -1)
            return SDL_EVENT_JOYSTICK_BATTERY_UPDATED
        }
        if (SdlEvent(gamepad_axis_motion = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.axis == SDL_GamepadAxis.GAMEPAD_AXIS_RIGHTY && int(v.value) == -32768)
            return SDL_EVENT_GAMEPAD_AXIS_MOTION
        }
        if (SdlEvent(gamepad_button_down = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.button == SDL_GamepadButton.GAMEPAD_BUTTON_EAST)
            return SDL_EVENT_GAMEPAD_BUTTON_DOWN
        }
        if (SdlEvent(gamepad_button_up = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.button == SDL_GamepadButton.GAMEPAD_BUTTON_EAST)
            return SDL_EVENT_GAMEPAD_BUTTON_UP
        }
        if (SdlEvent(gamepad_added = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(true)
            return SDL_EVENT_GAMEPAD_ADDED
        }
        if (SdlEvent(gamepad_removed = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(true)
            return SDL_EVENT_GAMEPAD_REMOVED
        }
        if (SdlEvent(gamepad_remapped = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(true)
            return SDL_EVENT_GAMEPAD_REMAPPED
        }
        if (SdlEvent(gamepad_update_complete = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(true)
            return SDL_EVENT_GAMEPAD_UPDATE_COMPLETE
        }
        if (SdlEvent(gamepad_steam_handle_updated = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(true)
            return SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED
        }
        if (SdlEvent(gamepad_touchpad_down = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.touchpad == 2 && v.finger == 3 && v.position == float2(0.25, 0.75) && v.pressure == 0.5)
            return SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN
        }
        if (SdlEvent(gamepad_touchpad_motion = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.touchpad == 2 && v.finger == 3 && v.position == float2(0.25, 0.75) && v.pressure == 0.5)
            return SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION
        }
        if (SdlEvent(gamepad_touchpad_up = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.touchpad == 2 && v.finger == 3 && v.position == float2(0.25, 0.75) && v.pressure == 0.5)
            return SDL_EVENT_GAMEPAD_TOUCHPAD_UP
        }
        if (SdlEvent(gamepad_sensor_update = $v(v))) {
            verify(v.which == 0xf1234567u && v.timestamp == 0xfedcba9876543210ul)
            verify(v.sensor == SDL_SensorType.SENSOR_GYRO && v.data == float3(
                -1.25,
                2.5,
                3.75) && v.sensor_timestamp == 0x123456789abcdef0ul
            )
            return SDL_EVENT_GAMEPAD_SENSOR_UPDATE
        }
        if (_) { verify(false); return 0u }
    }
}

[export]
def main(smoke : bool) : int {
    let kinds <- array<uint>(SDL_EVENT_JOYSTICK_AXIS_MOTION, SDL_EVENT_JOYSTICK_BALL_MOTION, SDL_EVENT_JOYSTICK_HAT_MOTION, SDL_EVENT_JOYSTICK_BUTTON_DOWN, SDL_EVENT_JOYSTICK_BUTTON_UP, SDL_EVENT_JOYSTICK_ADDED, SDL_EVENT_JOYSTICK_REMOVED, SDL_EVENT_JOYSTICK_UPDATE_COMPLETE, SDL_EVENT_JOYSTICK_BATTERY_UPDATED, SDL_EVENT_GAMEPAD_AXIS_MOTION, SDL_EVENT_GAMEPAD_BUTTON_DOWN, SDL_EVENT_GAMEPAD_BUTTON_UP, SDL_EVENT_GAMEPAD_ADDED, SDL_EVENT_GAMEPAD_REMOVED, SDL_EVENT_GAMEPAD_REMAPPED, SDL_EVENT_GAMEPAD_UPDATE_COMPLETE, SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED, SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN, SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION, SDL_EVENT_GAMEPAD_TOUCHPAD_UP, SDL_EVENT_GAMEPAD_SENSOR_UPDATE)
    var saved : array<SdlEvent>
    for (kind in kinds) {
        var raw = SDLTestControllerEvent(kind)
        var decoded <- decode_event(raw); emplace(saved, decoded)
        raw = SDL_MakeEvent()
        verify(check(saved[length(saved) - 1]) == kind)
    }
    var wrong = SDL_MakeEvent()
    wrong.event_type = SDL_EVENT_QUIT
    var outJoyAxis : SDL_JoyAxisEvent
    let rawJoyAxis = SDLTestControllerEvent(SDL_EVENT_JOYSTICK_AXIS_MOTION)
    verify(SDL_ReadJoyAxisEvent(rawJoyAxis, outJoyAxis) && outJoyAxis.which == 0xf1234567u)
    verify(!SDL_ReadJoyAxisEvent(wrong, outJoyAxis) && outJoyAxis.which == 0u && outJoyAxis.timestamp == 0ul)
    var outJoyBall : SDL_JoyBallEvent
    let rawJoyBall = SDLTestControllerEvent(SDL_EVENT_JOYSTICK_BALL_MOTION)
    verify(SDL_ReadJoyBallEvent(rawJoyBall, outJoyBall) && outJoyBall.which == 0xf1234567u)
    verify(!SDL_ReadJoyBallEvent(wrong, outJoyBall) && outJoyBall.which == 0u && outJoyBall.timestamp == 0ul)
    var outJoyHat : SDL_JoyHatEvent
    let rawJoyHat = SDLTestControllerEvent(SDL_EVENT_JOYSTICK_HAT_MOTION)
    verify(SDL_ReadJoyHatEvent(rawJoyHat, outJoyHat) && outJoyHat.which == 0xf1234567u)
    verify(!SDL_ReadJoyHatEvent(wrong, outJoyHat) && outJoyHat.which == 0u && outJoyHat.timestamp == 0ul)
    var outJoyButton : SDL_JoyButtonEvent
    let rawJoyButton = SDLTestControllerEvent(SDL_EVENT_JOYSTICK_BUTTON_DOWN)
    verify(SDL_ReadJoyButtonEvent(rawJoyButton, outJoyButton) && outJoyButton.which == 0xf1234567u)
    verify(!SDL_ReadJoyButtonEvent(wrong, outJoyButton) && outJoyButton.which == 0u && outJoyButton.timestamp == 0ul)
    var outJoyDevice : SDL_JoyDeviceEvent
    let rawJoyDevice = SDLTestControllerEvent(SDL_EVENT_JOYSTICK_ADDED)
    verify(SDL_ReadJoyDeviceEvent(rawJoyDevice, outJoyDevice) && outJoyDevice.which == 0xf1234567u)
    verify(!SDL_ReadJoyDeviceEvent(wrong, outJoyDevice) && outJoyDevice.which == 0u && outJoyDevice.timestamp == 0ul)
    var outJoyBattery : SDL_JoyBatteryEvent
    let rawJoyBattery = SDLTestControllerEvent(SDL_EVENT_JOYSTICK_BATTERY_UPDATED)
    verify(SDL_ReadJoyBatteryEvent(rawJoyBattery, outJoyBattery) && outJoyBattery.which == 0xf1234567u)
    verify(!SDL_ReadJoyBatteryEvent(wrong, outJoyBattery) && outJoyBattery.which == 0u && outJoyBattery.timestamp == 0ul)
    var outGamepadAxis : SDL_GamepadAxisEvent
    let rawGamepadAxis = SDLTestControllerEvent(SDL_EVENT_GAMEPAD_AXIS_MOTION)
    verify(SDL_ReadGamepadAxisEvent(rawGamepadAxis, outGamepadAxis) && outGamepadAxis.which == 0xf1234567u)
    verify(!SDL_ReadGamepadAxisEvent(wrong, outGamepadAxis) && outGamepadAxis.which == 0u && outGamepadAxis.timestamp == 0ul)
    var outGamepadButton : SDL_GamepadButtonEvent
    let rawGamepadButton = SDLTestControllerEvent(SDL_EVENT_GAMEPAD_BUTTON_DOWN)
    verify(SDL_ReadGamepadButtonEvent(rawGamepadButton, outGamepadButton) && outGamepadButton.which == 0xf1234567u)
    verify(!SDL_ReadGamepadButtonEvent(wrong, outGamepadButton) && outGamepadButton.which == 0u && outGamepadButton.timestamp == 0ul)
    var outGamepadDevice : SDL_GamepadDeviceEvent
    let rawGamepadDevice = SDLTestControllerEvent(SDL_EVENT_GAMEPAD_ADDED)
    verify(SDL_ReadGamepadDeviceEvent(rawGamepadDevice, outGamepadDevice) && outGamepadDevice.which == 0xf1234567u)
    verify(!SDL_ReadGamepadDeviceEvent(wrong, outGamepadDevice) && outGamepadDevice.which == 0u && outGamepadDevice.timestamp == 0ul)
    var outGamepadTouchpad : SDL_GamepadTouchpadEvent
    let rawGamepadTouchpad = SDLTestControllerEvent(SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN)
    verify(SDL_ReadGamepadTouchpadEvent(rawGamepadTouchpad, outGamepadTouchpad) && outGamepadTouchpad.which == 0xf1234567u)
    verify(!SDL_ReadGamepadTouchpadEvent(wrong, outGamepadTouchpad) && outGamepadTouchpad.which == 0u && outGamepadTouchpad.timestamp == 0ul)
    var outGamepadSensor : SDL_GamepadSensorEvent
    let rawGamepadSensor = SDLTestControllerEvent(SDL_EVENT_GAMEPAD_SENSOR_UPDATE)
    verify(SDL_ReadGamepadSensorEvent(rawGamepadSensor, outGamepadSensor) && outGamepadSensor.which == 0xf1234567u)
    verify(!SDL_ReadGamepadSensorEvent(wrong, outGamepadSensor) && outGamepadSensor.which == 0u && outGamepadSensor.timestamp == 0ul)
    let result = with_sdl() {
        while (is_some(poll_event())) { }
        for (kind in kinds) {
            var raw = SDLTestControllerEvent(kind)
            verify(push_event(raw))
        }
        for (kind in kinds) {
            var next <- poll_event()
            verify(is_some(next) && check(unwrap(next)) == kind)
        }
        for (i in 0 .. length(kinds)) { verify(check(saved[i]) == kinds[i]) }
        return sdl_ok()
    }
    verify(is_ok(result))
    print("All 21 controller event variants, active union readers and owned queue copies PASS\n")
    return 0
}
