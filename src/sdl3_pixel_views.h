#pragma once
#include "sdl3_texture_transfer.h"
#include "daScript/ast/ast_handle.h"
#include <cstring>

// Only constructed on the stack for a synchronous block. No exposed pixel pointer.
struct SdlPixelView {
    int width, height, pitch;
    uint8_t * data;
};
MAKE_TYPE_FACTORY(SdlPixelView, SdlPixelView);
namespace das {
struct SdlPixelViewAnnotation : ManagedStructureAnnotation<SdlPixelView, false> {
    bool canCopy() const override { return false; }
    bool canMove() const override { return false; }
    bool canClone() const override { return false; }
    SdlPixelViewAnnotation(ModuleLibrary & lib) : ManagedStructureAnnotation("SdlPixelView",lib) {
        cppName="::SdlPixelView";
        addField<DAS_BIND_MANAGED_FIELD(width)>("width");
        addField<DAS_BIND_MANAGED_FIELD(height)>("height");
        addField<DAS_BIND_MANAGED_FIELD(pitch)>("pitch");
    }
};
}
inline bool SDL_WithSurfacePixelsRGBA8(SDL_Surface * surface,
    const das::TBlock<void,das::TTemporary<const SdlPixelView>> & body,
    das::Context * context, das::LineInfoArg * at) {
    if(!surface || surface->format!=SDL_PIXELFORMAT_RGBA32 || !surface->pixels ||
       surface->w<=0 || surface->h<=0 || int64_t(surface->pitch)<int64_t(surface->w)*4)
        return SDL_SetError("Pixel view requires locked RGBA32 surface with valid dimensions/pitch");
    SdlPixelView view{surface->w,surface->h,surface->pitch,static_cast<uint8_t *>(surface->pixels)};
    vec4f args[]={das::cast<SdlPixelView *>::from(&view)};
    context->invoke(body,args,nullptr,at);
    return true;
}
inline bool SDL_SetPixelRGBA8(const SdlPixelView & view,int x,int y,das::uint4 color) {
    if(!view.data || x<0 || y<0 || x>=view.width || y>=view.height ||
       color.x>255 || color.y>255 || color.z>255 || color.w>255)
        return SDL_SetError("Pixel coordinate or RGBA component out of range");
    auto p=view.data+size_t(y)*view.pitch+size_t(x)*4;
    p[0]=uint8_t(color.x);p[1]=uint8_t(color.y);p[2]=uint8_t(color.z);p[3]=uint8_t(color.w);
    return true;
}
inline uint32_t SDL_PackRGBA8(uint32_t r,uint32_t g,uint32_t b,uint32_t a) {
    const uint8_t bytes[]={uint8_t(r),uint8_t(g),uint8_t(b),uint8_t(a)};
    uint32_t packed;std::memcpy(&packed,bytes,4);return packed;
}
inline bool SDL_WithPixelRowRGBA8(const SdlPixelView & view,int y,
    const das::TBlock<void,das::TTemporary<das::TArray<uint32_t>>> & body,
    das::Context * context,das::LineInfoArg * at) {
    if(!view.data || y<0 || y>=view.height) return SDL_SetError("Pixel row out of range");
    auto data=view.data+size_t(y)*view.pitch;
    if(reinterpret_cast<uintptr_t>(data)%alignof(uint32_t)) return SDL_SetError("Unaligned RGBA32 row");
    das::Array row;das::array_mark_locked(row,data,uint32_t(view.width));
    vec4f args[]={das::cast<das::Array *>::from(&row)};
    context->invoke(body,args,nullptr,at);return true;
}
inline bool SDL_WithPixelBytesRGBA8(const SdlPixelView & view,
    const das::TBlock<void,das::TTemporary<das::TArray<uint8_t>>> & body,
    das::Context * context,das::LineInfoArg * at) {
    const uint64_t size=uint64_t(view.height-1)*view.pitch+uint64_t(view.width)*4;
    if(!view.data || size>UINT32_MAX) return SDL_SetError("Pixel view exceeds array size");
    das::Array bytes;das::array_mark_locked(bytes,view.data,uint32_t(size));
    vec4f args[]={das::cast<das::Array *>::from(&bytes)};
    context->invoke(body,args,nullptr,at);return true;
}
