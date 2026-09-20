#pragma once
#include "sdl3_pixels.h"
inline bool SDL_GetTextureColorModRef(SDL_Texture * texture,uint32_t & r,uint32_t & g,uint32_t & b) {
    Uint8 nr=255,ng=255,nb=255;const bool ok=SDL_GetTextureColorMod(texture,&nr,&ng,&nb);r=nr;g=ng;b=nb;return ok;
}
inline bool SDL_GetTextureAlphaModRef(SDL_Texture * texture,uint32_t & a) {
    Uint8 na=255;const bool ok=SDL_GetTextureAlphaMod(texture,&na);a=na;return ok;
}
inline bool SDL_GetTextureBlendModeRef(SDL_Texture * texture,SDL_BlendMode & mode) {return SDL_GetTextureBlendMode(texture,&mode);}
inline bool SDL_LockTextureToSurfaceRef(SDL_Texture * texture,const SDL_Rect & rect,SDL_Surface * & surface) {
    if(!texture)return SDL_SetError("Texture surface lock: null texture");
    const auto props=SDL_GetTextureProperties(texture);
    if(!props)return false;
    const auto w=SDL_GetNumberProperty(props,SDL_PROP_TEXTURE_WIDTH_NUMBER,0);
    const auto h=SDL_GetNumberProperty(props,SDL_PROP_TEXTURE_HEIGHT_NUMBER,0);
    if(rect.x<0 || rect.y<0 || rect.w<=0 || rect.h<=0 || int64_t(rect.x)+rect.w>w || int64_t(rect.y)+rect.h>h)
        return SDL_SetError("Texture surface lock: rectangle outside texture");
    return SDL_LockTextureToSurface(texture,&rect,&surface);
}
inline bool SDL_UpdateTextureRGBA8(SDL_Texture * texture,const SDL_Rect & rect,const das::TArray<uint8_t> & bytes,int pitch) {
    if(!texture)return SDL_SetError("Texture update: null texture");
    const auto props=SDL_GetTextureProperties(texture);
    if(!props)return false;
    if(SDL_GetNumberProperty(props,SDL_PROP_TEXTURE_FORMAT_NUMBER,0)!=SDL_PIXELFORMAT_RGBA32)
        return SDL_SetError("Texture update: expected RGBA32");
    const auto w=SDL_GetNumberProperty(props,SDL_PROP_TEXTURE_WIDTH_NUMBER,0);
    const auto h=SDL_GetNumberProperty(props,SDL_PROP_TEXTURE_HEIGHT_NUMBER,0);
    if(rect.x<0 || rect.y<0 || rect.w<=0 || rect.h<=0 || int64_t(rect.x)+rect.w>w || int64_t(rect.y)+rect.h>h)
        return SDL_SetError("Texture update: rectangle outside texture");
    const int needed=SDL_RGBA8BufferSize(rect.w,rect.h,pitch);
    if(needed<0)return false;
    if(!bytes.data || bytes.size<uint32_t(needed))return SDL_SetError("Texture update: insufficient source bytes");
    return SDL_UpdateTexture(texture,&rect,bytes.data,pitch);
}
