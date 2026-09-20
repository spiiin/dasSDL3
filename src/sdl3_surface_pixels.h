#pragma once
#include "sdl3_pixels.h"
#include "sdl3_video.h"
inline bool SDL_GetMasksForPixelFormatRef(SDL_PixelFormat format,int & bpp,uint32_t & r,uint32_t & g,uint32_t & b,uint32_t & a) {return SDL_GetMasksForPixelFormat(format,&bpp,&r,&g,&b,&a);}
inline bool SDL_GetPixelFormatDetailsCopy(SDL_PixelFormat format,SDL_PixelFormatDetails & out) {auto * p=SDL_GetPixelFormatDetails(format);if(!p){out={};return false;}out=*p;return true;}
inline void SDL_GetRGBRef(uint32_t pixel,const SDL_PixelFormatDetails & format,const SDL_Palette * palette,uint32_t & r,uint32_t & g,uint32_t & b) {Uint8 nr=0,ng=0,nb=0;SDL_GetRGB(pixel,&format,palette,&nr,&ng,&nb);r=nr;g=ng;b=nb;}
inline void SDL_GetRGBARef(uint32_t pixel,const SDL_PixelFormatDetails & format,const SDL_Palette * palette,uint32_t & r,uint32_t & g,uint32_t & b,uint32_t & a) {Uint8 nr=0,ng=0,nb=0,na=0;SDL_GetRGBA(pixel,&format,palette,&nr,&ng,&nb,&na);r=nr;g=ng;b=nb;a=na;}
inline uint32_t SDL_MapRGBRef(const SDL_PixelFormatDetails & format,const SDL_Palette * palette,uint32_t r,uint32_t g,uint32_t b) {return SDL_MapRGB(&format,palette,Uint8(r),Uint8(g),Uint8(b));}
inline uint32_t SDL_MapRGBARef(const SDL_PixelFormatDetails & format,const SDL_Palette * palette,uint32_t r,uint32_t g,uint32_t b,uint32_t a) {return SDL_MapRGBA(&format,palette,Uint8(r),Uint8(g),Uint8(b),Uint8(a));}
inline bool SDL_ReadSurfacePixelRef(SDL_Surface * surface,int x,int y,uint32_t & r,uint32_t & g,uint32_t & b,uint32_t & a) {Uint8 nr=0,ng=0,nb=0,na=0;const bool ok=SDL_ReadSurfacePixel(surface,x,y,&nr,&ng,&nb,&na);r=nr;g=ng;b=nb;a=na;return ok;}
inline bool SDL_ReadSurfacePixelFloatRef(SDL_Surface * surface,int x,int y,float & r,float & g,float & b,float & a) {return SDL_ReadSurfacePixelFloat(surface,x,y,&r,&g,&b,&a);}
inline bool SDL_SetPaletteColorsArray(SDL_Palette * palette,const das::TArray<SDL_Color> & colors,int first) {if(colors.size>uint32_t(INT_MAX)/sizeof(SDL_Color))return SDL_SetError("Palette array too large");return SDL_SetPaletteColors(palette,reinterpret_cast<const SDL_Color *>(colors.data),first,int(colors.size));}
inline bool SDL_FillSurfaceRectsArray(SDL_Surface * surface,const das::TArray<SDL_Rect> & rects,uint32_t color) {if(rects.size>uint32_t(INT_MAX)/sizeof(SDL_Rect))return SDL_SetError("Rectangle array too large");return SDL_FillSurfaceRects(surface,reinterpret_cast<const SDL_Rect *>(rects.data),int(rects.size),color);}
inline bool SDL_GetSurfaceImagesCopy(SDL_Surface * surface,das::TArray<SDL_Surface *> & output,das::Context * context,das::LineInfoArg * at) {int count=0;auto ** images=SDL_GetSurfaceImages(surface,&count);return sdl3_video::copy_array(images,count,output,context,at);}
inline bool SDL_BlitSurfaceAll(SDL_Surface * src,SDL_Surface * dst) {return SDL_BlitSurface(src,nullptr,dst,nullptr);}
inline bool SDL_BlitSurfaceRefs(SDL_Surface * src,const SDL_Rect & sr,SDL_Surface * dst,const SDL_Rect & dr) {return SDL_BlitSurface(src,&sr,dst,&dr);}
inline bool SDL_BlitSurfaceScaledRefs(SDL_Surface * src,const SDL_Rect & sr,SDL_Surface * dst,const SDL_Rect & dr,SDL_ScaleMode mode) {return SDL_BlitSurfaceScaled(src,&sr,dst,&dr,mode);}
inline bool SDL_StretchSurfaceRefs(SDL_Surface * src,const SDL_Rect & sr,SDL_Surface * dst,const SDL_Rect & dr,SDL_ScaleMode mode) {return SDL_StretchSurface(src,&sr,dst,&dr,mode);}
inline bool SDL_BlitSurfaceTiledRefs(SDL_Surface * src,const SDL_Rect & sr,SDL_Surface * dst,const SDL_Rect & dr) {return SDL_BlitSurfaceTiled(src,&sr,dst,&dr);}
inline bool SDL_BlitSurfaceTiledWithScaleRefs(SDL_Surface * src,const SDL_Rect & sr,float scale,SDL_ScaleMode mode,SDL_Surface * dst,const SDL_Rect & dr) {return SDL_BlitSurfaceTiledWithScale(src,&sr,scale,mode,dst,&dr);}
inline bool SDL_BlitSurface9GridRefs(SDL_Surface * src,const SDL_Rect & sr,int left,int right,int top,int bottom,float scale,SDL_ScaleMode mode,SDL_Surface * dst,const SDL_Rect & dr) {return SDL_BlitSurface9Grid(src,&sr,left,right,top,bottom,scale,mode,dst,&dr);}
namespace sdl3_surface_pixels {
// Array conveniences support packed, byte-addressed pixels only; raw SDL also supports planar formats.
inline bool fits(int w,int h,SDL_PixelFormat format,int pitch,const das::TArray<uint8_t> & bytes) {
    if(w<=0 || h<=0 || SDL_ISPIXELFORMAT_FOURCC(format) || SDL_BITSPERPIXEL(format)<8)return SDL_SetError("Expected positive packed-pixel dimensions");
    const int bpp=SDL_BYTESPERPIXEL(format);const int64_t row=int64_t(w)*bpp;
    if(bpp<=0 || row>INT_MAX || pitch<row || uint64_t(h)*uint64_t(pitch)>bytes.size || !bytes.data)return SDL_SetError("Pixel buffer pitch/capacity mismatch");
    return true;
}
}
inline bool SDL_ConvertPixelsArray(int w,int h,SDL_PixelFormat sf,const das::TArray<uint8_t> & src,int sp,SDL_PixelFormat df,das::TArray<uint8_t> & dst,int dp) {
    if(!sdl3_surface_pixels::fits(w,h,sf,sp,src) || !sdl3_surface_pixels::fits(w,h,df,dp,dst))return false;
    return SDL_ConvertPixels(w,h,sf,src.data,sp,df,dst.data,dp);
}
inline bool SDL_ConvertPixelsAndColorspaceArray(int w,int h,SDL_PixelFormat sf,SDL_Colorspace sc,SDL_PropertiesID spr,const das::TArray<uint8_t> & src,int sp,SDL_PixelFormat df,SDL_Colorspace dc,SDL_PropertiesID dpr,das::TArray<uint8_t> & dst,int dp) {
    if(!sdl3_surface_pixels::fits(w,h,sf,sp,src) || !sdl3_surface_pixels::fits(w,h,df,dp,dst))return false;
    return SDL_ConvertPixelsAndColorspace(w,h,sf,sc,spr,src.data,sp,df,dc,dpr,dst.data,dp);
}
inline bool SDL_PremultiplyAlphaArray(int w,int h,SDL_PixelFormat sf,const das::TArray<uint8_t> & src,int sp,SDL_PixelFormat df,das::TArray<uint8_t> & dst,int dp,bool linear) {
    if(!sdl3_surface_pixels::fits(w,h,sf,sp,src) || !sdl3_surface_pixels::fits(w,h,df,dp,dst))return false;
    return SDL_PremultiplyAlpha(w,h,sf,src.data,sp,df,dst.data,dp,linear);
}
