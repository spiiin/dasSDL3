#pragma once
#include <SDL3/SDL.h>
inline bool SDL_GetSurfaceColorKeyRef(SDL_Surface * surface,uint32_t & key) {return SDL_GetSurfaceColorKey(surface,&key);}
// daScript byte scalar references normalize to uint: use native byte temporaries.
inline bool SDL_GetSurfaceColorModRef(SDL_Surface * surface,uint32_t & r,uint32_t & g,uint32_t & b) {
    Uint8 nr=255,ng=255,nb=255;const bool ok=SDL_GetSurfaceColorMod(surface,&nr,&ng,&nb);r=nr;g=ng;b=nb;return ok;
}
inline bool SDL_GetSurfaceAlphaModRef(SDL_Surface * surface,uint32_t & a) {
    Uint8 na=255;const bool ok=SDL_GetSurfaceAlphaMod(surface,&na);a=na;return ok;
}
inline bool SDL_GetSurfaceBlendModeRef(SDL_Surface * surface,SDL_BlendMode & mode) {return SDL_GetSurfaceBlendMode(surface,&mode);}
inline bool SDL_SetSurfaceClipRectRef(SDL_Surface * surface,const SDL_Rect & rect) {return SDL_SetSurfaceClipRect(surface,&rect);}
inline bool SDL_GetSurfaceClipRectRef(SDL_Surface * surface,SDL_Rect & rect) {return SDL_GetSurfaceClipRect(surface,&rect);}
inline bool SDL_ResetSurfaceClipRect(SDL_Surface * surface) {return SDL_SetSurfaceClipRect(surface,nullptr);}
