options gen2
require sdl3
require daslib/defer

[export]
def main(smoke : bool) : int {
    verify(SDL_Init(SDL_INIT_GAMEPAD))
    var desc = SDLTestVirtualJoystickDesc()
    desc.userdata = SDLTestRecordCookie()
    SDL_SetVirtualJoystickDesc_Update(desc, SDLTestRecordCallback(0))
    SDL_SetVirtualJoystickDesc_SetPlayerIndex(desc, SDLTestRecordCallback(1))
    SDL_SetVirtualJoystickDesc_Rumble(desc, SDLTestRecordCallback(2))
    SDL_SetVirtualJoystickDesc_RumbleTriggers(desc, SDLTestRecordCallback(3))
    SDL_SetVirtualJoystickDesc_SetLED(desc, SDLTestRecordCallback(4))
    SDL_SetVirtualJoystickDesc_SendEffect(desc, SDLTestRecordCallback(5))
    SDL_SetVirtualJoystickDesc_SetSensorsEnabled(desc, SDLTestRecordCallback(6))
    SDL_SetVirtualJoystickDesc_Cleanup(desc, SDLTestRecordCallback(7))
    let version = desc.version; desc.version = 0u
    unsafe {verify(SDL_AttachVirtualJoystick(addr(desc)) == 0u)}
    verify(SDLTestRecordCount(7) == 0)// Validation precedes transfer of userdata ownership.
    desc.version = version
    var id : uint
    unsafe {id = SDL_AttachVirtualJoystick(addr(desc))}
    verify(id != 0u)
    let j = SDL_OpenJoystick(id); verify(j != null)
    let g = SDL_OpenGamepad(id); verify(g != null)
    SDL_UpdateJoysticks()
    verify(SDL_SetJoystickPlayerIndex(j, 7))
    verify(SDL_RumbleJoystick(j, 123u, 456u, 100u))
    verify(SDL_RumbleJoystickTriggers(j, 123u, 456u, 100u))
    verify(SDL_SetJoystickLED(j, 12u, 34u, 56u))
    var bytes : uint8[3]; bytes[0] = uint8(42)
    unsafe {verify(SDL_SendJoystickEffect(j, addr(bytes[0]), 3))}
    verify(SDL_SetGamepadSensorEnabled(g, SDL_SensorType.SENSOR_ACCEL, true))
    SDL_CloseGamepad(g); SDL_CloseJoystick(j)
    verify(SDL_DetachVirtualJoystick(id))
    for (i in 0 .. 8) {verify(SDLTestRecordCount(i) > 0)}
    verify(SDLTestRecordCount(7) == 1 && SDLTestRecordGood())
    SDL_Quit()
    print("All eight virtual joystick native callback setters passed\n")
    return 0
}
