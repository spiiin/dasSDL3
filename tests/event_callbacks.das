options gen2
require dassdl3/sdl3_event_queue
require dassdl3/sdl3_scope
require daslib/defer

def code_of(event : SDL_Event) : int { return (decode_event(event) as user).code }

[export]
def main(smoke : bool) : int {
    let result = with_sdl() {
        SDL_FlushEvents(SDL_EVENT_FIRST,SDL_EVENT_LAST)
        let first = register_events(1) |> sdl_try
        let native_filter = SDLTestEventFilterAddress()
        let watch = SDLTestEventWatchAddress()
        let cookie = SDLTestEventCookie()
        var previous : void?; var previous_data : void?
        unsafe { verify(!SDL_GetEventFilter(addr(previous),addr(previous_data))) }
        {
            defer() { SDL_SetEventFilter(previous,previous_data) }
            SDL_SetEventFilter(native_filter,cookie)
            var found : void?; var data : void?
            unsafe { verify(SDL_GetEventFilter(addr(found),addr(data))) }
            verify(found == native_filter && data == cookie)
            verify(SDL_GetEventFilterRef(found,data) && found == native_filter && data == cookie)
            var rejected = SDL_MakeUserEvent(first,0u,-1)
            verify(!push_event(rejected))
            verify(SDL_AddEventWatch(watch,cookie))
            {
                defer() { SDL_RemoveEventWatch(watch,cookie) }
                let before = SDLTestEventWatchCount()
                verify(SDLTestEventPushWorker(first,2))
                verify(SDLTestEventWatchCount() == before+1)
                var event = SDL_MakeEvent()
                var queued : array<SDL_Event>; resize(queued,1)
                verify(unwrap(peep_events(queued,SDL_EventAction.GETEVENT,first,first)) == 1)
                verify(code_of(queued[0]) == 12)
                // ADDEVENT bypasses both callbacks.
                queued[0] = SDL_MakeUserEvent(first,0u,3)
                verify(unwrap(peep_events(queued,SDL_EventAction.ADDEVENT)) == 1)
                verify(SDLTestEventWatchCount() == before+1)
            }
            let after = SDLTestEventWatchCount()
            verify(SDLTestEventPushWorker(first,4))
            verify(SDLTestEventWatchCount() == after)
            SDL_SetEventFilter(null,null)
            verify(!SDL_GetEventFilterRef(found,data) && found == null && data == null)
            SDL_FilterEvents(native_filter,cookie)
            var queued <- take_events(8,first,first) |> sdl_try
            verify(length(queued)==2 && (queued[0] as user).code==13 && (queued[1] as user).code==24)
        }
        // Script predicate edits borrowed queue entries; false is a normal removal.
        for (code in 0 .. 4) {
            var event = SDL_MakeUserEvent(first,0u,code)
            verify(push_event(event))
        }
        var calls = 0
        SDL_SetErrorText("old error")
        filter_events() $(var event : SDL_Event) {
            if (event.event_type != first) { return true }
            calls++
            let code = code_of(event)
            if (code % 2 != 0) { return false }
            event = SDL_MakeUserEvent(first,0u,code+100)
            return true
        } |> sdl_try
        verify(calls == 4)
        let kept <- take_events(8,first,first) |> sdl_try
        verify(length(kept)==2 && (kept[0] as user).code==100 && (kept[1] as user).code==102)
        filter_events() $(var event : SDL_Event) { calls++; return false } |> sdl_try
        verify(calls==4)
        return sdl_ok()
    }
    verify(is_ok(result))
    print("Events native callbacks and synchronous script filtering passed\n")
    return 0
}
