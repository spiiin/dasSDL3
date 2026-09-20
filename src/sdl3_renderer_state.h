#pragma once
#include <SDL3/SDL.h>
inline bool SDL_GetRenderOutputSizeRef(SDL_Renderer * renderer,int & w,int & h) {return SDL_GetRenderOutputSize(renderer,&w,&h);}
inline bool SDL_GetCurrentRenderOutputSizeRef(SDL_Renderer * renderer,int & w,int & h) {return SDL_GetCurrentRenderOutputSize(renderer,&w,&h);}
inline bool SDL_SetRenderViewportRef(SDL_Renderer * renderer,const SDL_Rect & rect) {return SDL_SetRenderViewport(renderer,&rect);}
inline bool SDL_GetRenderViewportRef(SDL_Renderer * renderer,SDL_Rect & rect) {return SDL_GetRenderViewport(renderer,&rect);}
inline bool SDL_ResetRenderViewport(SDL_Renderer * renderer) {return SDL_SetRenderViewport(renderer,nullptr);}
inline bool SDL_SetRenderClipRectRef(SDL_Renderer * renderer,const SDL_Rect & rect) {return SDL_SetRenderClipRect(renderer,&rect);}
inline bool SDL_GetRenderClipRectRef(SDL_Renderer * renderer,SDL_Rect & rect) {return SDL_GetRenderClipRect(renderer,&rect);}
inline bool SDL_DisableRenderClip(SDL_Renderer * renderer) {return SDL_SetRenderClipRect(renderer,nullptr);}
inline bool SDL_GetRenderScaleRef(SDL_Renderer * renderer,float & x,float & y) {return SDL_GetRenderScale(renderer,&x,&y);}
