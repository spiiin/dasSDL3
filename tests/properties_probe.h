#pragma once
#include <SDL3/SDL.h>
#include <thread>
#include <atomic>
inline std::atomic<int> SDLTestPropertyCleanups{0};
inline int SDLTestPropertyValue=73;
inline void SDLCALL SDLTestPropertyCleanup(void *,void *) { ++SDLTestPropertyCleanups; }
inline void * SDLTestPropertyPointer() { return &SDLTestPropertyValue; }
inline bool SDLTestAttachPropertyCleanup(SDL_PropertiesID props,const char * name) {
    return SDL_SetPointerPropertyWithCleanup(props,name,&SDLTestPropertyValue,SDLTestPropertyCleanup,nullptr);
}
inline int SDLTestPropertyCleanupCount() { return SDLTestPropertyCleanups.load(); }
inline bool SDLTestPropertiesOtherThread(SDL_PropertiesID props) {
    bool result=false;
    std::thread thread([&] { if(SDL_LockProperties(props)) {
        result=SDL_GetNumberProperty(props,"answer",0)==42;
        SDL_UnlockProperties(props);
    }});
    thread.join();return result;
}
