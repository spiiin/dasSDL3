options gen2
module sdl3_event_queue shared public
require dassdl3/sdl3_events public

def public wait_event(var event : SDL_Event) {
    return sdl_status(SDL_WaitEventRef(event),"SDL_WaitEvent")
}
def public wait_event() {
    var event = SDL_MakeEvent()
    if (!SDL_WaitEventRef(event)) { return <- err(sdl_error("SDL_WaitEvent"),type<SdlEvent>) }
    var decoded <- decode_event(event)
    return <- move_ok(decoded,type<SdlError>)
}

def public wait_event_timeout(var event : SDL_Event; timeout_ms : int) {
    let status = SDL_WaitEventTimeoutStatusRef(event,timeout_ms)
    if (status < 0) { return err(sdl_error("SDL_WaitEventTimeout"),type<$Option<SdlUnit>>) }
    return ok(status == 0 ? none(type<SdlUnit>) : some(SdlUnit()),type<SdlError>)
}
def public wait_event_timeout(timeout_ms : int) {
    var event = SDL_MakeEvent()
    let status = SDL_WaitEventTimeoutStatusRef(event,timeout_ms)
    if (status < 0) { return <- err(sdl_error("SDL_WaitEventTimeout"),type<$Option<SdlEvent>>) }
    if (status == 0) { return <- ok(none(type<SdlEvent>),type<SdlError>) }
    var decoded <- decode_event(event)
    var optional <- move_some(decoded)
    return <- move_ok(optional,type<SdlError>)
}

// Raw event copies borrow pointer payloads. Only the returned prefix is valid.
// ADDEVENT returns a possibly partial count; it does not run filters/watchers.
def public peep_events(var events : array<SDL_Event>; action : SDL_EventAction;
        min_type : uint = SDL_EVENT_FIRST; max_type : uint = SDL_EVENT_LAST) {
    let count = SDL_PeepEventsArray(events,action,min_type,max_type)
    if (count < 0) { return err(sdl_error("SDL_PeepEvents"),type<int>) }
    return ok(count,type<SdlError>)
}
def public count_events(min_type : uint = SDL_EVENT_FIRST; max_type : uint = SDL_EVENT_LAST) {
    let count = SDL_CountEvents(min_type,max_type)
    if (count < 0) { return err(sdl_error("SDL_PeepEvents"),type<int>) }
    return ok(count,type<SdlError>)
}
def private read_events(action : SDL_EventAction; limit : int; min_type, max_type : uint) {
    if (limit < 0) {
        return err(SdlError(operation="SDL_PeepEvents",message="Event limit must not be negative"),type<array<SdlEvent>>)
    }
    var raw : array<SDL_Event>
    resize(raw,limit)
    let count = SDL_PeepEventsArray(raw,action,min_type,max_type)
    if (count < 0) { return err(sdl_error("SDL_PeepEvents"),type<array<SdlEvent>>) }
    var events : array<SdlEvent>
    resize(events,count)
    for (index in 0 .. count) { events[index] <- decode_event(raw[index]) }
    return <- move_ok(events,type<SdlError>)
}
def public peek_events(limit : int = 64; min_type : uint = SDL_EVENT_FIRST; max_type : uint = SDL_EVENT_LAST) {
    return <- read_events(SDL_EventAction.PEEKEVENT,limit,min_type,max_type)
}
def public take_events(limit : int = 64; min_type : uint = SDL_EVENT_FIRST; max_type : uint = SDL_EVENT_LAST) {
    return <- read_events(SDL_EventAction.GETEVENT,limit,min_type,max_type)
}

def public register_events(count : int) {
    if (count <= 0 || uint(count) > SDL_EVENT_LAST - SDL_EVENT_USER) {
        return err(SdlError(operation="SDL_RegisterEvents",message="Invalid user event count"),type<uint>)
    }
    let first = SDL_RegisterEvents(count)
    // SDL 3.2.18 may return zero without setting an error (or an overlong range).
    if (first == 0u || uint64(first) + uint64(count) > uint64(SDL_EVENT_LAST)) {
        return err(SdlError(operation="SDL_RegisterEvents",message="User event range exhausted"),type<uint>)
    }
    return ok(first,type<SdlError>)
}
def public event_window(event : SDL_Event) {
    var window = SDL_GetWindowFromEventRef(event)
    if (window == null) { return none(type<SDL_Window?>) }
    return <- move_some(window)
}

// Synchronous borrowed event reference; true keeps, false removes.
// Do not modify the queue, retain the reference or panic in the predicate.
def public filter_events(predicate : block<(var event : SDL_Event) : bool>) {
    SDL_FilterEventsBlock(predicate)
    return sdl_ok()
}
