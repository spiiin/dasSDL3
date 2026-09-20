#pragma once
#include <SDL3/SDL.h>
inline bool SDL_GetWindowSafeAreaRef(SDL_Window * window,SDL_Rect & rect) {return SDL_GetWindowSafeArea(window,&rect);}
inline bool SDL_GetWindowAspectRatioRef(SDL_Window * window,float & low,float & high) {return SDL_GetWindowAspectRatio(window,&low,&high);}
inline bool SDL_GetWindowBordersSizeRef(SDL_Window * window,int & top,int & left,int & bottom,int & right) {
    return SDL_GetWindowBordersSize(window,&top,&left,&bottom,&right);
}
inline bool SDL_GetWindowMinimumSizeRef(SDL_Window * window,int & w,int & h) {return SDL_GetWindowMinimumSize(window,&w,&h);}
inline bool SDL_GetWindowMaximumSizeRef(SDL_Window * window,int & w,int & h) {return SDL_GetWindowMaximumSize(window,&w,&h);}
