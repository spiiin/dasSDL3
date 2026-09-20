#pragma once
#include <SDL3/SDL.h>
inline bool SDL_CreateWindowAndRendererRef(const char * title,int w,int h,SDL_WindowFlags flags,SDL_Window * & window,SDL_Renderer * & renderer) {return SDL_CreateWindowAndRenderer(title,w,h,flags,&window,&renderer);}
inline bool SDL_GetRenderVSyncRef(SDL_Renderer * renderer,int & vsync) {return SDL_GetRenderVSync(renderer,&vsync);}
inline SDL_Surface * SDL_RenderReadPixelsRect(SDL_Renderer * renderer,const SDL_Rect & rect) {return SDL_RenderReadPixels(renderer,&rect);}
inline bool SDL_RenderTextureRotatedRefs(SDL_Renderer * renderer,SDL_Texture * texture,const SDL_FRect & src,const SDL_FRect & dst,double angle,const SDL_FPoint & center,SDL_FlipMode flip) {return SDL_RenderTextureRotated(renderer,texture,&src,&dst,angle,&center,flip);}
inline bool SDL_RenderTextureAffineRefs(SDL_Renderer * renderer,SDL_Texture * texture,const SDL_FRect & src,const SDL_FPoint & origin,const SDL_FPoint & right,const SDL_FPoint & down) {return SDL_RenderTextureAffine(renderer,texture,&src,&origin,&right,&down);}
inline bool SDL_RenderTextureTiledRefs(SDL_Renderer * renderer,SDL_Texture * texture,const SDL_FRect & src,float scale,const SDL_FRect & dst) {return SDL_RenderTextureTiled(renderer,texture,&src,scale,&dst);}
inline bool SDL_RenderTexture9GridRefs(SDL_Renderer * renderer,SDL_Texture * texture,const SDL_FRect & src,float left,float right,float top,float bottom,float scale,const SDL_FRect & dst) {return SDL_RenderTexture9Grid(renderer,texture,&src,left,right,top,bottom,scale,&dst);}
