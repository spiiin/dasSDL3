#pragma once
#include <SDL3/SDL.h>
#include <atomic>
namespace sdl3_test {
inline SDL_TLSID thread_tls{};
inline std::atomic<bool> thread_started{false};
inline std::atomic<int> thread_destroyed{0};
inline SDL_Semaphore * thread_gate=nullptr;
inline int thread_marker=0;
inline void SDLCALL thread_destructor(void * data) {if(data==&thread_marker)thread_destroyed.fetch_add(1);}
inline int SDLCALL thread_entry(void * data) {
    if(!SDL_SetTLS(&thread_tls,&thread_marker,thread_destructor))return -1;
    thread_started=true;
    SDL_WaitSemaphore(thread_gate);
    if(data)for(int i=0;i<10000;++i)SDL_AddAtomicInt(static_cast<SDL_AtomicInt *>(data),1);
    return SDL_GetTLS(&thread_tls)==&thread_marker?37:-2;
}
inline void thread_reset() {if(thread_gate)SDL_DestroySemaphore(thread_gate);thread_gate=SDL_CreateSemaphore(0);thread_destroyed=0;thread_started=false;}
inline void thread_release() {SDL_SignalSemaphore(thread_gate);}
inline void thread_finish() {SDL_DestroySemaphore(thread_gate);thread_gate=nullptr;}
inline bool thread_ready() {return thread_started.load();}
inline int thread_cleanup_count() {return thread_destroyed.load();}
inline void * thread_address(int kind) {
    switch(kind) {
    case 0:return reinterpret_cast<void *>(thread_entry);
    case 1:return reinterpret_cast<void *>(thread_destructor);
    case 2:return &thread_marker;
    case 3:return reinterpret_cast<void *>(SDL_BeginThreadFunction);
    case 4:return reinterpret_cast<void *>(SDL_EndThreadFunction);
    default:return nullptr;
    }
}
}
