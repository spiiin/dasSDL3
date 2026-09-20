#pragma once
#include "sdl3_pixels.h"
inline bool SDL_GetRenderDrawColorFloatRef(SDL_Renderer * renderer,float & r,float & g,float & b,float & a) {return SDL_GetRenderDrawColorFloat(renderer,&r,&g,&b,&a);}
inline bool SDL_GetRenderDrawColorRef(SDL_Renderer * renderer,uint32_t & r,uint32_t & g,uint32_t & b,uint32_t & a) {
    Uint8 nr=0,ng=0,nb=0,na=0;const bool ok=SDL_GetRenderDrawColor(renderer,&nr,&ng,&nb,&na);r=nr;g=ng;b=nb;a=na;return ok;
}
inline bool SDL_GetRenderColorScaleRef(SDL_Renderer * renderer,float & scale) {return SDL_GetRenderColorScale(renderer,&scale);}
inline bool SDL_GetRenderDrawBlendModeRef(SDL_Renderer * renderer,SDL_BlendMode & mode) {return SDL_GetRenderDrawBlendMode(renderer,&mode);}
namespace sdl3_yuv {
inline bool plane(const das::TArray<uint8_t> & bytes,int pitch,int64_t row,int64_t rows) {
    if(row<=0 || rows<=0 || pitch<row)return SDL_SetError("YUV plane: invalid pitch or dimensions");
    const int64_t required=(rows-1)*int64_t(pitch)+row;
    if(required>INT_MAX || !bytes.data || uint64_t(required)>bytes.size)return SDL_SetError("YUV plane: insufficient bytes or size overflow");
    return true;
}
inline bool size(SDL_Texture * texture,bool nv,int64_t & w,int64_t & h) {
    if(!texture)return SDL_SetError("YUV update: null texture");
    const auto props=SDL_GetTextureProperties(texture);if(!props)return false;
    const auto format=SDL_GetNumberProperty(props,SDL_PROP_TEXTURE_FORMAT_NUMBER,0);
    if(nv ? (format!=SDL_PIXELFORMAT_NV12 && format!=SDL_PIXELFORMAT_NV21) : (format!=SDL_PIXELFORMAT_IYUV && format!=SDL_PIXELFORMAT_YV12))
        return SDL_SetError("YUV update: incompatible texture format");
    w=SDL_GetNumberProperty(props,SDL_PROP_TEXTURE_WIDTH_NUMBER,0);h=SDL_GetNumberProperty(props,SDL_PROP_TEXTURE_HEIGHT_NUMBER,0);
    if(w<=0 || h<=0 || w>INT_MAX || h>INT_MAX)return SDL_SetError("YUV update: invalid texture size");
    return true;
}
}
inline bool SDL_UpdateYUVTextureArrays(SDL_Texture * texture,const das::TArray<uint8_t> & y,int yp,const das::TArray<uint8_t> & u,int up,const das::TArray<uint8_t> & v,int vp) {
    int64_t w,h;if(!sdl3_yuv::size(texture,false,w,h))return false;
    if(!sdl3_yuv::plane(y,yp,w,h) || !sdl3_yuv::plane(u,up,(w+1)/2,(h+1)/2) || !sdl3_yuv::plane(v,vp,(w+1)/2,(h+1)/2))return false;
    return SDL_UpdateYUVTexture(texture,nullptr,reinterpret_cast<const Uint8 *>(y.data),yp,reinterpret_cast<const Uint8 *>(u.data),up,reinterpret_cast<const Uint8 *>(v.data),vp);
}
inline bool SDL_UpdateNVTextureArrays(SDL_Texture * texture,const das::TArray<uint8_t> & y,int yp,const das::TArray<uint8_t> & uv,int uvp) {
    int64_t w,h;if(!sdl3_yuv::size(texture,true,w,h))return false;
    if(!sdl3_yuv::plane(y,yp,w,h) || !sdl3_yuv::plane(uv,uvp,2*((w+1)/2),(h+1)/2))return false;
    return SDL_UpdateNVTexture(texture,nullptr,reinterpret_cast<const Uint8 *>(y.data),yp,reinterpret_cast<const Uint8 *>(uv.data),uvp);
}
