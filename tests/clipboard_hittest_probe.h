#pragma once
#ifdef _WIN32
#ifndef NOMINMAX
#define NOMINMAX
#endif
// Windows COM macros must not corrupt later daScript AST declarations.
#pragma push_macro("THIS")
#pragma push_macro("THIS_")
#include <windows.h>
#pragma pop_macro("THIS_")
#pragma pop_macro("THIS")
#endif
namespace sdl3_callback_test {
inline int cleaned=0,requested=0,hits=0;
inline void reset(){cleaned=requested=hits=0;}
inline int cleanup_count(){return cleaned;}
inline int request_count(){return requested;}
inline int hit_count(){return hits;}
inline const void * SDLCALL provide(void *,const char * mime,size_t * size){static const unsigned char bytes[]={9,0,7};++requested;if(!mime){*size=0;return nullptr;}*size=3;return bytes;}
inline void SDLCALL cleanup(void *){++cleaned;}
inline SDL_HitTestResult SDLCALL hit(SDL_Window *,const SDL_Point * point,void *){++hits;return point->x<10 ? SDL_HITTEST_RESIZE_LEFT : SDL_HITTEST_DRAGGABLE;}
inline void * provider(){return reinterpret_cast<void *>(&provide);}
inline void * cleaner(){return reinterpret_cast<void *>(&cleanup);}
inline void * hitter(){return reinterpret_cast<void *>(&hit);}
inline int64_t probe(SDL_Window * window,int x,int y){
#ifdef _WIN32
    auto hwnd=static_cast<HWND>(SDL_GetPointerProperty(SDL_GetWindowProperties(window),SDL_PROP_WINDOW_WIN32_HWND_POINTER,nullptr));
    if(!hwnd)return -1;POINT p{x,y};if(!ClientToScreen(hwnd,&p))return -1;
    return int64_t(SendMessageW(hwnd,WM_NCHITTEST,0,MAKELPARAM(p.x,p.y)));
#else
    return -1;
#endif
}
}
