#pragma once
#include "sdl3_geometry.h"
inline bool SDL_ConvertEventToRenderCoordinatesRef(SDL_Renderer * renderer,SDL_Event & event) {return SDL_ConvertEventToRenderCoordinates(renderer,&event);}
inline void SDL_WriteMouseMotionEvent(const SDL_MouseMotionEvent & motion,SDL_Event & event) {event={};event.motion=motion;event.type=SDL_EVENT_MOUSE_MOTION;}
inline void SDL_WriteMouseButtonEvent(const SDL_MouseButtonEvent & button,SDL_Event & event) {event={};event.button=button;event.type=button.down ? SDL_EVENT_MOUSE_BUTTON_DOWN : SDL_EVENT_MOUSE_BUTTON_UP;}
inline void SDL_WriteMouseWheelEvent(const SDL_MouseWheelEvent & wheel,SDL_Event & event) {event={};event.wheel=wheel;event.type=SDL_EVENT_MOUSE_WHEEL;}
inline bool SDL_RenderDebugTextFormatText(SDL_Renderer * renderer,float x,float y,const char * text) {return SDL_RenderDebugTextFormat(renderer,x,y,"%s",text ? text : "");}
namespace sdl3_raw_geometry {
inline bool draw(SDL_Renderer * renderer,SDL_Texture * texture,const das::TArray<SDL_FPoint> & xy,const das::TArray<SDL_FColor> & colors,const das::TArray<SDL_FPoint> & uv,const das::TArray<int32_t> * indices) {
    if(!renderer)return SDL_SetError("Raw geometry: null renderer");
    if(xy.size>uint32_t(INT_MAX)/sizeof(SDL_FColor) || (indices && indices->size>uint32_t(INT_MAX)/sizeof(int32_t)))return SDL_SetError("Raw geometry: array exceeds byte budget");
    if(colors.size!=xy.size || (texture && uv.size!=xy.size) || (!texture && uv.size!=0 && uv.size!=xy.size))return SDL_SetError("Raw geometry: attribute count mismatch");
    const uint32_t count=indices ? indices->size : xy.size;
    if(count%3)return SDL_SetError("Raw geometry: incomplete triangles");
    if(!count)return true; // Empty indexed draws do not become sequential draws.
    if(!xy.data || !colors.data || (texture && !uv.data) || (indices && !indices->data))return SDL_SetError("Raw geometry: missing storage");
    const auto * idx=indices ? reinterpret_cast<const int32_t *>(indices->data) : nullptr;
    if(idx)for(uint32_t i=0;i<count;++i)if(idx[i]<0 || uint32_t(idx[i])>=xy.size)return SDL_SetError("Raw geometry: index outside vertices");
    return SDL_RenderGeometryRaw(renderer,texture,reinterpret_cast<const float *>(xy.data),sizeof(SDL_FPoint),reinterpret_cast<const SDL_FColor *>(colors.data),sizeof(SDL_FColor),texture ? reinterpret_cast<const float *>(uv.data) : nullptr,sizeof(SDL_FPoint),int(xy.size),idx,int(indices ? count : 0),indices ? sizeof(int32_t) : 0);
}
}
inline bool SDL_RenderGeometryRawArrays(SDL_Renderer * renderer,SDL_Texture * texture,const das::TArray<SDL_FPoint> & xy,const das::TArray<SDL_FColor> & colors,const das::TArray<SDL_FPoint> & uv) {return sdl3_raw_geometry::draw(renderer,texture,xy,colors,uv,nullptr);}
inline bool SDL_RenderGeometryRawIndexedArrays(SDL_Renderer * renderer,SDL_Texture * texture,const das::TArray<SDL_FPoint> & xy,const das::TArray<SDL_FColor> & colors,const das::TArray<SDL_FPoint> & uv,const das::TArray<int32_t> & indices) {return sdl3_raw_geometry::draw(renderer,texture,xy,colors,uv,&indices);}
