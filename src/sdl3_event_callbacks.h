#pragma once
#include "sdl3_native_callbacks.h"
#include "sdl3_record_access.h"
#ifdef DASSDL3_TESTING
#include "../tests/native_callback_probe.h"
#endif
#include <SDL3/SDL.h>
#include "daScript/simulate/aot.h"
#include "daScript/simulate/aot_builtin.h"

// Native function addresses, never daScript Func/Block representations.
inline void SDL_SetEventFilterAddress(void * filter, void * userdata) {
    SDL_SetEventFilter(reinterpret_cast<SDL_EventFilter>(filter), userdata);
}
inline bool SDL_GetEventFilterAddress(void ** filter, void ** userdata) {
    SDL_EventFilter native = nullptr;
    const bool present = SDL_GetEventFilter(filter ? &native : nullptr, userdata);
    if (filter) *filter = reinterpret_cast<void *>(native);
    return present;
}
inline bool SDL_AddEventWatchAddress(void * filter, void * userdata) {
    return SDL_AddEventWatch(reinterpret_cast<SDL_EventFilter>(filter), userdata);
}
inline void SDL_RemoveEventWatchAddress(void * filter, void * userdata) {
    SDL_RemoveEventWatch(reinterpret_cast<SDL_EventFilter>(filter), userdata);
}
inline void SDL_FilterEventsAddress(void * filter, void * userdata) {
    SDL_FilterEvents(reinterpret_cast<SDL_EventFilter>(filter), userdata);
}
inline bool SDL_GetEventFilterRef(void *& filter, void *& userdata) {
    return SDL_GetEventFilterAddress(&filter, &userdata);
}

namespace sdl3_event_callbacks {
struct Invocation {
    const das::Block & block;
    das::Context * context;
    das::LineInfoArg * at;
};
inline bool SDLCALL invoke(void * userdata, SDL_Event * event) {
    auto & call = *static_cast<Invocation *>(userdata);
    return das::das_invoke<bool>::invoke<SDL_Event &>(call.context, call.at, call.block, *event);
}
}

// SDL borrows this stack state until the synchronous call returns.
// The block may edit the event, but must not mutate the queue, retain the event
// reference, shut down SDL or panic while SDL holds its queue lock.
inline void SDL_FilterEventsBlock(const das::TBlock<bool, SDL_Event &> & predicate,
                                 das::Context * context, das::LineInfoArg * at) {
    sdl3_event_callbacks::Invocation call{predicate, context, at};
    SDL_FilterEvents(sdl3_event_callbacks::invoke, &call);
}
