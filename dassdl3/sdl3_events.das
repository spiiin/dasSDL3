options gen2
module sdl3_events shared public
require dassdl3/sdl3_boost public

struct QuitEvent {
    timestamp : uint64
}
struct KeyEvent {
    timestamp : uint64
    window_id, which : uint
    scancode : int
    keycode : uint
    modifiers, raw : uint16
    repeat : bool
}
struct MouseMotionEvent {
    timestamp : uint64
    window_id, which, buttons : uint
    position, delta : float2
}
struct MouseButtonEvent {
    timestamp : uint64
    window_id, which : uint
    button, clicks : uint8
    position : float2
}
struct MouseWheelEvent {
    timestamp : uint64
    window_id, which : uint
    delta, position : float2
    integer_delta : int2
    flipped : bool
}
struct TextInputEvent {
    timestamp : uint64
    window_id : uint
    text : string
}
struct TextEditingEvent {
    timestamp : uint64
    window_id : uint
    text : string
    start, length : int
}
struct WindowEvent {
    timestamp : uint64
    event_type, window_id : uint
    data : int2
}
struct UnknownEvent {
    event_type : uint
    timestamp : uint64
}
struct DropEvent {
    timestamp : uint64
    window_id : uint
    position : float2
    source, data : string
}
// Metadata only: application-defined data1/data2 pointers stay in raw SDL_Event.
struct UserEvent {
    timestamp : uint64
    event_type, window_id : uint
    code : int
}
struct JoystickAxisEvent {
    timestamp : uint64
    which : uint
    axis : uint8
    value : int16
}
struct JoystickBallEvent {
    timestamp : uint64
    which : uint
    ball : uint8
    delta : int2
}
struct JoystickHatEvent {
    timestamp : uint64
    which : uint
    hat, value : uint8
}
struct JoystickButtonEvent {
    timestamp : uint64
    which : uint
    button : uint8
}
struct JoystickDeviceEvent {
    timestamp : uint64
    which : uint
}
struct JoystickBatteryEvent {
    timestamp : uint64
    which : uint
    state : SDL_PowerState
    percent : int
}
struct GamepadAxisEvent {
    timestamp : uint64
    which : uint
    axis : SDL_GamepadAxis
    value : int16
}
struct GamepadButtonEvent {
    timestamp : uint64
    which : uint
    button : SDL_GamepadButton
}
struct GamepadDeviceEvent {
    timestamp : uint64
    which : uint
}
struct GamepadTouchpadEvent {
    timestamp : uint64
    which : uint
    touchpad, finger : int
    position : float2
    pressure : float
}
struct GamepadSensorEvent {
    timestamp : uint64
    which : uint
    sensor : SDL_SensorType
    data : float3
    sensor_timestamp : uint64
}
struct TouchFingerEvent {
    timestamp : uint64
    touch_id, finger_id : uint64
    window_id : uint
    position, delta : float2
    pressure : float
}
struct PenProximityEvent {
    timestamp : uint64
    window_id, which : uint
}
struct PenMotionEvent {
    timestamp : uint64
    window_id, which, pen_state : uint
    position : float2
}
struct PenTouchEvent {
    timestamp : uint64
    window_id, which, pen_state : uint
    position : float2
    eraser : bool
}
struct PenButtonEvent {
    timestamp : uint64
    window_id, which, pen_state : uint
    position : float2
    button : uint8
}
struct PenAxisEvent {
    timestamp : uint64
    window_id, which, pen_state : uint
    position : float2
    axis : SDL_PenAxis
    value : float
}
struct SensorEvent {
    timestamp : uint64
    which : uint
    data : float[6]
    sensor_timestamp : uint64
}
struct TextEditingCandidatesEvent {
    timestamp : uint64
    window_id : uint
    candidates : array<string>
    selected_candidate : int
    horizontal : bool
}
struct ClipboardEvent {
    timestamp : uint64
    owner : bool
    mime_types : array<string>
}
variant SdlEvent {
    unknown : UnknownEvent
    text_editing_candidates : TextEditingCandidatesEvent
    clipboard_update : ClipboardEvent
    quit : QuitEvent
    key_down : KeyEvent
    key_up : KeyEvent
    mouse_motion : MouseMotionEvent
    mouse_button_down : MouseButtonEvent
    mouse_button_up : MouseButtonEvent
    mouse_wheel : MouseWheelEvent
    text_input : TextInputEvent
    text_editing : TextEditingEvent
    window : WindowEvent
    drop_begin : DropEvent
    drop_file : DropEvent
    drop_text : DropEvent
    drop_complete : DropEvent
    drop_position : DropEvent
    user : UserEvent
    finger_down : TouchFingerEvent
    finger_up : TouchFingerEvent
    finger_motion : TouchFingerEvent
    finger_canceled : TouchFingerEvent
    pen_proximity_in : PenProximityEvent
    pen_proximity_out : PenProximityEvent
    pen_motion : PenMotionEvent
    pen_down : PenTouchEvent
    pen_up : PenTouchEvent
    pen_button_down : PenButtonEvent
    pen_button_up : PenButtonEvent
    pen_axis : PenAxisEvent
    sensor_update : SensorEvent
    joystick_axis_motion : JoystickAxisEvent
    joystick_ball_motion : JoystickBallEvent
    joystick_hat_motion : JoystickHatEvent
    joystick_button_down : JoystickButtonEvent
    joystick_button_up : JoystickButtonEvent
    joystick_added : JoystickDeviceEvent
    joystick_removed : JoystickDeviceEvent
    joystick_update_complete : JoystickDeviceEvent
    joystick_battery_updated : JoystickBatteryEvent
    gamepad_axis_motion : GamepadAxisEvent
    gamepad_button_down : GamepadButtonEvent
    gamepad_button_up : GamepadButtonEvent
    gamepad_added : GamepadDeviceEvent
    gamepad_removed : GamepadDeviceEvent
    gamepad_remapped : GamepadDeviceEvent
    gamepad_update_complete : GamepadDeviceEvent
    gamepad_steam_handle_updated : GamepadDeviceEvent
    gamepad_touchpad_down : GamepadTouchpadEvent
    gamepad_touchpad_motion : GamepadTouchpadEvent
    gamepad_touchpad_up : GamepadTouchpadEvent
    gamepad_sensor_update : GamepadSensorEvent
}

// Decode immediately while pointer-bearing SDL payloads are still valid.
// No native pointer is retained in the returned variant.
def public decode_event(event : SDL_Event) : SdlEvent {
    let kind = event.event_type
    let timestamp = SDL_EventTimestamp(event)
    if (kind == SDL_EVENT_QUIT) { return <- SdlEvent(quit=QuitEvent(timestamp=timestamp)) }
    if (kind == SDL_EVENT_KEY_DOWN || kind == SDL_EVENT_KEY_UP) {
        var key : SDL_KeyboardEvent
        SDL_ReadKeyEvent(event,key)
        let value = KeyEvent(timestamp=timestamp,window_id=key.windowID,which=key.which,
            scancode=SDL_KeyScancode(key),keycode=key.key,modifiers=key.mod,raw=key.raw,repeat=key.repeat)
        if (kind == SDL_EVENT_KEY_DOWN) { return <- SdlEvent(key_down=value) }
        return <- SdlEvent(key_up=value)
    }
    if (kind == SDL_EVENT_MOUSE_MOTION) {
        var motion : SDL_MouseMotionEvent
        SDL_ReadMouseMotionEvent(event,motion)
        return <- SdlEvent(mouse_motion=MouseMotionEvent(timestamp=timestamp,window_id=motion.windowID,
            which=motion.which,buttons=motion.state,position=float2(motion.x,motion.y),delta=float2(motion.xrel,motion.yrel)))
    }
    if (kind == SDL_EVENT_MOUSE_BUTTON_DOWN || kind == SDL_EVENT_MOUSE_BUTTON_UP) {
        var button : SDL_MouseButtonEvent
        SDL_ReadMouseButtonEvent(event,button)
        let value = MouseButtonEvent(timestamp=timestamp,window_id=button.windowID,which=button.which,
            button=button.button,clicks=button.clicks,position=float2(button.x,button.y))
        if (kind == SDL_EVENT_MOUSE_BUTTON_DOWN) { return <- SdlEvent(mouse_button_down=value) }
        return <- SdlEvent(mouse_button_up=value)
    }
    if (kind == SDL_EVENT_MOUSE_WHEEL) {
        var wheel : SDL_MouseWheelEvent
        SDL_ReadMouseWheelEvent(event,wheel)
        return <- SdlEvent(mouse_wheel=MouseWheelEvent(timestamp=timestamp,window_id=wheel.windowID,which=wheel.which,
            delta=float2(wheel.x,wheel.y),position=float2(wheel.mouse_x,wheel.mouse_y),
            integer_delta=int2(wheel.integer_x,wheel.integer_y),flipped=SDL_MouseWheelFlipped(wheel)))
    }
    if (kind == SDL_EVENT_TEXT_INPUT) {
        var text : string
        SDL_ReadTextInput(event,text)
        return <- SdlEvent(text_input=TextInputEvent(timestamp=timestamp,window_id=SDL_InputWindowID(event),text=text))
    }
    if (kind == SDL_EVENT_TEXT_EDITING) {
        var text : string
        var start, length : int
        SDL_ReadTextEditing(event,text,start,length)
        return <- SdlEvent(text_editing=TextEditingEvent(timestamp=timestamp,window_id=SDL_InputWindowID(event),
            text=text,start=start,length=length))
    }
    if (kind == SDL_EVENT_JOYSTICK_AXIS_MOTION) {
        var v : SDL_JoyAxisEvent
        SDL_ReadJoyAxisEvent(event,v)
        let value = JoystickAxisEvent(timestamp=timestamp,which=v.which,axis=v.axis,value=v.value)
        return <- SdlEvent(joystick_axis_motion=value)
    }
    if (kind == SDL_EVENT_JOYSTICK_BALL_MOTION) {
        var v : SDL_JoyBallEvent
        SDL_ReadJoyBallEvent(event,v)
        let value = JoystickBallEvent(timestamp=timestamp,which=v.which,ball=v.ball,delta=int2(int(v.xrel),int(v.yrel)))
        return <- SdlEvent(joystick_ball_motion=value)
    }
    if (kind == SDL_EVENT_JOYSTICK_HAT_MOTION) {
        var v : SDL_JoyHatEvent
        SDL_ReadJoyHatEvent(event,v)
        let value = JoystickHatEvent(timestamp=timestamp,which=v.which,hat=v.hat,value=v.value)
        return <- SdlEvent(joystick_hat_motion=value)
    }
    if (kind == SDL_EVENT_JOYSTICK_BUTTON_DOWN || kind == SDL_EVENT_JOYSTICK_BUTTON_UP) {
        var v : SDL_JoyButtonEvent
        SDL_ReadJoyButtonEvent(event,v)
        let value = JoystickButtonEvent(timestamp=timestamp,which=v.which,button=v.button)
        if (kind == SDL_EVENT_JOYSTICK_BUTTON_DOWN) { return <- SdlEvent(joystick_button_down=value) }
        return <- SdlEvent(joystick_button_up=value)
    }
    if (kind == SDL_EVENT_JOYSTICK_ADDED || kind == SDL_EVENT_JOYSTICK_REMOVED || kind == SDL_EVENT_JOYSTICK_UPDATE_COMPLETE) {
        var v : SDL_JoyDeviceEvent
        SDL_ReadJoyDeviceEvent(event,v)
        let value = JoystickDeviceEvent(timestamp=timestamp,which=v.which)
        if (kind == SDL_EVENT_JOYSTICK_ADDED) { return <- SdlEvent(joystick_added=value) }
        if (kind == SDL_EVENT_JOYSTICK_REMOVED) { return <- SdlEvent(joystick_removed=value) }
        return <- SdlEvent(joystick_update_complete=value)
    }
    if (kind == SDL_EVENT_JOYSTICK_BATTERY_UPDATED) {
        var v : SDL_JoyBatteryEvent
        SDL_ReadJoyBatteryEvent(event,v)
        let value = JoystickBatteryEvent(timestamp=timestamp,which=v.which,state=v.state,percent=v.percent)
        return <- SdlEvent(joystick_battery_updated=value)
    }
    if (kind == SDL_EVENT_GAMEPAD_AXIS_MOTION) {
        var v : SDL_GamepadAxisEvent
        SDL_ReadGamepadAxisEvent(event,v)
        let value = GamepadAxisEvent(timestamp=timestamp,which=v.which,axis=unsafe(reinterpret<SDL_GamepadAxis>(int(v.axis))),value=v.value)
        return <- SdlEvent(gamepad_axis_motion=value)
    }
    if (kind == SDL_EVENT_GAMEPAD_BUTTON_DOWN || kind == SDL_EVENT_GAMEPAD_BUTTON_UP) {
        var v : SDL_GamepadButtonEvent
        SDL_ReadGamepadButtonEvent(event,v)
        let value = GamepadButtonEvent(timestamp=timestamp,which=v.which,button=unsafe(reinterpret<SDL_GamepadButton>(int(v.button))))
        if (kind == SDL_EVENT_GAMEPAD_BUTTON_DOWN) { return <- SdlEvent(gamepad_button_down=value) }
        return <- SdlEvent(gamepad_button_up=value)
    }
    if (kind == SDL_EVENT_GAMEPAD_ADDED || kind == SDL_EVENT_GAMEPAD_REMOVED || kind == SDL_EVENT_GAMEPAD_REMAPPED || kind == SDL_EVENT_GAMEPAD_UPDATE_COMPLETE || kind == SDL_EVENT_GAMEPAD_STEAM_HANDLE_UPDATED) {
        var v : SDL_GamepadDeviceEvent
        SDL_ReadGamepadDeviceEvent(event,v)
        let value = GamepadDeviceEvent(timestamp=timestamp,which=v.which)
        if (kind == SDL_EVENT_GAMEPAD_ADDED) { return <- SdlEvent(gamepad_added=value) }
        if (kind == SDL_EVENT_GAMEPAD_REMOVED) { return <- SdlEvent(gamepad_removed=value) }
        if (kind == SDL_EVENT_GAMEPAD_REMAPPED) { return <- SdlEvent(gamepad_remapped=value) }
        if (kind == SDL_EVENT_GAMEPAD_UPDATE_COMPLETE) { return <- SdlEvent(gamepad_update_complete=value) }
        return <- SdlEvent(gamepad_steam_handle_updated=value)
    }
    if (kind == SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN || kind == SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION || kind == SDL_EVENT_GAMEPAD_TOUCHPAD_UP) {
        var v : SDL_GamepadTouchpadEvent
        SDL_ReadGamepadTouchpadEvent(event,v)
        let value = GamepadTouchpadEvent(timestamp=timestamp,which=v.which,touchpad=v.touchpad,finger=v.finger,position=float2(v.x,v.y),pressure=v.pressure)
        if (kind == SDL_EVENT_GAMEPAD_TOUCHPAD_DOWN) { return <- SdlEvent(gamepad_touchpad_down=value) }
        if (kind == SDL_EVENT_GAMEPAD_TOUCHPAD_MOTION) { return <- SdlEvent(gamepad_touchpad_motion=value) }
        return <- SdlEvent(gamepad_touchpad_up=value)
    }
    if (kind == SDL_EVENT_GAMEPAD_SENSOR_UPDATE) {
        var v : SDL_GamepadSensorEvent
        SDL_ReadGamepadSensorEvent(event,v)
        let value = GamepadSensorEvent(timestamp=timestamp,which=v.which,sensor=unsafe(reinterpret<SDL_SensorType>(int(v.sensor))),data=float3(v.data[0],v.data[1],v.data[2]),sensor_timestamp=v.sensor_timestamp)
        return <- SdlEvent(gamepad_sensor_update=value)
    }
    if (kind==SDL_EVENT_FINGER_DOWN || kind==SDL_EVENT_FINGER_UP || kind==SDL_EVENT_FINGER_MOTION || kind==SDL_EVENT_FINGER_CANCELED) {
        var v : SDL_TouchFingerEvent
        SDL_ReadTouchFingerEvent(event,v)
        let value=TouchFingerEvent(timestamp=timestamp,touch_id=v.touchID,finger_id=v.fingerID,window_id=v.windowID,position=float2(v.x,v.y),delta=float2(v.dx,v.dy),pressure=v.pressure)
        if(kind==SDL_EVENT_FINGER_DOWN) {return <- SdlEvent(finger_down=value)}
        if(kind==SDL_EVENT_FINGER_UP) {return <- SdlEvent(finger_up=value)}
        if(kind==SDL_EVENT_FINGER_MOTION) {return <- SdlEvent(finger_motion=value)}
        return <- SdlEvent(finger_canceled=value)
    }
    if (kind==SDL_EVENT_PEN_PROXIMITY_IN || kind==SDL_EVENT_PEN_PROXIMITY_OUT) {
        var v : SDL_PenProximityEvent
        SDL_ReadPenProximityEvent(event,v)
        let value=PenProximityEvent(timestamp=timestamp,window_id=v.windowID,which=v.which)
        if(kind==SDL_EVENT_PEN_PROXIMITY_IN) {return <- SdlEvent(pen_proximity_in=value)}
        return <- SdlEvent(pen_proximity_out=value)
    }
    if (kind==SDL_EVENT_PEN_MOTION) {
        var v : SDL_PenMotionEvent
        SDL_ReadPenMotionEvent(event,v)
        let value=PenMotionEvent(timestamp=timestamp,window_id=v.windowID,which=v.which,pen_state=v.pen_state,position=float2(v.x,v.y))
        return <- SdlEvent(pen_motion=value)
    }
    if (kind==SDL_EVENT_PEN_DOWN || kind==SDL_EVENT_PEN_UP) {
        var v : SDL_PenTouchEvent
        SDL_ReadPenTouchEvent(event,v)
        let value=PenTouchEvent(timestamp=timestamp,window_id=v.windowID,which=v.which,pen_state=v.pen_state,position=float2(v.x,v.y),eraser=v.eraser)
        if(kind==SDL_EVENT_PEN_DOWN) {return <- SdlEvent(pen_down=value)}
        return <- SdlEvent(pen_up=value)
    }
    if (kind==SDL_EVENT_PEN_BUTTON_DOWN || kind==SDL_EVENT_PEN_BUTTON_UP) {
        var v : SDL_PenButtonEvent
        SDL_ReadPenButtonEvent(event,v)
        let value=PenButtonEvent(timestamp=timestamp,window_id=v.windowID,which=v.which,pen_state=v.pen_state,position=float2(v.x,v.y),button=v.button)
        if(kind==SDL_EVENT_PEN_BUTTON_DOWN) {return <- SdlEvent(pen_button_down=value)}
        return <- SdlEvent(pen_button_up=value)
    }
    if (kind==SDL_EVENT_PEN_AXIS) {
        var v : SDL_PenAxisEvent
        SDL_ReadPenAxisEvent(event,v)
        let value=PenAxisEvent(timestamp=timestamp,window_id=v.windowID,which=v.which,pen_state=v.pen_state,position=float2(v.x,v.y),axis=v.axis,value=v.value)
        return <- SdlEvent(pen_axis=value)
    }
    if (kind==SDL_EVENT_SENSOR_UPDATE) {
        var v : SDL_SensorEvent
        SDL_ReadSensorEvent(event,v)
        let value=SensorEvent(timestamp=timestamp,which=v.which,data=v.data,sensor_timestamp=v.sensor_timestamp)
        return <- SdlEvent(sensor_update=value)
    }
    if(kind==SDL_EVENT_TEXT_EDITING_CANDIDATES) {
        var info : SDL_TextEditingCandidatesEvent
        var strings : array<string>
        if(SDL_ReadTextEditingCandidatesEvent(event,info,strings)) {
            var value <- TextEditingCandidatesEvent(timestamp=timestamp,window_id=info.windowID,
                candidates <- strings,selected_candidate=info.selected_candidate,horizontal=info.horizontal)
            return <- SdlEvent(text_editing_candidates <- value)
        }
        return <- SdlEvent(unknown=UnknownEvent(event_type=kind,timestamp=timestamp))
    }
    if(kind==SDL_EVENT_CLIPBOARD_UPDATE) {
        var info : SDL_ClipboardEvent
        var strings : array<string>
        if(SDL_ReadClipboardEvent(event,info,strings)) {
            var value <- ClipboardEvent(timestamp=timestamp,owner=info.owner,mime_types <- strings)
            return <- SdlEvent(clipboard_update <- value)
        }
        return <- SdlEvent(unknown=UnknownEvent(event_type=kind,timestamp=timestamp))
    }
    var data : int2
    if (SDL_ReadWindowEventData(event,data)) {
        return <- SdlEvent(window=WindowEvent(timestamp=timestamp,event_type=kind,window_id=SDL_InputWindowID(event),data=data))
    }
    var window_id : uint
    var code : int
    if (SDL_ReadUserEvent(event,window_id,code)) {
        return <- SdlEvent(user=UserEvent(timestamp=timestamp,event_type=kind,window_id=window_id,code=code))
    }
    var position : float2
    var source, text : string
    if (SDL_ReadDropEvent(event,window_id,position,source,text)) {
        let value = DropEvent(timestamp=timestamp,window_id=window_id,position=position,source=source,data=text)
        if (kind == SDL_EVENT_DROP_BEGIN) { return <- SdlEvent(drop_begin=value) }
        if (kind == SDL_EVENT_DROP_FILE) { return <- SdlEvent(drop_file=value) }
        if (kind == SDL_EVENT_DROP_TEXT) { return <- SdlEvent(drop_text=value) }
        if (kind == SDL_EVENT_DROP_COMPLETE) { return <- SdlEvent(drop_complete=value) }
        return <- SdlEvent(drop_position=value)
    }
    return <- SdlEvent(unknown=UnknownEvent(event_type=kind,timestamp=timestamp))
}

// None means the queue is empty, not an SDL failure (including stale SDL errors).
def public poll_event() : $Option<SdlEvent> {
    var event = SDL_MakeEvent()
    if (!SDL_PollEventRef(event)) { return <- none(type<SdlEvent>) }
    var decoded <- decode_event(event)
    return <- move_some(decoded)
}

// Lazy: consumes one owned event per iteration. Breaking leaves later events queued.
def public poll_events() : iterator<SdlEvent> {
    return <- generator<SdlEvent> {
        while (true) {
            var next_event <- poll_event()
            if (is_none(next_event)) { return false }
            var event <- move_unwrap(next_event)
            yield <- event
        }
        return false
    }
}

// Matches the raw overload: quit or Escape key-down.
def public should_close(event : SdlEvent) : bool {
    if(event is quit) { return true }
    if(event is key_down) { return (event as key_down).keycode==SDLK_ESCAPE }
    return false
}
def public should_close(event : SdlEvent; window : SDL_Window?) : bool {
    if(event is quit) { return true }
    let id=SDL_GetWindowID(window)
    if(event is key_down) {
        let key=event as key_down
        return key.window_id==id && key.keycode==SDLK_ESCAPE
    }
    if(event is window) {
        let value=event as window
        return value.window_id==id && value.event_type==SDL_EVENT_WINDOW_CLOSE_REQUESTED
    }
    return false
}
