options gen2
require dassdl3/sdl3_joystick_gamepad_boost
require dassdl3/sdl3_scope
require daslib/defer

// Every query here uses this test's own virtual device, never a physical controller.
def query_devices(id : uint; joystick : SDL_Joystick?; gamepad : SDL_Gamepad?) {
    verify(SDL_HasJoystick() && SDL_HasGamepad() && SDL_IsGamepad(id))
    verify(SDL_JoystickConnected(joystick) && SDL_GamepadConnected(gamepad))
    verify(SDL_GetJoystickID(joystick) == id && SDL_GetGamepadID(gamepad) == id)
    verify(SDL_GetGamepadJoystick(gamepad) == joystick)
    verify(SDL_GetJoystickFromID(id) == joystick && SDL_GetGamepadFromID(id) == gamepad)
    verify(SDL_SetJoystickPlayerIndex(joystick, 7) && SDL_SetGamepadPlayerIndex(gamepad, 7))
    verify(SDL_GetJoystickFromPlayerIndex(7) == joystick && SDL_GetGamepadFromPlayerIndex(7) == gamepad)
    verify(SDL_GetJoystickPlayerIndex(joystick) == 7 && SDL_GetGamepadPlayerIndex(gamepad) == 7)
    verify(SDL_GetJoystickPlayerIndexForID(id) == 7 && SDL_GetGamepadPlayerIndexForID(id) == 7)
    verify(SDL_GetJoystickProperties(joystick) != 0u && SDL_GetGamepadProperties(gamepad) != 0u)
    verify(uint(SDL_GetJoystickVendor(joystick)) == 0x1234u && uint(SDL_GetGamepadVendor(gamepad)) == 0x1234u)
    verify(uint(SDL_GetJoystickProduct(joystick)) == 0x5678u && uint(SDL_GetGamepadProduct(gamepad)) == 0x5678u)
    verify(uint(SDL_GetJoystickVendorForID(id)) == 0x1234u && uint(SDL_GetGamepadVendorForID(id)) == 0x1234u)
    verify(uint(SDL_GetJoystickProductForID(id)) == 0x5678u && uint(SDL_GetGamepadProductForID(id)) == 0x5678u)
    verify(length(SDL_GetJoystickNameForID(id)) > 0 && length(SDL_GetJoystickName(joystick)) > 0)
    let path_joystick = SDL_GetJoystickPath(joystick); let pathid_joystick = SDL_GetJoystickPathForID(id)
    let serial_joystick = SDL_GetJoystickSerial(joystick)
    let version_joystick = SDL_GetJoystickProductVersion(joystick); let vid_joystick = SDL_GetJoystickProductVersionForID(id)
    let firmware_joystick = SDL_GetJoystickFirmwareVersion(joystick)
    let type_joystick = SDL_GetJoystickType(joystick); let tid_joystick = SDL_GetJoystickTypeForID(id)
    verify(type_joystick == tid_joystick && version_joystick == vid_joystick)
    let connection_joystick = SDL_GetJoystickConnectionState(joystick)
    var percent_joystick : int
    unsafe { let power = SDL_GetJoystickPowerInfo(joystick, addr(percent_joystick)) }
    let power_joystick = SDL_GetJoystickPowerInfoRef(joystick, percent_joystick)
    joystick_name(joystick) |> sdl_try
    let p_joystick = joystick_path(joystick); let s_joystick = joystick_serial(joystick)
    verify(length(SDL_GetGamepadNameForID(id)) > 0 && length(SDL_GetGamepadName(gamepad)) > 0)
    let path_gamepad = SDL_GetGamepadPath(gamepad); let pathid_gamepad = SDL_GetGamepadPathForID(id)
    let serial_gamepad = SDL_GetGamepadSerial(gamepad)
    let version_gamepad = SDL_GetGamepadProductVersion(gamepad); let vid_gamepad = SDL_GetGamepadProductVersionForID(id)
    let firmware_gamepad = SDL_GetGamepadFirmwareVersion(gamepad)
    let type_gamepad = SDL_GetGamepadType(gamepad); let tid_gamepad = SDL_GetGamepadTypeForID(id)
    verify(type_gamepad == tid_gamepad && version_gamepad == vid_gamepad)
    let connection_gamepad = SDL_GetGamepadConnectionState(gamepad)
    var percent_gamepad : int
    unsafe { let power = SDL_GetGamepadPowerInfo(gamepad, addr(percent_gamepad)) }
    let power_gamepad = SDL_GetGamepadPowerInfoRef(gamepad, percent_gamepad)
    gamepad_name(gamepad) |> sdl_try
    let p_gamepad = gamepad_path(gamepad); let s_gamepad = gamepad_serial(gamepad)
    let steam = SDL_GetGamepadSteamHandle(gamepad)
    verify(SDL_GetRealGamepadType(gamepad) == SDL_GetRealGamepadTypeForID(id))
    var guid = SDL_GetJoystickGUID(joystick)
    verify(SDL_GUIDString(guid) == SDL_GUIDString(SDL_GetJoystickGUIDForID(id)))
    verify(SDL_GUIDString(guid) == SDL_GUIDString(SDL_GetGamepadGUIDForID(id)))
    var vendor, product, version, crc : uint16
    unsafe { SDL_GetJoystickGUIDInfo(guid, addr(vendor), addr(product), addr(version), addr(crc)) }
    verify(uint(vendor) == 0x1234u && uint(product) == 0x5678u)
    var v, p, r, c : uint
    SDL_GetJoystickGUIDInfoRef(guid, v, p, r, c); verify(v == uint(vendor) && p == uint(product))
    unsafe {
        var count : int
        let js = SDL_GetJoysticks(addr(count)); verify(js != null && count >= 1); SDL_free(js)
        let gs = SDL_GetGamepads(addr(count)); verify(gs != null && count >= 1); SDL_free(gs)
        let bindings = SDL_GetGamepadBindings(gamepad, addr(count)); verify(bindings != null && count > 0); SDL_free(bindings)
        let mappings = SDL_GetGamepadMappings(addr(count)); verify(mappings != null && count > 0); SDL_free(mappings)
        let mapping = SDL_GetGamepadMapping(gamepad); verify(length(mapping) > 0); SDL_free(reinterpret<void?>(mapping))
        let by_id = SDL_GetGamepadMappingForID(id); verify(length(by_id) > 0); SDL_free(reinterpret<void?>(by_id))
        let by_guid = SDL_GetGamepadMappingForGUID(guid); verify(length(by_guid) > 0); SDL_free(reinterpret<void?>(by_guid))
    }
    let js <- joysticks() |> sdl_try; let gs <- gamepads() |> sdl_try
    verify(length(js) >= 1 && length(gs) >= 1)
    let mappings <- gamepad_mappings() |> sdl_try; verify(length(mappings) > 0)
    let mapping = gamepad_mapping(gamepad) |> sdl_try; verify(length(mapping) > 0)
    let bindings <- gamepad_bindings(gamepad) |> sdl_try
    verify(length(bindings) > 0)
    for (binding in bindings) {
        let input = SDL_GamepadBindingInput(binding); let output = SDL_GamepadBindingOutput(binding)
        verify(input.x >= 0 && output.x >= 0)
    }
    verify(SDL_GetGamepadTypeFromString("xboxone") == SDL_GamepadType.GAMEPAD_TYPE_XBOXONE)
    verify(SDL_GetGamepadStringForType(SDL_GamepadType.GAMEPAD_TYPE_XBOXONE) == "xboxone")
    verify(SDL_GetGamepadAxisFromString("leftx") == SDL_GamepadAxis.GAMEPAD_AXIS_LEFTX)
    verify(SDL_GetGamepadStringForAxis(SDL_GamepadAxis.GAMEPAD_AXIS_LEFTX) == "leftx")
    verify(SDL_GetGamepadButtonFromString("a") == SDL_GamepadButton.GAMEPAD_BUTTON_SOUTH)
    verify(SDL_GetGamepadStringForButton(SDL_GamepadButton.GAMEPAD_BUTTON_SOUTH) == "a")
    let button_label = SDL_GetGamepadButtonLabel(gamepad, SDL_GamepadButton.GAMEPAD_BUTTON_SOUTH)
    let type_label = SDL_GetGamepadButtonLabelForType(SDL_GamepadType.GAMEPAD_TYPE_XBOXONE, SDL_GamepadButton.GAMEPAD_BUTTON_SOUTH)
    verify(type_label == SDL_GamepadButtonLabel.GAMEPAD_BUTTON_LABEL_A)
    let symbol_button = SDL_GetGamepadAppleSFSymbolsNameForButton(gamepad, SDL_GamepadButton.GAMEPAD_BUTTON_SOUTH)
    let symbol_axis = SDL_GetGamepadAppleSFSymbolsNameForAxis(gamepad, SDL_GamepadAxis.GAMEPAD_AXIS_LEFTX)
    return sdl_ok()
}

def exercise_input(joystick : SDL_Joystick?; gamepad : SDL_Gamepad?) {
    verify(SDL_GetNumJoystickAxes(joystick) == 6 && SDL_GetNumJoystickButtons(joystick) == 16)
    verify(SDL_GetNumJoystickBalls(joystick) == 0 && SDL_GetNumJoystickHats(joystick) == 1)
    let je = SDL_JoystickEventsEnabled(); let ge = SDL_GamepadEventsEnabled()
    {
        defer() { SDL_SetJoystickEventsEnabled(je); SDL_SetGamepadEventsEnabled(ge) }
        SDL_SetJoystickEventsEnabled(true); SDL_SetGamepadEventsEnabled(true)
        verify(SDL_JoystickEventsEnabled() && SDL_GamepadEventsEnabled())
        SDL_UpdateJoysticks(); SDL_UpdateGamepads()
        var initial : int16
        unsafe { let known = SDL_GetJoystickAxisInitialState(joystick, 0, addr(initial)) }
        let known = joystick_axis_initial_state(joystick, 0)
        verify(SDL_SetJoystickVirtualAxis(joystick, 0, int16(12345)))
        verify(SDL_SetJoystickVirtualButton(joystick, 0, true))
        verify(SDL_SetJoystickVirtualHat(joystick, 0, SDL_HAT_RIGHT))
        verify(SDL_SetJoystickVirtualBall(joystick, 0, int16(7), int16(-3)))
        SDL_UpdateJoysticks(); SDL_UpdateGamepads()
        verify(int(SDL_GetJoystickAxis(joystick, 0)) == 12345)
        verify(SDL_GetJoystickButton(joystick, 0) && uint(SDL_GetJoystickHat(joystick, 0)) == SDL_HAT_RIGHT)
        verify(SDL_GamepadHasAxis(gamepad, SDL_GamepadAxis.GAMEPAD_AXIS_LEFTX))
        verify(SDL_GamepadHasButton(gamepad, SDL_GamepadButton.GAMEPAD_BUTTON_SOUTH))
        verify(int(SDL_GetGamepadAxis(gamepad, SDL_GamepadAxis.GAMEPAD_AXIS_LEFTX)) == 12345)
        verify(SDL_GetGamepadButton(gamepad, SDL_GamepadButton.GAMEPAD_BUTTON_SOUTH))
        var x, y : int
        // SDL 3.2.18 virtual Open omits nballs; submitted ball motion is discarded.
        unsafe { verify(!SDL_GetJoystickBall(joystick, 0, addr(x), addr(y))) }
        verify(is_err(joystick_ball(joystick, 0)))
    }
    verify(SDL_GetNumGamepadTouchpads(gamepad) == 1 && SDL_GetNumGamepadTouchpadFingers(gamepad, 0) == 2)
    verify(SDL_SetJoystickVirtualTouchpad(joystick, 0, 0, true, 0.25, 0.75, 0.5))
    SDL_UpdateJoysticks(); SDL_UpdateGamepads()
    var down : bool; var x, y, pressure : float
    unsafe { verify(SDL_GetGamepadTouchpadFinger(gamepad, 0, 0, addr(down), addr(x), addr(y), addr(pressure))) }
    verify(down && x == 0.25 && y == 0.75 && pressure == 0.5)
    var position : float2
    gamepad_touchpad_finger(gamepad, 0, 0, down, position, pressure) |> sdl_try
    let touch = gamepad_touchpad_finger(gamepad, 0, 0) |> sdl_try
    verify(touch.down == down && touch.position == position && touch.pressure == pressure)
    verify(down && position == float2(0.25, 0.75))
    verify(SDL_GamepadHasSensor(gamepad, SDL_SensorType.SENSOR_ACCEL))
    verify(SDL_SetGamepadSensorEnabled(gamepad, SDL_SensorType.SENSOR_ACCEL, true))
    verify(SDL_GamepadSensorEnabled(gamepad, SDL_SensorType.SENSOR_ACCEL))
    verify(SDL_GetGamepadSensorDataRate(gamepad, SDL_SensorType.SENSOR_ACCEL) == 120.0)
    var data <- array<float>(1.25, -2.0, 9.0)
    unsafe { verify(SDL_SendJoystickVirtualSensorData(joystick, SDL_SensorType.SENSOR_ACCEL, 123456ul, addr(data[0]), 3)) }
    SDL_UpdateJoysticks(); SDL_UpdateGamepads()
    var measured : array<float>; resize(measured, 3)
    unsafe { verify(SDL_GetGamepadSensorData(gamepad, SDL_SensorType.SENSOR_ACCEL, addr(measured[0]), 3)) }
    verify(measured[0] == 1.25 && measured[1] == -2.0 && measured[2] == 9.0)
    send_virtual_sensor_data(joystick, SDL_SensorType.SENSOR_ACCEL, 234567ul, data) |> sdl_try
    SDL_UpdateJoysticks(); SDL_UpdateGamepads()
    let copied <- gamepad_sensor_data(gamepad, SDL_SensorType.SENSOR_ACCEL) |> sdl_try
    verify(copied[0] == 1.25 && copied[2] == 9.0)
    verify(is_err(gamepad_sensor_data(gamepad, SDL_SensorType.SENSOR_ACCEL, 0)))
    return sdl_ok()
}

def effects(joystick : SDL_Joystick?; gamepad : SDL_Gamepad?) {
    let before = SDLTestVirtualCounts()
    var bytes <- array<uint8>(uint8(42), uint8(7), uint8(8))
    verify(SDL_RumbleJoystick(joystick, 123u, 456u, 10u))
    verify(SDL_RumbleJoystickTriggers(joystick, 123u, 456u, 10u))
    verify(SDL_SetJoystickLED(joystick, 12u, 34u, 56u))
    unsafe { verify(SDL_SendJoystickEffect(joystick, addr(bytes[0]), 3)) }
    rumble_joystick(joystick, 123u, 456u, 10u) |> sdl_try
    rumble_joystick_triggers(joystick, 123u, 456u, 10u) |> sdl_try
    set_joystick_led(joystick, 12u, 34u, 56u) |> sdl_try
    send_joystick_effect(joystick, bytes) |> sdl_try
    verify(SDL_RumbleGamepad(gamepad, 123u, 456u, 10u))
    verify(SDL_RumbleGamepadTriggers(gamepad, 123u, 456u, 10u))
    verify(SDL_SetGamepadLED(gamepad, 12u, 34u, 56u))
    unsafe { verify(SDL_SendGamepadEffect(gamepad, addr(bytes[0]), 3)) }
    rumble_gamepad(gamepad, 123u, 456u, 10u) |> sdl_try
    rumble_gamepad_triggers(gamepad, 123u, 456u, 10u) |> sdl_try
    set_gamepad_led(gamepad, 12u, 34u, 56u) |> sdl_try
    send_gamepad_effect(gamepad, bytes) |> sdl_try
    let after = SDLTestVirtualCounts()
    verify(after.y >= before.y + 4 && after.z > before.z && after.w > before.w)
    return sdl_ok()
}

def run_virtual() {
    SDL_LockJoysticks(); SDL_UnlockJoysticks()
    verify(SDL_ReloadGamepadMappings())
    verify(SDL_AddGamepadMappingsFromFile("dassdl3-missing-mappings-file.txt") == -1)
    verify(SDL_AddGamepadMapping("invalid") == -1 && is_err(add_gamepad_mapping("invalid")))
    let before = SDLTestVirtualCounts()
    var desc = SDLTestVirtualJoystickDesc()
    var id : uint
    unsafe { id = SDL_AttachVirtualJoystick(addr(desc)) }
    verify(id != 0u && SDL_IsJoystickVirtual(id))
    {
        defer() { verify(SDL_DetachVirtualJoystick(id)) }
        var guid = SDL_GetJoystickGUIDForID(id)
        let mapping = "{SDL_GUIDString(guid)},dasSDL3 mapped,a:b0,b:b1,leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:a4,righttrigger:a5,dpup:h0.1,dpright:h0.2,dpdown:h0.4,dpleft:h0.8,"
        verify(SDL_AddGamepadMapping(mapping) >= 0)
        verify(SDL_SetGamepadMapping(id, mapping))
        let added = add_gamepad_mapping(mapping) |> sdl_try
        unsafe {
            let lines = "{mapping}\n"
            let io = SDL_IOFromConstMem(reinterpret<void?>(lines), uint64(length(lines)))
            verify(io != null && SDL_AddGamepadMappingsFromIO(io, true) >= 0)
        }
        let joystick = SDL_OpenJoystick(id); verify(joystick != null)
        {
            defer() { SDL_CloseJoystick(joystick) }
            let gamepad = SDL_OpenGamepad(id); verify(gamepad != null)
            {
                defer() { SDL_CloseGamepad(gamepad) }
                query_devices(id, joystick, gamepad) |> sdl_try
                exercise_input(joystick, gamepad) |> sdl_try
                effects(joystick, gamepad) |> sdl_try
                with_joystick(id) $(j : SDL_Joystick?) {verify(j == joystick); return sdl_ok()} |> sdl_try
                with_gamepad(id) $(g : SDL_Gamepad?) {verify(g == gamepad); return sdl_ok()} |> sdl_try
            }
        }
    }
    verify(!SDL_IsJoystickVirtual(id) && SDLTestVirtualCounts().x == before.x + 1)
    verify(SDL_GetJoystickFromID(id) == null && SDL_GetGamepadFromID(id) == null)
    verify(is_err(open_joystick(id)) && is_err(open_gamepad(id)))
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    SDL_SetHint("SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS", "1")
    let result = with_sdl_subsystems(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD) {
        return with_joysticks_lock() { return run_virtual() }
    }
    if (is_err(result)) {let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1}
    print("Joystick/gamepad: native virtual input, mappings, sensor/touch and callbacks passed\n")
    return 0
}
