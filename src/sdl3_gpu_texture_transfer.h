#pragma once
#include "sdl3_gpu_formats.h"

struct SDL_GPUTransferTexture {
    SDL_GPUDevice * device;
    SDL_GPUTexture * texture;
    uint32_t width, height, layers, levels;
    uint32_t format, bytesPerTexel, blockWidth, blockHeight, usage;
    std::vector<bool> valid;
    uint32_t type=SDL_GPU_TEXTURETYPE_2D;
};
inline std::unordered_map<uint64_t,SDL_GPUTransferTexture> SDL_GPUTransferTextures;
struct SDL_GPUTextureFootprint { uint32_t rowBytes, rowPitch, size, rows, pixelsPerRow; };
inline bool SDL_GPUTextureFootprintBlocks(uint32_t width,uint32_t height,uint32_t bytesPerTexel,uint32_t blockWidth,uint32_t blockHeight,SDL_GPUTextureFootprint & out) {
    if (!width || !height || width>8192 || height>8192 || !bytesPerTexel || !blockWidth || !blockHeight)
        return SDL_SetError("GPU texture: dimensions must be 1..8192");
    const uint64_t row=uint64_t((width+blockWidth-1)/blockWidth)*bytesPerTexel;
    const uint64_t pitch=(row+255)&~uint64_t(255); // D3D12-compatible staging row alignment.
    const uint32_t rows=(height+blockHeight-1)/blockHeight;
    const uint64_t size=pitch*rows;
    if (size>SDL_GPUDataLimit) return SDL_SetError("GPU texture: staging footprint exceeds 64 MiB");
    out={uint32_t(row),uint32_t(pitch),uint32_t(size),rows,uint32_t(pitch/bytesPerTexel)*blockWidth}; return true;
}
// Compatibility helper for existing color/BC and 3D volume callers.
inline bool SDL_GPUTextureFootprintColor(uint32_t width,uint32_t height,uint32_t bytesPerTexel,uint32_t blockWidth,SDL_GPUTextureFootprint & out) {
    return SDL_GPUTextureFootprintBlocks(width,height,bytesPerTexel,blockWidth,blockWidth,out);
}
inline uint32_t SDL_GPUTextureLevelSize(uint32_t size,uint32_t level) { return std::max(1u,size>>level); }
inline bool SDL_GPUTextureSubregion(const SDL_GPUTransferTexture & texture,das::uint2 sub,
        das::uint4 rect,SDL_GPUTextureFootprint & footprint) {
    if (sub.x>=texture.levels || sub.y>=texture.layers) return SDL_SetError("GPU texture: invalid mip or layer");
    const auto width=SDL_GPUTextureLevelSize(texture.width,sub.x), height=SDL_GPUTextureLevelSize(texture.height,sub.x);
    if (rect.x>width || rect.y>height || rect.z>width-rect.x || rect.w>height-rect.y)
        return SDL_SetError("GPU texture: region out of bounds");
    if (rect.x%texture.blockWidth || rect.y%texture.blockHeight ||
        (rect.z%texture.blockWidth && rect.x+rect.z!=width) ||
        (rect.w%texture.blockHeight && rect.y+rect.w!=height))
        return SDL_SetError("GPU texture: block-aligned region or mip edge required");
    return SDL_GPUTextureFootprintBlocks(rect.z,rect.w,texture.bytesPerTexel,texture.blockWidth,texture.blockHeight,footprint);
}
// D3D12 CopyTextureRegion boxes use physical block-aligned mip extents.
// Vulkan requires logical edge extents instead. Validate logical bounds first.
inline das::uint4 SDL_GPUTextureNativeRect(SDL_GPUDevice * device,uint32_t blockWidth,uint32_t blockHeight,das::uint4 rect) {
    if (blockWidth>1 && SDL_strcmp(SDL_GetGPUDeviceDriver(device),"direct3d12")==0) {
        rect.z=(rect.z+blockWidth-1)/blockWidth*blockWidth;
        rect.w=(rect.w+blockHeight-1)/blockHeight*blockHeight;
    }
    return rect;
}
inline SDL_GPUTextureRegion SDL_GPUTextureMakeRegion(SDL_GPUTexture * texture,das::uint2 sub,das::uint4 rect) {
    SDL_GPUTextureRegion result{}; result.texture=texture; result.mip_level=sub.x; result.layer=sub.y;
    result.x=rect.x; result.y=rect.y; result.w=rect.z; result.h=rect.w; result.d=1; return result;
}
inline bool SDL_GPUTextureSourceBytes(const das::TArray<uint8_t> & bytes,uint32_t row,uint32_t height,uint32_t pitch) {
    if (!height || pitch<row || uint64_t(pitch)*(height-1)+row>bytes.size ||
            bytes.size>SDL_GPUDataLimit || !bytes.data)
        return SDL_SetError("GPU texture: source pitch/array too small or over 64 MiB");
    return true;
}
inline bool SDL_GPUTextureTransferBackendAllowed(SDL_GPUDevice * device,uint32_t format) {
    // SDL 3.2.18 exposes no public query for enabled Vulkan device extensions.
    return format<SDL_GPU_TEXTUREFORMAT_ASTC_4x4_FLOAT || SDL_strcmp(SDL_GetGPUDeviceDriver(device),"vulkan")!=0;
}
inline int SDL_GPUTextureTransferSupportedChecked(SDL_GPUDevice * device,uint32_t format,uint32_t type) {
    if (!SDL_GPUTransferDevice(device) || !SDL_GPUFormatValid(format)) return -1;
    if (type>SDL_GPU_TEXTURETYPE_CUBE_ARRAY) { SDL_SetError("GPU texture transfer support: invalid type"); return -1; }
    if (type==SDL_GPU_TEXTURETYPE_3D) return 0; // Separate volume API.
    const auto block=SDL_GPUFormatBlockExtentChecked(format);
    if (block.x==1 && !SDL_GPUTransferColorBytes(format)) return 0;
    // Pinned SDL's Vulkan query can return true for ASTC HDR without enabling
    // VK_EXT_texture_compression_astc_hdr. No public device-extension query is
    // available here. Conservatively reject this path before image creation.
    if (!SDL_GPUTextureTransferBackendAllowed(device,format)) return 0;
    return SDL_GPUTextureSupportsFormat(device,SDL_GPUTextureFormat(format),SDL_GPUTextureType(type),SDL_GPU_TEXTUREUSAGE_SAMPLER) ? 1 : 0;
}
inline uint64_t SDL_CreateGPUTransferTextureWithUsage(SDL_GPUDevice * device,uint32_t width,uint32_t height,uint32_t layers,uint32_t levels,uint32_t format,uint32_t type,uint32_t usage) {
    if (!SDL_GPUTransferDevice(device) || !SDL_GPUTransferIDAvailable()) return 0;
    const auto block=SDL_GPUFormatBlockExtentChecked(format); if (!block.x) return 0;
    const uint32_t blockWidth=block.x, blockHeight=block.y;
    const bool compressed=blockWidth>1;
    const uint32_t bytesPerTexel=compressed ? SDL_GPUTextureFormatTexelBlockSize(SDL_GPUTextureFormat(format)) : SDL_GPUTransferColorBytes(format);
    if (!bytesPerTexel) return 0;
    if (!SDL_GPUTextureTransferBackendAllowed(device,format)) {
        SDL_SetError("GPU texture: ASTC HDR disabled on pinned Vulkan (unverified device extension)"); return 0;
    }
    if ((type!=SDL_GPU_TEXTURETYPE_2D && type!=SDL_GPU_TEXTURETYPE_2D_ARRAY && type!=SDL_GPU_TEXTURETYPE_CUBE && type!=SDL_GPU_TEXTURETYPE_CUBE_ARRAY) ||
        (type==SDL_GPU_TEXTURETYPE_2D && layers!=1) ||
        (type==SDL_GPU_TEXTURETYPE_CUBE && (width!=height || layers!=6)) ||
        (type==SDL_GPU_TEXTURETYPE_CUBE_ARRAY && (width!=height || layers%6)) ||
        (compressed && (width%blockWidth || height%blockHeight))) {
        SDL_SetError("GPU texture: invalid type/layers/cube dimensions or base dimensions not block-aligned"); return 0;
    }
    SDL_GPUTextureFootprint base{};
    if (!SDL_GPUTextureFootprintBlocks(width,height,bytesPerTexel,blockWidth,blockHeight,base)) return 0;
    uint32_t maxLevels=1; for (auto n=std::max(width,height);n>1;n>>=1) ++maxLevels;
    if (!layers || layers>256 || !levels || levels>maxLevels) {
        SDL_SetError("GPU texture: invalid array layers or mip count"); return 0;
    }
    uint64_t total=0;
    for (uint32_t mip=0;mip<levels;++mip) {
        SDL_GPUTextureFootprint f{};
        if (!SDL_GPUTextureFootprintBlocks(SDL_GPUTextureLevelSize(width,mip),SDL_GPUTextureLevelSize(height,mip),bytesPerTexel,blockWidth,blockHeight,f)) return 0;
        total+=uint64_t(f.size)*layers;
    }
    if (total>SDL_GPUDataLimit) { SDL_SetError("GPU texture: complete mip/array footprint exceeds 64 MiB"); return 0; }
    SDL_GPUTextureCreateInfo info{}; info.type=SDL_GPUTextureType(type);
    info.format=SDL_GPUTextureFormat(format); info.usage=usage;
    info.width=width; info.height=height; info.layer_count_or_depth=layers; info.num_levels=levels; info.sample_count=SDL_GPU_SAMPLECOUNT_1;
    if (!SDL_GPUTextureSupportsFormat(device,info.format,info.type,info.usage)) {
        SDL_SetError("GPU texture: color format/type/usage unsupported"); return 0;
    }
    SDL_GPUTransferTexture entry{device,nullptr,width,height,layers,levels,format,bytesPerTexel,blockWidth,blockHeight,usage,std::vector<bool>(layers*levels,true)};
    entry.type=type;
    SDL_GPUTransferBuild build{device}; build.texture=SDL_CreateGPUTexture(device,&info); if (!build.texture) return 0;
    if (!build.staging(base.size,SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD)) return 0;
    auto * mapped=SDL_MapGPUTransferBuffer(device,build.transfer,false); if (!mapped) return 0;
    std::memset(mapped,0,base.size); SDL_UnmapGPUTransferBuffer(device,build.transfer);
    auto * pass=build.begin(); if (!pass) return 0;
    // One private zero-filled staging buffer can initialize every subresource.
    for (uint32_t layer=0;layer<layers;++layer) for (uint32_t mip=0;mip<levels;++mip) {
        const uint32_t w=SDL_GPUTextureLevelSize(width,mip), h=SDL_GPUTextureLevelSize(height,mip);
        SDL_GPUTextureFootprint f{}; SDL_GPUTextureFootprintBlocks(w,h,bytesPerTexel,blockWidth,blockHeight,f);
        SDL_GPUTextureTransferInfo from{}; from.transfer_buffer=build.transfer; from.pixels_per_row=f.pixelsPerRow; from.rows_per_layer=0;
        auto to=SDL_GPUTextureMakeRegion(build.texture,{mip,layer},SDL_GPUTextureNativeRect(device,blockWidth,blockHeight,{0,0,w,h}));
        SDL_UploadToGPUTexture(pass,&from,&to,false);
    }
    SDL_EndGPUCopyPass(pass); if (!build.submit()) return 0;
    entry.texture=build.texture; const auto id=SDL_GPUNextResourceID++;
    SDL_GPUTransferTextures.emplace(id,std::move(entry)); build.texture=nullptr; return id;
}
inline uint64_t SDL_CreateGPUTypedTransferTexture(SDL_GPUDevice * device,uint32_t width,uint32_t height,uint32_t layers,uint32_t levels,uint32_t format,uint32_t type) {
    return SDL_CreateGPUTransferTextureWithUsage(device,width,height,layers,levels,format,type,SDL_GPU_TEXTUREUSAGE_SAMPLER);
}
inline uint64_t SDL_CreateGPUColorTransferTexture(SDL_GPUDevice * device,uint32_t width,uint32_t height,uint32_t layers,uint32_t levels,uint32_t format) {
    if (!SDL_GPUTransferColorBytes(format)) return 0;
    return SDL_CreateGPUTypedTransferTexture(device,width,height,layers,levels,format,layers==1 ? SDL_GPU_TEXTURETYPE_2D : SDL_GPU_TEXTURETYPE_2D_ARRAY);
}
inline uint64_t SDL_CreateGPUTransferTexture(SDL_GPUDevice * device,uint32_t width,uint32_t height,uint32_t layers,uint32_t levels) {
    return SDL_CreateGPUColorTransferTexture(device,width,height,layers,levels,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM);
}
inline bool SDL_ReleaseGPUTransferTexture(SDL_GPUDevice * device,uint64_t id) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,id); if (!entry) return false;
    SDL_ReleaseGPUTexture(device,entry->texture); SDL_GPUTransferTextures.erase(id); return true;
}
inline bool SDL_UploadGPUTextureRegion(SDL_GPUDevice * device,uint64_t id,das::uint2 sub,das::uint4 rect,
        const das::TArray<uint8_t> & bytes,uint32_t pitch,bool cycle) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,id); if (!entry) return false;
    SDL_GPUTextureFootprint f{};
    if (!SDL_GPUTextureSubregion(*entry,sub,rect,f) || !SDL_GPUTextureSourceBytes(bytes,f.rowBytes,f.rows,pitch)) return false;
    const uint32_t index=sub.y*entry->levels+sub.x;
    const bool full=rect.x==0 && rect.y==0 && rect.z==SDL_GPUTextureLevelSize(entry->width,sub.x) && rect.w==SDL_GPUTextureLevelSize(entry->height,sub.x);
    if ((!entry->valid[index] && !full) || (cycle && (!full || entry->levels!=1 || entry->layers!=1)))
        return SDL_SetError("GPU texture: recovery needs full mip/layer; cycling needs full single-subresource texture");
    SDL_GPUTransferBuild build{device}; if (!build.staging(f.size,SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD)) return false;
    auto * mapped=static_cast<uint8_t *>(SDL_MapGPUTransferBuffer(device,build.transfer,false)); if (!mapped) return false;
    std::memset(mapped,0,f.size);
    for (uint32_t y=0;y<f.rows;++y) std::memcpy(mapped+uint64_t(y)*f.rowPitch,bytes.data+uint64_t(y)*pitch,f.rowBytes);
    SDL_UnmapGPUTransferBuffer(device,build.transfer);
    auto * pass=build.begin(); if (!pass) return false;
    SDL_GPUTextureTransferInfo from{}; from.transfer_buffer=build.transfer; from.pixels_per_row=f.pixelsPerRow; from.rows_per_layer=0;
    auto to=SDL_GPUTextureMakeRegion(entry->texture,sub,SDL_GPUTextureNativeRect(device,entry->blockWidth,entry->blockHeight,rect));
    SDL_UploadToGPUTexture(pass,&from,&to,cycle); SDL_EndGPUCopyPass(pass);
    const bool ok=build.submit(); entry->valid[index]=ok; return ok;
}
inline bool SDL_CopyGPUTextureRegion(SDL_GPUDevice * device,uint64_t source,das::uint2 sourceSub,das::uint4 sourceRect,
        uint64_t destination,das::uint2 destSub,das::uint2 destOrigin) {
    auto * src=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,source); if (!src) return false;
    auto * dst=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,destination); if (!dst) return false;
    if (src->format!=dst->format) return SDL_SetError("GPU texture copy: matching formats required");
    if (source==destination) return SDL_SetError("GPU texture copy: distinct textures required");
    SDL_GPUTextureFootprint f{}; const das::uint4 destRect{destOrigin.x,destOrigin.y,sourceRect.z,sourceRect.w};
    if (!SDL_GPUTextureSubregion(*src,sourceSub,sourceRect,f) || !SDL_GPUTextureSubregion(*dst,destSub,destRect,f)) return false;
    const uint32_t srcIndex=sourceSub.y*src->levels+sourceSub.x, dstIndex=destSub.y*dst->levels+destSub.x;
    if (!src->valid[srcIndex] || !dst->valid[dstIndex]) return SDL_SetError("GPU texture copy: subresource needs full successful upload");
    SDL_GPUTransferBuild build{device}; auto * pass=build.begin(); if (!pass) return false;
    SDL_GPUTextureLocation from{}; from.texture=src->texture; from.mip_level=sourceSub.x; from.layer=sourceSub.y; from.x=sourceRect.x; from.y=sourceRect.y;
    SDL_GPUTextureLocation to{}; to.texture=dst->texture; to.mip_level=destSub.x; to.layer=destSub.y; to.x=destOrigin.x; to.y=destOrigin.y;
    const auto nativeRect=SDL_GPUTextureNativeRect(device,src->blockWidth,src->blockHeight,sourceRect);
    SDL_CopyGPUTextureToTexture(pass,&from,&to,nativeRect.z,nativeRect.w,1,false); SDL_EndGPUCopyPass(pass);
    const bool ok=build.submit(); dst->valid[dstIndex]=ok; return ok;
}
inline uint64_t SDL_RequestGPUTextureReadback(SDL_GPUDevice * device,uint64_t id,das::uint2 sub,das::uint4 rect) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,id); if (!entry) return 0;
    SDL_GPUTextureFootprint f{};
    if (!SDL_GPUTransferIDAvailable() || !SDL_GPUTextureSubregion(*entry,sub,rect,f)) return 0;
    if (!entry->valid[sub.y*entry->levels+sub.x]) { SDL_SetError("GPU texture readback: subresource needs full successful upload"); return 0; }
    SDL_GPUTransferBuild build{device}; if (!build.staging(f.size,SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD)) return 0;
    auto * pass=build.begin(); if (!pass) return 0;
    auto source=SDL_GPUTextureMakeRegion(entry->texture,sub,SDL_GPUTextureNativeRect(device,entry->blockWidth,entry->blockHeight,rect));
    SDL_GPUTextureTransferInfo dest{}; dest.transfer_buffer=build.transfer; dest.pixels_per_row=f.pixelsPerRow; dest.rows_per_layer=0;
    SDL_DownloadFromGPUTexture(pass,&source,&dest); SDL_EndGPUCopyPass(pass);
    if (!build.submitFence()) return 0;
    const auto ticket=SDL_GPUNextResourceID++;
    SDL_GPUReadbacks.emplace(ticket,SDL_GPUReadback{device,build.transfer,build.fence,f.rowBytes*f.rows,false,f.rowBytes,f.rowPitch,f.rows});
    build.transfer=nullptr; build.fence=nullptr; return ticket;
}
inline void SDL_ReleaseGPUTransferTexturesForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPUTransferTextures.begin();it!=SDL_GPUTransferTextures.end();) {
        if (it->second.device!=device) { ++it; continue; }
        SDL_ReleaseGPUTexture(device,it->second.texture); it=SDL_GPUTransferTextures.erase(it);
    }
}
inline const bool SDL_GPUTransferTextureCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPUTransferTexturesForDevice);
