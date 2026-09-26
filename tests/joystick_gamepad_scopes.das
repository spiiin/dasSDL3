options gen2
require dassdl3/sdl3_joystick_gamepad_boost
require dassdl3/sdl3_scope
require daslib/defer

def check_scopes() {
    var desc = SDL_MakeVirtualJoystickDesc()
    desc.joystick_type = uint16(SDL_JoystickType.JOYSTICK_TYPE_GAMEPAD)
    desc.naxes = uint16(6); desc.nbuttons = uint16(16)
    var pads : array<SDL_VirtualJoystickTouchpadDesc>
    var sensors : array<SDL_VirtualJoystickSensorDesc>
    resize(pads, 1); pads[0].nfingers = uint16(2)
    resize(sensors, 1); sensors[0].sensor_type = SDL_SensorType.SENSOR_ACCEL; sensors[0].rate = 60.0
    let id = attach_virtual_joystick(desc, "copied virtual device", pads, sensors) |> sdl_try
    {
        defer() { verify(SDL_DetachVirtualJoystick(id)) }
        // SDL owns its copy of the descriptor arrays after Attach returns.
        resize(pads, 0); resize(sensors, 0)
        var retained_name : string
        let failed = with_gamepad(id) $(g : SDL_Gamepad?) {
            retained_name = gamepad_name(g) |> sdl_try
            verify(SDL_GetNumGamepadTouchpads(g) == 1 && SDL_GetNumGamepadTouchpadFingers(g, 0) == 2)
            verify(SDL_GamepadHasSensor(g, SDL_SensorType.SENSOR_ACCEL))
            return err(SdlError(operation = "body", message = "preserve me"), type<SdlUnit>)
        }
        verify(is_err(failed) && unwrap_err(failed).message == "preserve me")
        verify(SDL_GetGamepadFromID(id) == null && SDL_GetJoystickFromID(id) == null)
        let moved <- with_joystick(id) $(j : SDL_Joystick?) {
            var empty : array<float>
            verify(is_err(send_virtual_sensor_data(j, SDL_SensorType.SENSOR_ACCEL, 0ul, empty)))
            var values <- array<int>(10, 20)
            return <- move_ok(values, type<SdlError>)
        } |> sdl_try
        verify(length(moved) == 2 && moved[1] == 20 && SDL_GetJoystickFromID(id) == null)
        var opened <- open_joystick(id) |> sdl_try
        SDL_CloseJoystick(opened)
        var gamepad <- open_gamepad(id) |> sdl_try
        SDL_CloseGamepad(gamepad)
        verify(length(retained_name) > 0)
        var entered = false
        let invalid = with_joystick(0u) $(j : SDL_Joystick?) {entered = true; return sdl_ok()}
        verify(is_err(invalid) && !entered)
    }
    verify(!SDL_IsJoystickVirtual(id))
    var scoped_id = 0u
    let primary = with_virtual_joystick(desc, "scoped", pads, sensors) $(new_id : uint) {
        scoped_id = new_id
        return err(SdlError(operation = "body", message = "virtual primary"), type<SdlUnit>)
    }
    verify(is_err(primary) && unwrap_err(primary).message == "virtual primary")
    verify(scoped_id != 0u && !SDL_IsJoystickVirtual(scoped_id))
    desc.naxes = uint16(256)
    verify(is_err(attach_virtual_joystick(desc, "too many axes", pads, sensors)))
    desc.naxes = uint16(6)
    desc.version = 0u
    var entered = false
    let invalid = with_virtual_joystick(desc, "invalid", pads, sensors) $(new_id : uint) { entered = true; return sdl_ok() }
    verify(is_err(invalid) && !entered)
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let result = with_sdl_subsystems(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD) { return check_scopes() }
    if (is_err(result)) {let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1}
    print("Joystick/gamepad scopes: copied descriptors, early errors, move-only results and cleanup passed\n")
    return 0
}
