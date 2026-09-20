#pragma once
#include "sdl3_video.h"
#include <cstring>
inline bool SDL_SetWindowFullscreenModeRef(SDL_Window * window,const SDL_DisplayMode & mode) {return SDL_SetWindowFullscreenMode(window,&mode);}
inline bool SDL_SetWindowDesktopFullscreenMode(SDL_Window * window) {return SDL_SetWindowFullscreenMode(window,nullptr);}
// False means NULL from SDL: no selected mode/rectangle OR an error.
inline bool SDL_GetWindowFullscreenModeCopy(SDL_Window * window,SDL_DisplayMode & mode) {return sdl3_video::copy_mode(SDL_GetWindowFullscreenMode(window),mode);}
inline bool SDL_SetWindowMouseRectRef(SDL_Window * window,const SDL_Rect & rect) {return SDL_SetWindowMouseRect(window,&rect);}
inline bool SDL_ClearWindowMouseRect(SDL_Window * window) {return SDL_SetWindowMouseRect(window,nullptr);}
inline bool SDL_GetWindowMouseRectCopy(SDL_Window * window,SDL_Rect & rect) {
    auto * source=SDL_GetWindowMouseRect(window);if(!source){rect={};return false;}rect=*source;return true;
}
inline bool SDL_GetWindowSurfaceVSyncRef(SDL_Window * window,int & vsync) {return SDL_GetWindowSurfaceVSync(window,&vsync);}
inline bool SDL_UpdateWindowSurfaceRectsArray(SDL_Window * window,const das::TArray<SDL_Rect> & rects) {
    if(rects.size>uint32_t(INT_MAX)/sizeof(SDL_Rect))return SDL_SetError("Window rectangles exceed byte limit");
    return SDL_UpdateWindowSurfaceRects(window,reinterpret_cast<const SDL_Rect *>(rects.data),int(rects.size));
}
inline bool SDL_GetWindowICCProfileCopy(SDL_Window * window,das::TArray<uint8_t> & bytes,das::Context * context,das::LineInfoArg * at) {
    das::builtin_array_resize(bytes,0,sizeof(uint8_t),context,at);
    // SDL 3.2.18 omits the usual window validation in the ICC getter.
    if(!window)return SDL_SetError("ICC profile: null window");
    size_t size=0;void * raw=SDL_GetWindowICCProfile(window,&size);
    std::unique_ptr<void,decltype(&SDL_free)> owned(raw,SDL_free);
    if(!raw)return false;
    if(size>size_t(INT_MAX))return SDL_SetError("ICC profile exceeds array limit");
    das::builtin_array_resize(bytes,int(size),sizeof(uint8_t),context,at);
    if(size)std::memcpy(bytes.data,raw,size);
    return true;
}
inline bool SDL_FillSurfaceAll(SDL_Surface * surface,Uint32 color) {return SDL_FillSurfaceRect(surface,nullptr,color);}
inline bool SDL_FillSurfaceRectRef(SDL_Surface * surface,const SDL_Rect & rect,Uint32 color) {return SDL_FillSurfaceRect(surface,&rect,color);}
