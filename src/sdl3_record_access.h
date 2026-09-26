#pragma once
#include "sdl3_pixel_views.h"
#include <vector>
#include <string>
#include <climits>

inline bool SDL_GetSurfaceMetadata(SDL_Surface *s, uint32_t &flags, SDL_PixelFormat &format, das::int3 &size_pitch) {
    flags=0; format=SDL_PIXELFORMAT_UNKNOWN; size_pitch={};
    if(!s) return SDL_InvalidParamError("surface");
    flags=s->flags;format=s->format;size_pitch={s->w,s->h,s->pitch};return true;
}
inline bool SDL_GetPaletteColorsCopy(SDL_Palette *p, das::TArray<SDL_Color> &out, das::Context *ctx,das::LineInfoArg *at) {
    das::builtin_array_resize(out,0,sizeof(SDL_Color),ctx,at);
    if(!p) return SDL_InvalidParamError("palette");
    if(p->ncolors<0 || uint64_t(p->ncolors)*sizeof(SDL_Color)>INT_MAX || (p->ncolors && !p->colors))
        return SDL_SetError("Invalid palette color storage");
    das::builtin_array_resize(out,p->ncolors,sizeof(SDL_Color),ctx,at);
    if(p->ncolors) SDL_memcpy(out.data,p->colors,size_t(p->ncolors)*sizeof(SDL_Color));
    return true;
}
// Native SDL surface storage must be valid, including the extent supplied to CreateSurfaceFrom.
// Plane order is physical storage order (Y,V,U for YV12; Y,U,V for IYUV).
namespace sdl3_surface_planes {
struct Layout { uint64_t offset=0, row=0, pitch=0, rows=0; int planes=1; };
inline bool layout(SDL_Surface *s,int plane,Layout &o) {
    if(!s) return SDL_InvalidParamError("surface");
    if(s->w<0 || s->h<0 || s->pitch<0 || plane<0) return SDL_SetError("Invalid surface plane geometry");
    const uint64_t w=s->w,h=s->h,p=s->pitch,cw=(w+1)/2,ch=(h+1)/2;
    o={};o.pitch=p;o.rows=h;
    switch(s->format) {
    case SDL_PIXELFORMAT_MJPG: o.row=p;o.rows=1;break;
    case SDL_PIXELFORMAT_IYUV: case SDL_PIXELFORMAT_YV12:
        o.planes=3;o.row=w;
        if(plane>0) {o.offset=p*h+(plane==2 ? ((p+1)/2)*ch : 0);o.pitch=(p+1)/2;o.row=cw;o.rows=ch;}
        break;
    case SDL_PIXELFORMAT_NV12: case SDL_PIXELFORMAT_NV21:
        o.planes=2;o.row=w;
        if(plane>0) {o.offset=p*h;o.pitch=2*((p+1)/2);o.row=2*cw;o.rows=ch;}
        break;
    case SDL_PIXELFORMAT_P010:
        o.planes=2;o.row=2*w;
        if(plane>0) {o.offset=p*h;o.pitch=SDL_max(p,4*cw);o.row=4*cw;o.rows=ch;}
        break;
    case SDL_PIXELFORMAT_YUY2: case SDL_PIXELFORMAT_UYVY: case SDL_PIXELFORMAT_YVYU: o.row=4*cw;break;
    default:
        if(SDL_ISPIXELFORMAT_FOURCC(s->format) || s->format==SDL_PIXELFORMAT_UNKNOWN)
            return SDL_SetError("Unsupported surface plane format");
        o.row=SDL_BYTESPERPIXEL(s->format) ? w*SDL_BYTESPERPIXEL(s->format) : (w*SDL_BITSPERPIXEL(s->format)+7)/8;
        break;
    }
    if(plane>=o.planes || o.pitch<o.row || o.row>INT_MAX || o.pitch>INT_MAX || o.rows>INT_MAX)
        return SDL_SetError("Invalid surface plane or pitch");
    // Exclude padding after the last row; external memory may end at its last pixel.
    const uint64_t count=(o.rows && o.row) ? (o.rows-1)*o.pitch+o.row : 0;
    if(count>INT_MAX || o.offset>SIZE_MAX-count || (count && !s->pixels))
        return SDL_SetError("Surface plane exceeds valid byte storage");
    return true;
}
}
inline bool SDL_GetSurfacePlaneInfo(SDL_Surface *s,int plane,das::int4 &info) {
    info={};sdl3_surface_planes::Layout l;
    if(!sdl3_surface_planes::layout(s,plane,l)) return false;
    info={int(l.row),int(l.rows),int(l.pitch),l.planes};return true;
}
inline bool SDL_WithSurfacePlaneBytes(SDL_Surface *s,int plane,
    const das::TBlock<void,das::TTemporary<das::TArray<uint8_t>>,das::int4> &body,
    das::Context *ctx,das::LineInfoArg *at) {
    sdl3_surface_planes::Layout l;
    if(!sdl3_surface_planes::layout(s,plane,l)) return false;
    uint32_t count=(l.rows && l.row) ? uint32_t((l.rows-1)*l.pitch+l.row) : 0;
    auto *data=count ? static_cast<uint8_t *>(s->pixels)+size_t(l.offset) : nullptr;
    das::Array bytes;das::array_mark_locked(bytes,data,count);
    das::int4 info{int(l.row),int(l.rows),int(l.pitch),l.planes};
    vec4f args[]={das::cast<das::Array *>::from(&bytes),das::cast<das::int4>::from(info)};
    ctx->invoke(body,args,nullptr,at);return true;
}

// Native callback addresses only. SDL copies the descriptor, not the pointed-to host state.
inline void SDL_SetVirtualJoystickDesc_Update(SDL_VirtualJoystickDesc &desc,void *address) {desc.Update=reinterpret_cast<decltype(desc.Update)>(address);}
inline void SDL_SetVirtualJoystickDesc_SetPlayerIndex(SDL_VirtualJoystickDesc &desc,void *address) {desc.SetPlayerIndex=reinterpret_cast<decltype(desc.SetPlayerIndex)>(address);}
inline void SDL_SetVirtualJoystickDesc_Rumble(SDL_VirtualJoystickDesc &desc,void *address) {desc.Rumble=reinterpret_cast<decltype(desc.Rumble)>(address);}
inline void SDL_SetVirtualJoystickDesc_RumbleTriggers(SDL_VirtualJoystickDesc &desc,void *address) {desc.RumbleTriggers=reinterpret_cast<decltype(desc.RumbleTriggers)>(address);}
inline void SDL_SetVirtualJoystickDesc_SetLED(SDL_VirtualJoystickDesc &desc,void *address) {desc.SetLED=reinterpret_cast<decltype(desc.SetLED)>(address);}
inline void SDL_SetVirtualJoystickDesc_SendEffect(SDL_VirtualJoystickDesc &desc,void *address) {desc.SendEffect=reinterpret_cast<decltype(desc.SendEffect)>(address);}
inline void SDL_SetVirtualJoystickDesc_SetSensorsEnabled(SDL_VirtualJoystickDesc &desc,void *address) {desc.SetSensorsEnabled=reinterpret_cast<decltype(desc.SetSensorsEnabled)>(address);}
inline void SDL_SetVirtualJoystickDesc_Cleanup(SDL_VirtualJoystickDesc &desc,void *address) {desc.Cleanup=reinterpret_cast<decltype(desc.Cleanup)>(address);}

namespace sdl3_vulkan_options {
struct Copy { SDL_PropertiesID target; bool ok=true; };
// Copy values, never SDL's numeric-to-string cache or cleanup ownership.
inline void SDLCALL copy_value(void *userdata,SDL_PropertiesID source,const char *name) {
    auto &c=*static_cast<Copy *>(userdata);
    if(!c.ok) return;
    switch(SDL_GetPropertyType(source,name)) {
    case SDL_PROPERTY_TYPE_POINTER:c.ok=SDL_SetPointerProperty(c.target,name,SDL_GetPointerProperty(source,name,nullptr));break;
    case SDL_PROPERTY_TYPE_STRING:c.ok=SDL_SetStringProperty(c.target,name,SDL_GetStringProperty(source,name,nullptr));break;
    case SDL_PROPERTY_TYPE_NUMBER:c.ok=SDL_SetNumberProperty(c.target,name,SDL_GetNumberProperty(source,name,0));break;
    case SDL_PROPERTY_TYPE_FLOAT:c.ok=SDL_SetFloatProperty(c.target,name,SDL_GetFloatProperty(source,name,0));break;
    case SDL_PROPERTY_TYPE_BOOLEAN:c.ok=SDL_SetBooleanProperty(c.target,name,SDL_GetBooleanProperty(source,name,false));break;
    default:c.ok=SDL_SetError("Unsupported Vulkan creation property type");break;
    }
}
}
// Private value copy: no caller properties, cache or cleanup ownership are changed.
// Pointer values are borrowed until synchronous device creation returns.
inline SDL_GPUDevice *SDL_CreateGPUDeviceWithVulkanOptions(SDL_PropertiesID properties,
        const SDL_GPUVulkanOptions &options,const das::TArray<char *> &device_extensions,
        const das::TArray<char *> &instance_extensions) {
    for(const auto *a : {&device_extensions,&instance_extensions}) {
        if(a->size>INT_MAX || (a->size && !a->data)) {SDL_SetError("Invalid Vulkan extension array");return nullptr;}
        auto **names=reinterpret_cast<char **>(a->data);
        for(uint32_t i=0;i<a->size;++i) if(!names[i] || !*names[i]) {SDL_SetError("Empty Vulkan extension name");return nullptr;}
    }
    SDL_GPUVulkanOptions local=options;
    local.device_extension_count=device_extensions.size;
    local.device_extension_names=reinterpret_cast<const char **>(device_extensions.data);
    local.instance_extension_count=instance_extensions.size;
    local.instance_extension_names=reinterpret_cast<const char **>(instance_extensions.data);
    SDL_PropertiesID props=SDL_CreateProperties();
    if(!props) return nullptr;
    SDL_GPUDevice *device=nullptr;
    sdl3_vulkan_options::Copy copy{props};
    if(SDL_EnumerateProperties(properties,sdl3_vulkan_options::copy_value,&copy) && copy.ok && SDL_SetStringProperty(props,SDL_PROP_GPU_DEVICE_CREATE_NAME_STRING,"vulkan") && SDL_SetPointerProperty(props,SDL_PROP_GPU_DEVICE_CREATE_VULKAN_OPTIONS_POINTER,&local))
        device=SDL_CreateGPUDeviceWithProperties(props);
    std::string error=device ? "" : SDL_GetError();
    SDL_DestroyProperties(props);
    if(!device) SDL_SetError("%s",error.c_str());
    return device;
}

#ifdef DASSDL3_TESTING
#include "../tests/record_access_probe.h"
#endif
