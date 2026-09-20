#pragma once
#include "sdl3_init_hints.h"
// daScript interpolation happens before this call; percent signs are literal.
inline bool SDL_SetErrorText(const char * text) { return SDL_SetError("%s",text ? text : ""); }
inline char * SDL_GetErrorCopy(das::Context * context,das::LineInfoArg * at) {
    return sdl3_init_hints::copy(SDL_GetError(),context,at);
}
inline bool SDL_GetCurrentTimeRef(SDL_Time & ticks) { return SDL_GetCurrentTime(&ticks); }
inline bool SDL_GetDateTimeLocalePreferencesRef(SDL_DateFormat & date,SDL_TimeFormat & time) {
    return SDL_GetDateTimeLocalePreferences(&date,&time);
}
inline bool SDL_TimeToDateTimeRef(SDL_Time ticks,SDL_DateTime & date,bool local) {
    return SDL_TimeToDateTime(ticks,&date,local);
}
inline bool SDL_DateTimeToTimeRef(const SDL_DateTime & date,SDL_Time & ticks) {
    return SDL_DateTimeToTime(&date,&ticks);
}
inline void SDL_TimeToWindowsRef(SDL_Time ticks,Uint32 & low,Uint32 & high) {
    SDL_TimeToWindows(ticks,&low,&high);
}
inline void SDL_LogText(const char * text) { SDL_Log("%s",text ? text : ""); }
inline void SDL_LogMessageText(int category,SDL_LogPriority priority,const char * text) {
    SDL_LogMessage(category,priority,"%s",text ? text : "");
}
inline void SDL_LogTraceText(int category,const char * text) { SDL_LogTrace(category,"%s",text ? text : ""); }
inline void SDL_LogVerboseText(int category,const char * text) { SDL_LogVerbose(category,"%s",text ? text : ""); }
inline void SDL_LogDebugText(int category,const char * text) { SDL_LogDebug(category,"%s",text ? text : ""); }
inline void SDL_LogInfoText(int category,const char * text) { SDL_LogInfo(category,"%s",text ? text : ""); }
inline void SDL_LogWarnText(int category,const char * text) { SDL_LogWarn(category,"%s",text ? text : ""); }
inline void SDL_LogErrorText(int category,const char * text) { SDL_LogError(category,"%s",text ? text : ""); }
inline void SDL_LogCriticalText(int category,const char * text) { SDL_LogCritical(category,"%s",text ? text : ""); }
