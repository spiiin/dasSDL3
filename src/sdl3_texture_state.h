#pragma once
#include <SDL3/SDL.h>
inline bool SDL_GetTextureColorModFloatRef(SDL_Texture * texture,float & r,float & g,float & b) {return SDL_GetTextureColorModFloat(texture,&r,&g,&b);}
inline bool SDL_GetTextureAlphaModFloatRef(SDL_Texture * texture,float & a) {return SDL_GetTextureAlphaModFloat(texture,&a);}
inline bool SDL_GetTextureScaleModeRef(SDL_Texture * texture,SDL_ScaleMode & mode) {return SDL_GetTextureScaleMode(texture,&mode);}
