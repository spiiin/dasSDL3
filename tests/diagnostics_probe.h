#pragma once
#include <SDL3/SDL.h>
#include <thread>
#include <string>
inline SDL_LogOutputFunction SDLTestSavedLog=nullptr;
inline void * SDLTestSavedLogData=nullptr;
inline int SDLTestLogCalls=0;
inline std::string SDLTestLogLast;
inline void SDLCALL SDLTestCaptureLog(void *,int,SDL_LogPriority,const char * text) {
    ++SDLTestLogCalls; SDLTestLogLast=text;
}
// Test-only native capture, used synchronously on this test's main thread.
inline void SDLTestBeginLog() {
    SDL_GetLogOutputFunction(&SDLTestSavedLog,&SDLTestSavedLogData);
    SDLTestLogCalls=0;SDLTestLogLast.clear();
    SDL_SetLogOutputFunction(SDLTestCaptureLog,nullptr);
}
inline bool SDLTestLogMatches(int count,const char * text) {
    return SDLTestLogCalls==count && SDLTestLogLast==text;
}
inline void SDLTestEndLog() { SDL_SetLogOutputFunction(SDLTestSavedLog,SDLTestSavedLogData); }
inline bool SDLTestThreadError() {
    bool ok=false;
    std::thread worker([&] { SDL_SetError("worker error");ok=SDL_strcmp(SDL_GetError(),"worker error")==0; });
    worker.join();return ok;
}
inline Uint32 SDLCALL SDLTestDormantTimer(void *,SDL_TimerID,Uint32 interval) { return interval; }
inline SDL_TimerID SDLTestCreateDormantTimer() { return SDL_AddTimer(60000,SDLTestDormantTimer,nullptr); }
