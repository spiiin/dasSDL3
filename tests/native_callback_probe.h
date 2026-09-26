#pragma once
#include <SDL3/SDL.h>
#include <atomic>
#include <string>
// Static lifetime deliberately exceeds registrations and in-flight callbacks.
// No script context, block or script-owned memory is retained by these fixtures.
namespace sdl3_callback_probe {
inline int cookie=0, value=0;
inline std::atomic<int> counts[7]{};
inline std::atomic<bool> valid{true}, release_timer{false}, timer_left{false}, worker_done{false};
inline SDL_Thread *worker=nullptr;
inline void check(bool v) { if(!v) valid=false; }
inline void SDLCALL hint(void *data,const char *name,const char *old_value,const char *new_value) {
    check(data==&cookie && std::string(name)=="DASSDL3_CALLBACK_TEST");
    const int call=counts[0]++;
    const std::string old_s=old_value?old_value:"", new_s=new_value?new_value:"";
    if(call==0 || call==1) check(old_s=="first" && new_s=="first");
    else if(call==2) check(old_s=="first" && new_s=="second");
    else check(false);
}
inline void SDLCALL log(void *data,int category,SDL_LogPriority priority,const char *message) {
    check(data==&cookie && category==SDL_LOG_CATEGORY_APPLICATION && priority==SDL_LOG_PRIORITY_ERROR);
    check(std::string(message)=="native callback 100%"); ++counts[1];
}
inline void SDLCALL cleanup(void *data,void *ptr) {
    check(data==&cookie && (ptr==&value || ptr==nullptr)); ++counts[2];
}
inline void SDLCALL main_call(void *data) {
    check(data==&cookie && SDL_IsMainThread()); ++counts[3];
}
inline Uint32 SDLCALL timer_ms(void *data,SDL_TimerID id,Uint32 interval) {
    check(data==&cookie && id!=0 && interval==2 && !SDL_IsMainThread());
    return ++counts[4]<2 ? interval : 0;
}
inline Uint64 SDLCALL timer_ns(void *data,SDL_TimerID id,Uint64 interval) {
    check(data==&cookie && id!=0 && interval==2000000 && !SDL_IsMainThread());
    return ++counts[5]<2 ? interval : 0;
}
inline Uint32 SDLCALL held_timer(void *data,SDL_TimerID id,Uint32 interval) {
    check(data==&cookie && id!=0 && interval==1); ++counts[6];
    while(!release_timer.load()) SDL_Delay(1);
    timer_left=true;
    return interval;
}
inline int SDLCALL worker_call(void *wait_flag) {
    check(SDL_RunOnMainThread(main_call,&cookie,wait_flag!=nullptr));
    worker_done=true;
    return 0;
}
}
inline void *SDLTestCallbackAddress(int kind) {
    using namespace sdl3_callback_probe;
    switch(kind) {
    case 0:return reinterpret_cast<void *>(hint);
    case 1:return reinterpret_cast<void *>(sdl3_callback_probe::log);
    case 2:return reinterpret_cast<void *>(cleanup);
    case 3:return reinterpret_cast<void *>(main_call);
    case 4:return reinterpret_cast<void *>(timer_ms);
    case 5:return reinterpret_cast<void *>(timer_ns);
    case 6:return reinterpret_cast<void *>(held_timer);
    default:return nullptr;
    }
}
inline void *SDLTestCallbackData(bool pointer_value) {
    return pointer_value ? &sdl3_callback_probe::value : &sdl3_callback_probe::cookie;
}
inline int SDLTestCallbackCount(int kind) {
    return kind>=0 && kind<7 ? sdl3_callback_probe::counts[kind].load() : -1;
}
inline bool SDLTestCallbackCheck() {return sdl3_callback_probe::valid.load();}
inline bool SDLTestTimerRelease() {
    const bool left=sdl3_callback_probe::timer_left.load();
    sdl3_callback_probe::release_timer=true;
    return left;
}
inline bool SDLTestStartMainWorker(bool wait) {
    using namespace sdl3_callback_probe;
    if(worker) return false;
    worker_done=false;
    worker=SDL_CreateThread(worker_call,"main callback",wait?&cookie:nullptr);
    return worker!=nullptr;
}
inline bool SDLTestMainWorkerDone() {return sdl3_callback_probe::worker_done.load();}
inline void SDLTestJoinMainWorker() {
    using namespace sdl3_callback_probe;
    if(worker && worker_done.load()) {SDL_WaitThread(worker,nullptr);worker=nullptr;}
}
