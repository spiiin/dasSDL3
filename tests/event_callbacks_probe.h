#pragma once
#include <atomic>
#include <thread>
namespace sdl3_test {
inline std::atomic<int> event_watch_calls{0};
inline int event_callback_cookie;
inline bool SDLCALL event_filter(void * userdata, SDL_Event * event) {
    if (event->type < SDL_EVENT_USER) return true;
    if (userdata != &event_callback_cookie) return false;
    if (event->user.code < 0) return false;
    event->user.code += 10;
    return true;
}
inline bool SDLCALL event_watch(void * userdata, SDL_Event * event) {
    if (userdata == &event_callback_cookie && event->type >= SDL_EVENT_USER) ++event_watch_calls;
    return false; // SDL must ignore this result for watches.
}
inline void * event_filter_address() { return reinterpret_cast<void *>(event_filter); }
inline void * event_watch_address() { return reinterpret_cast<void *>(event_watch); }
inline void * event_cookie() { return &event_callback_cookie; }
inline int event_watch_count() { return event_watch_calls.load(); }
inline bool event_push_worker(uint32_t type, int code) {
    bool accepted = false;
    std::thread worker([&] { SDL_Event e{}; e.type=type; e.user.code=code; accepted=SDL_PushEvent(&e); });
    worker.join();
    return accepted;
}
}
