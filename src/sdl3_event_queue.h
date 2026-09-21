#pragma once
#include "sdl3_input.h"
#include <limits>

inline bool SDL_WaitEventRef(SDL_Event & event) {
    event = {};
    return SDL_WaitEvent(&event);
}
// SDL's bool cannot distinguish timeout from failure. Clear a stale error
// before waiting and inspect the new error only after a false return.
inline int32_t SDL_WaitEventTimeoutStatusRef(SDL_Event & event, int32_t timeout_ms) {
    event = {};
    SDL_ClearError();
    if (SDL_WaitEventTimeout(&event, timeout_ms)) return 1;
    event = {};
    return *SDL_GetError() ? -1 : 0;
}
inline int32_t SDL_PeepEventsArray(das::TArray<SDL_Event> & events, SDL_EventAction action,
                                  uint32_t min_type, uint32_t max_type) {
    if (action != SDL_ADDEVENT && action != SDL_PEEKEVENT && action != SDL_GETEVENT) {
        SDL_SetError("Invalid event queue action"); return -1;
    }
    if (events.size > uint32_t(std::numeric_limits<int>::max()) || (events.size && !events.data)) {
        SDL_SetError("Invalid event array capacity"); return -1;
    }
    // NULL would query the queue count, not an empty destination buffer.
    if (!events.size) return 0;
    auto * data = reinterpret_cast<SDL_Event *>(events.data);
    if (action != SDL_ADDEVENT) SDL_memset(data, 0, size_t(events.size) * sizeof(SDL_Event));
    SDL_ClearError();
    const int count = SDL_PeepEvents(data, int(events.size), action, min_type, max_type);
    if (count < 0 && !*SDL_GetError()) SDL_SetError("Event queue is unavailable");
    if (action != SDL_ADDEVENT) {
        const uint32_t first_unused = count < 0 ? 0 : uint32_t(count);
        SDL_memset(data + first_unused, 0, size_t(events.size - first_unused) * sizeof(SDL_Event));
    }
    return count;
}
inline int32_t SDL_CountEvents(uint32_t min_type, uint32_t max_type) {
    SDL_ClearError();
    const int count = SDL_PeepEvents(nullptr, 0, SDL_PEEKEVENT, min_type, max_type);
    if (count < 0 && !*SDL_GetError()) SDL_SetError("Event queue is unavailable");
    return count;
}
inline SDL_Window * SDL_GetWindowFromEventRef(const SDL_Event & event) { return SDL_GetWindowFromEvent(&event); }
inline SDL_Event SDL_MakeUserEvent(uint32_t type, uint32_t window_id, int32_t code) {
    SDL_Event event{};
    event.user.type = type; event.user.windowID = window_id; event.user.code = code;
    return event;
}
inline bool SDL_ReadUserEvent(const SDL_Event & event, uint32_t & window_id, int32_t & code) {
    window_id = 0; code = 0;
    if (event.type < SDL_EVENT_USER || event.type >= SDL_EVENT_LAST) return false;
    window_id = event.user.windowID; code = event.user.code;
    return true;
}
inline bool SDL_ReadDropEvent(const SDL_Event & event, uint32_t & window_id, das::float2 & position,
                              char * & source, char * & data, das::Context * context, das::LineInfoArg * at) {
    window_id = 0; position = {}; source = data = nullptr;
    switch (event.type) {
    case SDL_EVENT_DROP_BEGIN: case SDL_EVENT_DROP_FILE: case SDL_EVENT_DROP_TEXT:
    case SDL_EVENT_DROP_COMPLETE: case SDL_EVENT_DROP_POSITION: break;
    default: return false;
    }
    window_id = event.drop.windowID; position = {event.drop.x, event.drop.y};
    if (event.drop.source) source = context->allocateString(event.drop.source, uint32_t(SDL_strlen(event.drop.source)), at);
    if (event.drop.data) data = context->allocateString(event.drop.data, uint32_t(SDL_strlen(event.drop.data)), at);
    return true;
}
