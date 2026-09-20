#pragma once
#include "sdl3_gpu_texture_transfer.h"

inline bool SDL_GPUImageFormat(uint32_t format) {
    return (format==SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM || format==SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM) ||
        SDL_SetError("GPU image: RGBA8 or BGRA8 UNORM required");
}
inline uint64_t SDL_CreateGPUColorTargetTexture(SDL_GPUDevice * device,uint32_t width,uint32_t height,uint32_t layers,uint32_t levels,uint32_t format) {
    if (!SDL_GPUImageFormat(format)) return 0;
    return SDL_CreateGPUTransferTextureWithUsage(device,width,height,layers,levels,format,
        layers==1 ? SDL_GPU_TEXTURETYPE_2D : SDL_GPU_TEXTURETYPE_2D_ARRAY,
        SDL_GPU_TEXTUREUSAGE_SAMPLER|SDL_GPU_TEXTUREUSAGE_COLOR_TARGET);
}
inline bool SDL_GenerateGPUTextureMipmapsChecked(SDL_GPUDevice * device,uint64_t id) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,id); if (!entry) return false;
    if (!SDL_GPUImageFormat(entry->format)) return false;
    if (!(entry->usage&SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) || entry->levels<2)
        return SDL_SetError("GPU mipmaps: color-target texture with multiple levels required");
    for (uint32_t layer=0;layer<entry->layers;++layer)
        if (!entry->valid[layer*entry->levels]) return SDL_SetError("GPU mipmaps: all base layers must be valid");
    SDL_GPUTransferBuild build{device}; build.command=SDL_AcquireGPUCommandBuffer(device);
    if (!build.command) return false;
    // SDL starts its own render work. Never wrap this in a copy/render pass.
    SDL_GenerateMipmapsForGPUTexture(build.command,entry->texture);
    const bool ok=build.submit();
    for (uint32_t layer=0;layer<entry->layers;++layer)
        for (uint32_t mip=1;mip<entry->levels;++mip) entry->valid[layer*entry->levels+mip]=ok;
    return ok;
}
inline SDL_GPUBlitRegion SDL_GPUImageRegion(SDL_GPUTexture * texture,das::uint2 sub,das::uint4 rect) {
    SDL_GPUBlitRegion result{}; result.texture=texture; result.mip_level=sub.x; result.layer_or_depth_plane=sub.y;
    result.x=rect.x; result.y=rect.y; result.w=rect.z; result.h=rect.w; return result;
}
inline bool SDL_BlitGPUTextureChecked(SDL_GPUDevice * device,uint64_t source,das::uint2 sourceSub,das::uint4 sourceRect,
        uint64_t destination,das::uint2 destSub,das::uint4 destRect,uint32_t filter) {
    auto * src=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,source); if (!src) return false;
    auto * dst=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,destination); if (!dst) return false;
    if (!SDL_GPUImageFormat(src->format)) return false;
    if (source==destination || src->format!=dst->format || !(dst->usage&SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) || filter>SDL_GPU_FILTER_LINEAR)
        return SDL_SetError("GPU blit: distinct matching textures, color-target destination and valid filter required");
    SDL_GPUTextureFootprint footprint{};
    if (!SDL_GPUTextureSubregion(*src,sourceSub,sourceRect,footprint) || !SDL_GPUTextureSubregion(*dst,destSub,destRect,footprint)) return false;
    const auto sourceIndex=sourceSub.y*src->levels+sourceSub.x, destIndex=destSub.y*dst->levels+destSub.x;
    if (!src->valid[sourceIndex] || !dst->valid[destIndex]) return SDL_SetError("GPU blit: initialized subresources required");
    SDL_GPUBlitInfo info{};
    info.source=SDL_GPUImageRegion(src->texture,sourceSub,sourceRect);
    info.destination=SDL_GPUImageRegion(dst->texture,destSub,destRect);
    info.load_op=SDL_GPU_LOADOP_LOAD; info.filter=SDL_GPUFilter(filter); info.flip_mode=SDL_FLIP_NONE; info.cycle=false;
    SDL_GPUTransferBuild build{device}; build.command=SDL_AcquireGPUCommandBuffer(device);
    if (!build.command) return false;
    SDL_BlitGPUTexture(build.command,&info);
    const bool ok=build.submit(); dst->valid[destIndex]=ok; return ok;
}
