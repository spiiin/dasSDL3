#pragma once
#include "sdl3_init_hints.h"
inline char * SDL_GetRenderDriverCopy(int index,das::Context * context,das::LineInfoArg * at) {return sdl3_init_hints::copy(SDL_GetRenderDriver(index),context,at);}
inline char * SDL_GetRendererNameCopy(SDL_Renderer * renderer,das::Context * context,das::LineInfoArg * at) {return sdl3_init_hints::copy(SDL_GetRendererName(renderer),context,at);}
inline bool SDL_GetRenderSafeAreaRef(SDL_Renderer * renderer,SDL_Rect & rect) {return SDL_GetRenderSafeArea(renderer,&rect);}
inline bool SDL_GetRenderLogicalPresentationRef(SDL_Renderer * renderer,int & w,int & h,SDL_RendererLogicalPresentation & mode) {return SDL_GetRenderLogicalPresentation(renderer,&w,&h,&mode);}
inline bool SDL_GetRenderLogicalPresentationRectRef(SDL_Renderer * renderer,SDL_FRect & rect) {return SDL_GetRenderLogicalPresentationRect(renderer,&rect);}
inline bool SDL_RenderCoordinatesFromWindowRef(SDL_Renderer * renderer,float wx,float wy,float & x,float & y) {return SDL_RenderCoordinatesFromWindow(renderer,wx,wy,&x,&y);}
inline bool SDL_RenderCoordinatesToWindowRef(SDL_Renderer * renderer,float x,float y,float & wx,float & wy) {return SDL_RenderCoordinatesToWindow(renderer,x,y,&wx,&wy);}
