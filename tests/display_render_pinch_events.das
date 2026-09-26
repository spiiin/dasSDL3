options gen2
require dassdl3/sdl3_event_queue
require daslib/match
require dassdl3/sdl3_try

def check(event : SdlEvent) : uint {
    match(event) {
        if(SdlEvent(display=$v(v))) {
            verify(v.timestamp==0xfedcba9876543210ul && v.display_id==0xf1234567u)
            verify(v.data==int2(-123,456))
            return v.event_type
        }
        if(SdlEvent(render_targets_reset=$v(v))) {
            verify(v.timestamp==0xfedcba9876543210ul && v.window_id==0xf1234567u)
            return SDL_EVENT_RENDER_TARGETS_RESET
        }
        if(SdlEvent(render_device_reset=$v(v))) {
            verify(v.timestamp==0xfedcba9876543210ul && v.window_id==0xf1234567u)
            return SDL_EVENT_RENDER_DEVICE_RESET
        }
        if(SdlEvent(render_device_lost=$v(v))) {
            verify(v.timestamp==0xfedcba9876543210ul && v.window_id==0xf1234567u)
            return SDL_EVENT_RENDER_DEVICE_LOST
        }
        if(SdlEvent(pinch_begin=$v(v))) {
            verify(v.timestamp==0xfedcba9876543210ul && v.window_id==0xf1234567u)
            verify(v.scale==0.75)
            return SDL_EVENT_PINCH_BEGIN
        }
        if(SdlEvent(pinch_update=$v(v))) {
            verify(v.timestamp==0xfedcba9876543210ul && v.window_id==0xf1234567u)
            verify(v.scale==0.75)
            return SDL_EVENT_PINCH_UPDATE
        }
        if(SdlEvent(pinch_end=$v(v))) {
            verify(v.timestamp==0xfedcba9876543210ul && v.window_id==0xf1234567u)
            verify(v.scale==0.75)
            return SDL_EVENT_PINCH_END
        }
        if(_) {return 0u}
    }
    return 0u
}
[export]
def main(smoke : bool) : int {
    let result=with_sdl(SDL_INIT_EVENTS) {
        SDL_FlushEvents(0u,65535u)
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_DISPLAY_ORIENTATION)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_DISPLAY_ORIENTATION)
            var queued <- take_events(1,SDL_EVENT_DISPLAY_ORIENTATION,SDL_EVENT_DISPLAY_ORIENTATION) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_DISPLAY_ORIENTATION)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_DISPLAY_ADDED)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_DISPLAY_ADDED)
            var queued <- take_events(1,SDL_EVENT_DISPLAY_ADDED,SDL_EVENT_DISPLAY_ADDED) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_DISPLAY_ADDED)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_DISPLAY_REMOVED)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_DISPLAY_REMOVED)
            var queued <- take_events(1,SDL_EVENT_DISPLAY_REMOVED,SDL_EVENT_DISPLAY_REMOVED) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_DISPLAY_REMOVED)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_DISPLAY_MOVED)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_DISPLAY_MOVED)
            var queued <- take_events(1,SDL_EVENT_DISPLAY_MOVED,SDL_EVENT_DISPLAY_MOVED) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_DISPLAY_MOVED)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED)
            var queued <- take_events(1,SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED,SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_DISPLAY_DESKTOP_MODE_CHANGED)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED)
            var queued <- take_events(1,SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED,SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_DISPLAY_CURRENT_MODE_CHANGED)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED)
            var queued <- take_events(1,SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED,SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_DISPLAY_CONTENT_SCALE_CHANGED)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED)
            var queued <- take_events(1,SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED,SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_DISPLAY_USABLE_BOUNDS_CHANGED)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_RENDER_TARGETS_RESET)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_RENDER_TARGETS_RESET)
            var queued <- take_events(1,SDL_EVENT_RENDER_TARGETS_RESET,SDL_EVENT_RENDER_TARGETS_RESET) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_RENDER_TARGETS_RESET)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_RENDER_DEVICE_RESET)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_RENDER_DEVICE_RESET)
            var queued <- take_events(1,SDL_EVENT_RENDER_DEVICE_RESET,SDL_EVENT_RENDER_DEVICE_RESET) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_RENDER_DEVICE_RESET)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_RENDER_DEVICE_LOST)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_RENDER_DEVICE_LOST)
            var queued <- take_events(1,SDL_EVENT_RENDER_DEVICE_LOST,SDL_EVENT_RENDER_DEVICE_LOST) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_RENDER_DEVICE_LOST)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_PINCH_BEGIN)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_PINCH_BEGIN)
            var queued <- take_events(1,SDL_EVENT_PINCH_BEGIN,SDL_EVENT_PINCH_BEGIN) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_PINCH_BEGIN)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_PINCH_UPDATE)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_PINCH_UPDATE)
            var queued <- take_events(1,SDL_EVENT_PINCH_UPDATE,SDL_EVENT_PINCH_UPDATE) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_PINCH_UPDATE)
        }
        {
            var raw=SDLTestCommonEvent(SDL_EVENT_PINCH_END)
            var value <- decode_event(raw)
            verify(SDL_PushEventRef(raw))
            raw=SDL_MakeEvent()
            verify(check(value)==SDL_EVENT_PINCH_END)
            var queued <- take_events(1,SDL_EVENT_PINCH_END,SDL_EVENT_PINCH_END) |> sdl_try
            verify(length(queued)==1 && check(queued[0])==SDL_EVENT_PINCH_END)
        }
        var wrong_display : SDL_DisplayEvent
        wrong_display.timestamp=9ul
        verify(!SDL_ReadDisplayEvent(SDL_MakeEvent(),wrong_display))
        verify(wrong_display.timestamp==0ul)
        var wrong_render : SDL_RenderEvent
        wrong_render.timestamp=9ul
        verify(!SDL_ReadRenderEvent(SDL_MakeEvent(),wrong_render))
        verify(wrong_render.timestamp==0ul)
        var wrong_pinch : SDL_PinchFingerEvent
        wrong_pinch.timestamp=9ul
        verify(!SDL_ReadPinchEvent(SDL_MakeEvent(),wrong_pinch))
        verify(wrong_pinch.timestamp==0ul)
        return sdl_ok()
    }
    verify(is_ok(result))
    print("Display/render/pinch: all 14 native tags, owned copies and queue passed.\n")
    return 0
}
