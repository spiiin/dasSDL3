#pragma once
#include "sdl3_init_hints.h"
#include "daScript/simulate/aot_builtin.h"
#include <memory>
#include <climits>
// Video operations keep SDL's main-thread precondition. No pointer registry.
namespace sdl3_video {
template<class T> inline bool copy_array(T * source,int count,das::TArray<T> & output,
        das::Context * context,das::LineInfoArg * at) {
    std::unique_ptr<T,decltype(&SDL_free)> owned(source,SDL_free);
    das::builtin_array_resize(output,0,sizeof(T),context,at);
    if(!source)return false;
    if(count<0 || size_t(count)>size_t(INT_MAX)/sizeof(T))return SDL_SetError("SDL video array exceeds size limit");
    das::builtin_array_resize(output,count,sizeof(T),context,at);
    auto * dest=reinterpret_cast<T *>(output.data);
    for(int i=0;i<count;++i)dest[i]=source[i];
    return true;
}
inline bool copy_mode(const SDL_DisplayMode * source,SDL_DisplayMode & output) {
    if(!source){output={};return false;}
    output=*source;output.internal=nullptr;return true;
}
}
inline bool SDL_GetDisplaysCopy(das::TArray<SDL_DisplayID> & output,das::Context * context,das::LineInfoArg * at) {
    int count=0;auto * source=SDL_GetDisplays(&count);
    return sdl3_video::copy_array(source,count,output,context,at);
}
inline bool SDL_GetWindowsCopy(das::TArray<SDL_Window *> & output,das::Context * context,das::LineInfoArg * at) {
    int count=0;auto * source=SDL_GetWindows(&count);
    return sdl3_video::copy_array(source,count,output,context,at);
}
inline bool SDL_GetFullscreenDisplayModesCopy(SDL_DisplayID display,das::TArray<SDL_DisplayMode> & output,
        das::Context * context,das::LineInfoArg * at) {
    int count=0;auto ** source=SDL_GetFullscreenDisplayModes(display,&count);
    std::unique_ptr<SDL_DisplayMode *,decltype(&SDL_free)> owned(source,SDL_free);
    das::builtin_array_resize(output,0,sizeof(SDL_DisplayMode),context,at);
    if(!source)return false;
    if(count<0 || size_t(count)>size_t(INT_MAX)/sizeof(SDL_DisplayMode))return SDL_SetError("SDL modes exceed size limit");
    das::builtin_array_resize(output,count,sizeof(SDL_DisplayMode),context,at);
    auto * dest=reinterpret_cast<SDL_DisplayMode *>(output.data);
    for(int i=0;i<count;++i)sdl3_video::copy_mode(source[i],dest[i]);
    return true;
}
inline bool SDL_GetDesktopDisplayModeCopy(SDL_DisplayID display,SDL_DisplayMode & mode) {
    return sdl3_video::copy_mode(SDL_GetDesktopDisplayMode(display),mode);
}
inline bool SDL_GetCurrentDisplayModeCopy(SDL_DisplayID display,SDL_DisplayMode & mode) {
    return sdl3_video::copy_mode(SDL_GetCurrentDisplayMode(display),mode);
}
inline bool SDL_GetClosestFullscreenDisplayModeRef(SDL_DisplayID display,int w,int h,float hz,bool dense,SDL_DisplayMode & mode) {
    const bool ok=SDL_GetClosestFullscreenDisplayMode(display,w,h,hz,dense,&mode);
    if(!ok)mode={};else mode.internal=nullptr;
    return ok;
}
inline SDL_DisplayID SDL_GetDisplayForPointRef(const SDL_Point & point) {return SDL_GetDisplayForPoint(&point);}
inline SDL_DisplayID SDL_GetDisplayForRectRef(const SDL_Rect & rect) {return SDL_GetDisplayForRect(&rect);}
inline char * SDL_GetVideoDriverCopy(int index,das::Context * context,das::LineInfoArg * at) {return sdl3_init_hints::copy(SDL_GetVideoDriver(index),context,at);}
inline char * SDL_GetDisplayNameCopy(SDL_DisplayID display,das::Context * context,das::LineInfoArg * at) {return sdl3_init_hints::copy(SDL_GetDisplayName(display),context,at);}
inline char * SDL_GetWindowTitleCopy(SDL_Window * window,das::Context * context,das::LineInfoArg * at) {return sdl3_init_hints::copy(SDL_GetWindowTitle(window),context,at);}
inline char * SDL_GetCurrentVideoDriverCopy(das::Context * context,das::LineInfoArg * at) {return sdl3_init_hints::copy(SDL_GetCurrentVideoDriver(),context,at);}
inline bool SDL_GetDisplayBoundsRef(SDL_DisplayID display,SDL_Rect & rect) {return SDL_GetDisplayBounds(display,&rect);}
inline bool SDL_GetDisplayUsableBoundsRef(SDL_DisplayID display,SDL_Rect & rect) {return SDL_GetDisplayUsableBounds(display,&rect);}
inline bool SDL_GetWindowPositionRef(SDL_Window * window,int & x,int & y) {return SDL_GetWindowPosition(window,&x,&y);}
inline bool SDL_GetWindowSizeRef(SDL_Window * window,int & x,int & y) {return SDL_GetWindowSize(window,&x,&y);}
inline bool SDL_GetWindowSizeInPixelsRef(SDL_Window * window,int & x,int & y) {return SDL_GetWindowSizeInPixels(window,&x,&y);}
