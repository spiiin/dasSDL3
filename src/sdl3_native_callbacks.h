#pragma once
#include <SDL3/SDL.h>
// Native C function addresses only. Never cast a daScript Func or Block here.
inline bool SDL_AddHintCallbackAddress(const char *name, void *callback, void *userdata) {
    return SDL_AddHintCallback(name, reinterpret_cast<SDL_HintCallback>(callback), userdata);
}
inline void SDL_RemoveHintCallbackAddress(const char *name, void *callback, void *userdata) {
    SDL_RemoveHintCallback(name, reinterpret_cast<SDL_HintCallback>(callback), userdata);
}
inline SDL_TimerID SDL_AddTimerAddress(Uint32 interval, void *callback, void *userdata) {
    return SDL_AddTimer(interval, reinterpret_cast<SDL_TimerCallback>(callback), userdata);
}
inline SDL_TimerID SDL_AddTimerNSAddress(Uint64 interval, void *callback, void *userdata) {
    return SDL_AddTimerNS(interval, reinterpret_cast<SDL_NSTimerCallback>(callback), userdata);
}
inline void *SDL_GetDefaultLogOutputFunctionAddress() {
    return reinterpret_cast<void *>(SDL_GetDefaultLogOutputFunction());
}
inline void SDL_GetLogOutputFunctionAddress(void **callback, void **userdata) {
    SDL_LogOutputFunction native = nullptr;
    SDL_GetLogOutputFunction(callback ? &native : nullptr, userdata);
    if (callback) *callback = reinterpret_cast<void *>(native);
}
inline void SDL_GetLogOutputFunctionRef(void *&callback, void *&userdata) {
    SDL_GetLogOutputFunctionAddress(&callback, &userdata);
}
inline void SDL_SetLogOutputFunctionAddress(void *callback, void *userdata) {
    SDL_SetLogOutputFunction(reinterpret_cast<SDL_LogOutputFunction>(callback), userdata);
}
inline bool SDL_RunOnMainThreadAddress(void *callback, void *userdata, bool wait_complete) {
    return SDL_RunOnMainThread(reinterpret_cast<SDL_MainThreadCallback>(callback), userdata, wait_complete);
}
inline bool SDL_SetPointerPropertyWithCleanupAddress(SDL_PropertiesID props, const char *name,
        void *value, void *cleanup, void *userdata) {
    return SDL_SetPointerPropertyWithCleanup(props, name, value,
        reinterpret_cast<SDL_CleanupPropertyCallback>(cleanup), userdata);
}
