options gen2
require daslib/defer
module sdl3_joystick_gamepad_boost shared public
require dassdl3/sdl3_init_boost public

def public joysticks() {
    var values : array<uint>
    if (!SDL_GetJoysticksCopy(values)) { return err(sdl_error("SDL_GetJoysticksCopy"),type<array<uint>>) }
    return <- move_ok(values,type<SdlError>)
}
def public gamepads() {
    var values : array<uint>
    if (!SDL_GetGamepadsCopy(values)) { return err(sdl_error("SDL_GetGamepadsCopy"),type<array<uint>>) }
    return <- move_ok(values,type<SdlError>)
}
def public gamepad_bindings(gamepad : SDL_Gamepad?) {
    var values : array<SDL_GamepadBinding>
    if (!SDL_GetGamepadBindingsCopy(gamepad,values)) { return err(sdl_error("SDL_GetGamepadBindingsCopy"),type<array<SDL_GamepadBinding>>) }
    return <- move_ok(values,type<SdlError>)
}
def public gamepad_mappings() {
    var values : array<string>
    if (!SDL_GetGamepadMappingsCopy(values)) { return err(sdl_error("SDL_GetGamepadMappingsCopy"),type<array<string>>) }
    return <- move_ok(values,type<SdlError>)
}
def public open_joystick(id : uint) {
    var value=SDL_OpenJoystick(id)
    if (value==null) { return err(sdl_error("SDL_OpenJoystick"),type<SDL_Joystick?>) }
    return <- move_ok(value,type<SdlError>)
}
def public with_joystick(id : uint; body : block<(device : SDL_Joystick?) : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    let device=SDL_OpenJoystick(id)
    if (device==null) { return err(sdl_error("SDL_OpenJoystick"),type<TT>) }
    {
        defer() { SDL_CloseJoystick(device) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { scope_result=body(device) }
        else { scope_result <- body(device) }
    }
    return <- scope_result
}
def public joystick_name(device : SDL_Joystick?) {
    var value : string
    if (!SDL_GetJoystickNameValue(device,value)) { return err(sdl_error("SDL_GetJoystickNameValue"),type<string>) }
    return ok(value,type<SdlError>)
}
def public joystick_path(device : SDL_Joystick?) {
    var value : string
    if (!SDL_GetJoystickPathValue(device,value)) { return none(type<string>) }
    return some(value)
}
def public joystick_serial(device : SDL_Joystick?) {
    var value : string
    if (!SDL_GetJoystickSerialValue(device,value)) { return none(type<string>) }
    return some(value)
}
def public rumble_joystick(device : SDL_Joystick?; low,high : uint; duration : uint) { return sdl_status(SDL_RumbleJoystick(device,low,high,duration),"SDL_RumbleJoystick") }
def public rumble_joystick_triggers(device : SDL_Joystick?; left,right : uint; duration : uint) { return sdl_status(SDL_RumbleJoystickTriggers(device,left,right,duration),"SDL_RumbleJoystickTriggers") }
def public set_joystick_led(device : SDL_Joystick?; red,green,blue : uint) { return sdl_status(SDL_SetJoystickLED(device,red,green,blue),"SDL_SetJoystickLED") }
def public send_joystick_effect(device : SDL_Joystick?; data : array<uint8>) { return sdl_status(SDL_SendJoystickEffectArray(device,data),"SDL_SendJoystickEffect") }
def public open_gamepad(id : uint) {
    var value=SDL_OpenGamepad(id)
    if (value==null) { return err(sdl_error("SDL_OpenGamepad"),type<SDL_Gamepad?>) }
    return <- move_ok(value,type<SdlError>)
}
def public with_gamepad(id : uint; body : block<(device : SDL_Gamepad?) : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    let device=SDL_OpenGamepad(id)
    if (device==null) { return err(sdl_error("SDL_OpenGamepad"),type<TT>) }
    {
        defer() { SDL_CloseGamepad(device) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { scope_result=body(device) }
        else { scope_result <- body(device) }
    }
    return <- scope_result
}
def public gamepad_name(device : SDL_Gamepad?) {
    var value : string
    if (!SDL_GetGamepadNameValue(device,value)) { return err(sdl_error("SDL_GetGamepadNameValue"),type<string>) }
    return ok(value,type<SdlError>)
}
def public gamepad_path(device : SDL_Gamepad?) {
    var value : string
    if (!SDL_GetGamepadPathValue(device,value)) { return none(type<string>) }
    return some(value)
}
def public gamepad_serial(device : SDL_Gamepad?) {
    var value : string
    if (!SDL_GetGamepadSerialValue(device,value)) { return none(type<string>) }
    return some(value)
}
def public rumble_gamepad(device : SDL_Gamepad?; low,high : uint; duration : uint) { return sdl_status(SDL_RumbleGamepad(device,low,high,duration),"SDL_RumbleGamepad") }
def public rumble_gamepad_triggers(device : SDL_Gamepad?; left,right : uint; duration : uint) { return sdl_status(SDL_RumbleGamepadTriggers(device,left,right,duration),"SDL_RumbleGamepadTriggers") }
def public set_gamepad_led(device : SDL_Gamepad?; red,green,blue : uint) { return sdl_status(SDL_SetGamepadLED(device,red,green,blue),"SDL_SetGamepadLED") }
def public send_gamepad_effect(device : SDL_Gamepad?; data : array<uint8>) { return sdl_status(SDL_SendGamepadEffectArray(device,data),"SDL_SendGamepadEffect") }
def public with_joysticks_lock(body : block<() : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    SDL_LockJoysticks()
    {
        defer() { SDL_UnlockJoysticks() }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { scope_result=body() }
        else { scope_result <- body() }
    }
    return <- scope_result
}
def public attach_virtual_joystick(desc : SDL_VirtualJoystickDesc; name : string;
        touchpads : array<SDL_VirtualJoystickTouchpadDesc>; sensors : array<SDL_VirtualJoystickSensorDesc>) {
    let id=SDL_AttachVirtualJoystickArrays(desc,name,touchpads,sensors)
    if (id==0u) { return err(sdl_error("SDL_AttachVirtualJoystick"),type<uint>) }
    return ok(id,type<SdlError>)
}
def public with_virtual_joystick(desc : SDL_VirtualJoystickDesc; name : string;
        touchpads : array<SDL_VirtualJoystickTouchpadDesc>; sensors : array<SDL_VirtualJoystickSensorDesc>;
        body : block<(id : uint) : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    let id=SDL_AttachVirtualJoystickArrays(desc,name,touchpads,sensors)
    if (id==0u) { return err(sdl_error("SDL_AttachVirtualJoystick"),type<TT>) }
    {
        defer() { if (!SDL_DetachVirtualJoystick(id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_DetachVirtualJoystick"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { scope_result=body(id) }
        else { scope_result <- body(id) }
    }
    return <- scope_result
}
def public gamepad_mapping(device : SDL_Gamepad?) {
    var value : string
    if (!SDL_GetGamepadMappingValue(device,value)) { return err(sdl_error("SDL_GetGamepadMapping"),type<string>) }
    return ok(value,type<SdlError>)
}
def public add_gamepad_mapping(mapping : string) {
    let status=SDL_AddGamepadMapping(mapping)
    if (status<0) { return err(sdl_error("SDL_AddGamepadMapping"),type<bool>) }
    return ok(status>0,type<SdlError>)
}
def public joystick_axis_initial_state(device : SDL_Joystick?; axis : int) {
    var value : int
    if (!SDL_GetJoystickAxisInitialStateRef(device,axis,value)) { return none(type<int>) }
    return some(value)
}
def public joystick_ball(device : SDL_Joystick?; ball : int) {
    var value : int2
    if (!SDL_GetJoystickBallRef(device,ball,value.x,value.y)) { return err(sdl_error("SDL_GetJoystickBall"),type<int2>) }
    return ok(value,type<SdlError>)
}
def public gamepad_touchpad_finger(device : SDL_Gamepad?; pad,finger : int;
        var down : bool&; var position : float2&; var pressure : float&) {
    return sdl_status(SDL_GetGamepadTouchpadFingerRef(device,pad,finger,down,position.x,position.y,pressure),"SDL_GetGamepadTouchpadFinger")
}
def public gamepad_sensor_data(device : SDL_Gamepad?; sensor : SDL_SensorType; count : int = 3) {
    var values : array<float>
    if (count<=0) { return err(SdlError(operation="SDL_GetGamepadSensorData",message="Sensor count must be positive"),type<array<float>>) }
    resize(values,count)
    if (!SDL_GetGamepadSensorDataArray(device,sensor,values)) { return err(sdl_error("SDL_GetGamepadSensorData"),type<array<float>>) }
    return <- move_ok(values,type<SdlError>)
}
def public send_virtual_sensor_data(device : SDL_Joystick?; sensor : SDL_SensorType; timestamp : uint64; data : array<float>) {
    return sdl_status(SDL_SendJoystickVirtualSensorDataArray(device,sensor,timestamp,data),"SDL_SendJoystickVirtualSensorData")
}

struct GamepadTouchpadFinger { down : bool; position : float2; pressure : float }
def public gamepad_touchpad_finger(device : SDL_Gamepad?; pad,finger : int) {
    var value : GamepadTouchpadFinger
    let status=gamepad_touchpad_finger(device,pad,finger,value.down,value.position,value.pressure)
    if(is_err(status)) { return err(unwrap_err(status),type<GamepadTouchpadFinger>) }
    return ok(value,type<SdlError>)
}
