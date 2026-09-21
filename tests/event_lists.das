options gen2
require dassdl3/sdl3_event_queue
require dassdl3/sdl3_scope
require daslib/match

def check(e : SdlEvent) : uint {
    match(e) {
        if(SdlEvent(text_editing_candidates=$v(v))) {
            verify(v.timestamp==0xfedcba9876543210ul && v.window_id==42u && v.selected_candidate==2 && v.horizontal)
            verify(length(v.candidates)==3 && v.candidates[0]=="日本 🌍" && v.candidates[1]=="second" && v.candidates[2]=="")
            return SDL_EVENT_TEXT_EDITING_CANDIDATES
        }
        if(SdlEvent(clipboard_update=$v(v))) {
            verify(v.timestamp==0xfedcba9876543210ul && v.owner)
            verify(length(v.mime_types)==3 && v.mime_types[0]=="text/plain;charset=utf-8" && v.mime_types[1]=="application/x-dassdl3" && v.mime_types[2]=="")
            return SDL_EVENT_CLIPBOARD_UPDATE
        }
        if(_) {verify(false);return 0u}
    }
}

def shapes() {
    var strings <- array<string>("old")
    var ime : SDL_TextEditingCandidatesEvent
    var clipboard : SDL_ClipboardEvent
    var wrong=SDLTestListEvent(SDL_EVENT_TEXT_EDITING_CANDIDATES,4)
    wrong.event_type=SDL_EVENT_QUIT // poisoned inactive pointers must not be touched
    verify(!SDL_ReadTextEditingCandidatesEvent(wrong,ime,strings) && empty(strings) && ime.timestamp==0ul)
    push(strings,"old")
    verify(!SDL_ReadClipboardEvent(wrong,clipboard,strings) && empty(strings) && clipboard.timestamp==0ul)
    for(kind in [SDL_EVENT_TEXT_EDITING_CANDIDATES,SDL_EVENT_CLIPBOARD_UPDATE]) {
        for(mode in 2 .. 5) {
            let raw=SDLTestListEvent(kind,mode)
            verify(decode_event(raw) is unknown)
        }
    }
    let empty_ime <- decode_event(SDLTestListEvent(SDL_EVENT_TEXT_EDITING_CANDIDATES,1))
    verify(empty_ime is text_editing_candidates)
    assume i=empty_ime as text_editing_candidates
    verify(empty(i.candidates) && i.selected_candidate== -1 && !i.horizontal)
    let empty_clipboard <- decode_event(SDLTestListEvent(SDL_EVENT_CLIPBOARD_UPDATE,1))
    assume c=empty_clipboard as clipboard_update
    verify(empty(c.mime_types) && !c.owner)
}

def user_data() {
    let first=register_events(1) |> sdl_try
    var e=SDL_MakeUserEvent(first,42u,-17)
    var p1=SDLTestUserPointer(0)
    var p2=SDLTestUserPointer(1)
    verify(SDL_WriteUserEventData(e,p1,p2))
    var a,b : void?
    verify(SDL_ReadUserEventData(e,a,b) && a==p1 && b==p2)
    verify(push_event(e))
    var raw=SDL_MakeEvent()
    verify(SDL_PollEventRef(raw))
    verify(SDL_ReadUserEventData(raw,a,b) && a==p1 && b==p2)
    let owned <- decode_event(raw)
    verify(owned is user && (owned as user).code== -17 && (owned as user).window_id==42u)
    verify(SDL_WriteUserEventData(raw,null,null))
    verify(SDL_ReadUserEventData(raw,a,b) && a==null && b==null)
    verify((decode_event(raw) as user).code== -17)
    raw.event_type=SDL_EVENT_LAST
    verify(!SDL_WriteUserEventData(raw,p1,p2) && !SDL_ReadUserEventData(raw,a,b) && a==null && b==null)
    var key=SDL_MakeKeyEvent(SDL_EVENT_KEY_DOWN,SDLK_ESCAPE)
    verify(!SDL_WriteUserEventData(key,p1,p2) && SDL_EventIsEscape(key))
    verify(push_event(e));SDL_FlushEvent(first)
    verify(SDLTestUserPointersAlive()) // queue removal/owned decode never frees user tokens
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    SDLTestResetEventLists()
    shapes()
    var source=SDLTestListEvent(SDL_EVENT_TEXT_EDITING_CANDIDATES,0)
    var original <- decode_event(source)
    var cloned <- clone_to_move(original)
    assume copy=cloned as text_editing_candidates
    copy.candidates[0]="independent array"
    verify(check(original)==SDL_EVENT_TEXT_EDITING_CANDIDATES)
    let result=sdl_scope() {
        with_sdl() |> sdl_use
        SDL_FlushEvents(SDL_EVENT_FIRST,SDL_EVENT_LAST)
        var ime=SDLTestListEvent(SDL_EVENT_TEXT_EDITING_CANDIDATES,0)
        var clip=SDLTestListEvent(SDL_EVENT_CLIPBOARD_UPDATE,0)
        verify(push_event(ime));verify(push_event(clip))
        var peeked <- peek_events(2) |> sdl_try
        var taken <- take_events(2) |> sdl_try
        verify(length(peeked)==2 && length(taken)==2)
        verify(push_event(ime))
        var polled <- poll_event()
        verify(is_some(polled))
        var retained <- move_unwrap(polled)
        verify(is_none(polled))
        verify(push_event(clip))
        let waited <- wait_event() |> sdl_try
        verify(push_event(ime))
        var timed <- wait_event_timeout(10) |> sdl_try
        verify(is_some(timed))
        SDLTestMutateEventLists()
        SDL_PumpEvents()
        verify(check(original)==SDL_EVENT_TEXT_EDITING_CANDIDATES)
        verify(check(retained)==SDL_EVENT_TEXT_EDITING_CANDIDATES && check(waited)==SDL_EVENT_CLIPBOARD_UPDATE)
        verify(check(move_unwrap(timed))==SDL_EVENT_TEXT_EDITING_CANDIDATES)
        for(i in 0 .. 2) {verify(check(peeked[i])==check(taken[i]))}
        SDL_FlushEvents(SDL_EVENT_FIRST,SDL_EVENT_LAST)
        user_data() |> sdl_try
        return sdl_ok()
    }
    verify(is_ok(result))
    print("Owned IME/MIME lists, move/clone, poll/peek/take/wait and borrowed user pointers PASS\n")
    return 0
}
