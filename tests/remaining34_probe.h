#pragma once
#include <SDL3/SDL.h>
#include <atomic>
#include <thread>
namespace sdl3_test {
inline std::atomic<int> remaining34_completed{0};
inline std::atomic<int> remaining34_bad{0};
inline void remaining34_reset(){remaining34_completed=0;remaining34_bad=0;}
inline void* remaining34_allocate(){void* data=SDL_malloc(64);if(data) SDL_memset(data,0x11,64);return data;}
inline void SDLCALL remaining34_complete(void* userdata,const void* bytes,int count){
    if(userdata || !bytes || (count!=64 && count!=0)) ++remaining34_bad;
    ++remaining34_completed;SDL_free(const_cast<void*>(bytes));
}
inline void SDLCALL remaining34_transform(void*,Uint64,SDL_Window*,SDL_MouseID,float* x,float* y){*x *= 2.0f;*y *= 2.0f;}
inline void* remaining34_callback(bool mouse){return mouse ? reinterpret_cast<void*>(remaining34_transform) : reinterpret_cast<void*>(remaining34_complete);}
inline char* remaining34_description_buffer(){static thread_local char data[1024]{};return data;}
inline int remaining34_count(bool bad){return bad ? remaining34_bad.load() : remaining34_completed.load();}
// Offline worker consumption, never a script Context callback.
inline bool remaining34_consume_worker(SDL_AudioStream* stream){
    bool good=false;std::thread thread([&]{Uint8 bytes[64]{};good=SDL_GetAudioStreamData(stream,bytes,64)==64;
        for(Uint8 value:bytes)good=good && value==0x11;
        // Exact-size read can leave a flushed, empty track retained until the next read.
        good=good && SDL_GetAudioStreamData(stream,bytes,4)==0;});thread.join();return good;
}
}
