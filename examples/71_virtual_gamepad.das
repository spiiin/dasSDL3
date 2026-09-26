options gen2
require dassdl3/sdl3_joystick_gamepad_boost
require dassdl3/sdl3_scope
require dassdl3/sdl3_events
require daslib/match

// Consume owned variants; ignore events from unrelated physical controllers.
def controller_changes(id : uint) : int2 {
    var counts = int2(0)
    while (true) {
        var next <- poll_event()
        if (is_none(next)) { break }
        let event <- move_unwrap(next)
        match (event) {
            if (SdlEvent(gamepad_axis_motion = $v(axis))) {
                if (axis.which == id && axis.axis == SDL_GamepadAxis.GAMEPAD_AXIS_LEFTX && int(axis.value) == 16000) {
                    print("Axis event: {int(axis.value)}\n")
                    counts.x++
                }
            }
            if (SdlEvent(gamepad_button_down = $v(button))) {
                if (button.which == id && button.button == SDL_GamepadButton.GAMEPAD_BUTTON_SOUTH) {
                    print("South button pressed\n")
                    counts.y++
                }
            }
            if (_) { }
        }
    }
    return counts
}

def inspect_virtual(id : uint) {
    return sdl_scope() {
        let joystick : SDL_Joystick? = with_joystick(id) |> sdl_use
        let gamepad : SDL_Gamepad? = with_gamepad(id) |> sdl_use
        let name = gamepad_name(gamepad) |> sdl_try
        print("Opened {name}; id={id}\n")
        controller_changes(id) // Drain initial state before changing the device.
        SDL_SetJoystickVirtualAxis(joystick, 0, int16(16000))
        SDL_SetJoystickVirtualButton(joystick, 0, true)
        SDL_UpdateJoysticks()
        let changes = controller_changes(id)
        // SDL may send an initial axis update as well as the changed state.
        verify(changes.x >= 1 && changes.y >= 1)
        let axis = SDL_GetGamepadAxis(gamepad, SDL_GamepadAxis.GAMEPAD_AXIS_LEFTX)
        let pressed = SDL_GetGamepadButton(gamepad, SDL_GamepadButton.GAMEPAD_BUTTON_SOUTH)
        verify(int(axis) == 16000 && pressed)
        print("Left X: {int(axis)}; south button: {pressed}\n")
        let bindings <- gamepad_bindings(gamepad) |> sdl_try
        print("Native mappings: {length(bindings)}\n")
        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    SDL_SetHint("SDL_JOYSTICK_ALLOW_BACKGROUND_EVENTS", "1")
    let result = sdl_scope() {
        with_sdl_subsystems(SDL_INIT_VIDEO | SDL_INIT_GAMEPAD) |> sdl_use
        var desc = SDL_MakeVirtualJoystickDesc()
        desc.joystick_type = uint16(SDL_JoystickType.JOYSTICK_TYPE_GAMEPAD)
        desc.naxes = uint16(6); desc.nbuttons = uint16(16)
        var touchpads : array<SDL_VirtualJoystickTouchpadDesc>
        var sensors : array<SDL_VirtualJoystickSensorDesc>
        let id : uint = with_virtual_joystick(desc, "dasSDL3 virtual gamepad", touchpads, sensors) |> sdl_use
        return inspect_virtual(id)
    }
    if (is_err(result)) {let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1}
    print("Gamepad and joystick closed; virtual device detached.\n")
    return 0
}
