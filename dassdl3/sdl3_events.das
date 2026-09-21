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
variant SdlEvent {
    unknown : UnknownEvent
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
}

// Decode immediately while pointer-bearing SDL payloads are still valid.
// No native pointer is retained in the returned variant.
def public decode_event(event : SDL_Event) : SdlEvent {
    let kind = event.event_type
    let timestamp = SDL_EventTimestamp(event)
    if (kind == SDL_EVENT_QUIT) { return SdlEvent(quit=QuitEvent(timestamp=timestamp)) }
    if (kind == SDL_EVENT_KEY_DOWN || kind == SDL_EVENT_KEY_UP) {
        var key : SDL_KeyboardEvent
        SDL_ReadKeyEvent(event,key)
        let value = KeyEvent(timestamp=timestamp,window_id=key.windowID,which=key.which,
            scancode=SDL_KeyScancode(key),keycode=key.key,modifiers=key.mod,raw=key.raw,repeat=key.repeat)
        return kind == SDL_EVENT_KEY_DOWN ? SdlEvent(key_down=value) : SdlEvent(key_up=value)
    }
    if (kind == SDL_EVENT_MOUSE_MOTION) {
        var motion : SDL_MouseMotionEvent
        SDL_ReadMouseMotionEvent(event,motion)
        return SdlEvent(mouse_motion=MouseMotionEvent(timestamp=timestamp,window_id=motion.windowID,
            which=motion.which,buttons=motion.state,position=float2(motion.x,motion.y),delta=float2(motion.xrel,motion.yrel)))
    }
    if (kind == SDL_EVENT_MOUSE_BUTTON_DOWN || kind == SDL_EVENT_MOUSE_BUTTON_UP) {
        var button : SDL_MouseButtonEvent
        SDL_ReadMouseButtonEvent(event,button)
        let value = MouseButtonEvent(timestamp=timestamp,window_id=button.windowID,which=button.which,
            button=button.button,clicks=button.clicks,position=float2(button.x,button.y))
        return kind == SDL_EVENT_MOUSE_BUTTON_DOWN ? SdlEvent(mouse_button_down=value) : SdlEvent(mouse_button_up=value)
    }
    if (kind == SDL_EVENT_MOUSE_WHEEL) {
        var wheel : SDL_MouseWheelEvent
        SDL_ReadMouseWheelEvent(event,wheel)
        return SdlEvent(mouse_wheel=MouseWheelEvent(timestamp=timestamp,window_id=wheel.windowID,which=wheel.which,
            delta=float2(wheel.x,wheel.y),position=float2(wheel.mouse_x,wheel.mouse_y),
            integer_delta=int2(wheel.integer_x,wheel.integer_y),flipped=SDL_MouseWheelFlipped(wheel)))
    }
    if (kind == SDL_EVENT_TEXT_INPUT) {
        var text : string
        SDL_ReadTextInput(event,text)
        return SdlEvent(text_input=TextInputEvent(timestamp=timestamp,window_id=SDL_InputWindowID(event),text=text))
    }
    if (kind == SDL_EVENT_TEXT_EDITING) {
        var text : string
        var start, length : int
        SDL_ReadTextEditing(event,text,start,length)
        return SdlEvent(text_editing=TextEditingEvent(timestamp=timestamp,window_id=SDL_InputWindowID(event),
            text=text,start=start,length=length))
    }
    var data : int2
    if (SDL_ReadWindowEventData(event,data)) {
        return SdlEvent(window=WindowEvent(timestamp=timestamp,event_type=kind,window_id=SDL_InputWindowID(event),data=data))
    }
    return SdlEvent(unknown=UnknownEvent(event_type=kind,timestamp=timestamp))
}

// None means the queue is empty, not an SDL failure (including stale SDL errors).
def public poll_event() : $Option<SdlEvent> {
    var event = SDL_MakeEvent()
    if (!SDL_PollEventRef(event)) { return none(type<SdlEvent>) }
    return some(decode_event(event))
}
