#pragma once
#include "sdl3_window_io.h"
inline bool SDL_RenderPointsArray(SDL_Renderer * renderer,const das::TArray<SDL_FPoint> & values) {
    if(values.size>uint32_t(INT_MAX)/sizeof(SDL_FPoint))return SDL_SetError("Render array exceeds byte limit");
    const SDL_FPoint empty{}; // SDL validates the pointer before the zero count.
    return SDL_RenderPoints(renderer,values.size ? reinterpret_cast<const SDL_FPoint *>(values.data) : &empty,int(values.size));
}
inline bool SDL_RenderLinesArray(SDL_Renderer * renderer,const das::TArray<SDL_FPoint> & values) {
    if(values.size>uint32_t(INT_MAX)/sizeof(SDL_FPoint))return SDL_SetError("Render array exceeds byte limit");
    const SDL_FPoint empty{}; // SDL validates the pointer before the zero count.
    return SDL_RenderLines(renderer,values.size ? reinterpret_cast<const SDL_FPoint *>(values.data) : &empty,int(values.size));
}
inline bool SDL_RenderRectsArray(SDL_Renderer * renderer,const das::TArray<SDL_FRect> & values) {
    if(values.size>uint32_t(INT_MAX)/sizeof(SDL_FRect))return SDL_SetError("Render array exceeds byte limit");
    const SDL_FRect empty{}; // SDL validates the pointer before the zero count.
    return SDL_RenderRects(renderer,values.size ? reinterpret_cast<const SDL_FRect *>(values.data) : &empty,int(values.size));
}
inline bool SDL_RenderFillRectsArray(SDL_Renderer * renderer,const das::TArray<SDL_FRect> & values) {
    if(values.size>uint32_t(INT_MAX)/sizeof(SDL_FRect))return SDL_SetError("Render array exceeds byte limit");
    const SDL_FRect empty{}; // SDL validates the pointer before the zero count.
    return SDL_RenderFillRects(renderer,values.size ? reinterpret_cast<const SDL_FRect *>(values.data) : &empty,int(values.size));
}
inline bool SDL_RenderRectRef(SDL_Renderer * renderer,const SDL_FRect & rect) {return SDL_RenderRect(renderer,&rect);}
