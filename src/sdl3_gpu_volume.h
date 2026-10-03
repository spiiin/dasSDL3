#pragma once
#include "sdl3_gpu_texture_transfer.h"

// Volumes have their own checked-ID registry: array layers are not depth slices.
struct SDL_GPUVolume {
    SDL_GPUDevice * device;
    SDL_GPUTexture * texture;
    das::uint3 size;
    uint32_t levels, format, texelBytes;
    std::vector<bool> valid;
};
inline std::unordered_map<uint64_t,SDL_GPUVolume> SDL_GPUVolumes;
struct SDL_GPUVolumeFootprint { uint32_t rowBytes, rowPitch, slicePitch, size, rows; };
inline bool SDL_GPUVolumeFootprintFor(das::uint3 size,uint32_t texelBytes,SDL_GPUVolumeFootprint & out,SDL_GPUDevice * device=nullptr) {
    if (!size.x || !size.y || !size.z || size.x>2048 || size.y>2048 || size.z>2048)
        return SDL_SetError("GPU volume: dimensions must be 1..2048");
    SDL_GPUTextureFootprint row{};
    if (!SDL_GPUTextureFootprintBlocks(size.x,size.y,texelBytes,1,1,row,device)) return false;
    const uint64_t total=uint64_t(row.size)*size.z;
    if (total>SDL_GPUDataLimit) return SDL_SetError("GPU volume: staging footprint exceeds 64 MiB");
    out={row.rowBytes,row.rowPitch,row.size,uint32_t(total),size.y*size.z}; return true;
}
inline das::uint3 SDL_GPUVolumeMipSize(const SDL_GPUVolume & entry,uint32_t mip) {
    return {SDL_GPUTextureLevelSize(entry.size.x,mip),SDL_GPUTextureLevelSize(entry.size.y,mip),SDL_GPUTextureLevelSize(entry.size.z,mip)};
}
inline bool SDL_GPUVolumeRegion(const SDL_GPUVolume & entry,uint32_t mip,das::uint3 origin,das::uint3 size,SDL_GPUVolumeFootprint & out) {
    if (mip>=entry.levels) return SDL_SetError("GPU volume: invalid mip");
    const auto extent=SDL_GPUVolumeMipSize(entry,mip);
    if (origin.x>extent.x || origin.y>extent.y || origin.z>extent.z ||
        size.x>extent.x-origin.x || size.y>extent.y-origin.y || size.z>extent.z-origin.z)
        return SDL_SetError("GPU volume: region out of bounds");
    return SDL_GPUVolumeFootprintFor(size,entry.texelBytes,out,entry.device);
}
inline bool SDL_GPUVolumeFull(const SDL_GPUVolume & entry,uint32_t mip,das::uint3 origin,das::uint3 size) {
    const auto extent=SDL_GPUVolumeMipSize(entry,mip);
    return !origin.x && !origin.y && !origin.z && size.x==extent.x && size.y==extent.y && size.z==extent.z;
}
inline SDL_GPUTextureRegion SDL_GPUVolumeNativeRegion(SDL_GPUTexture * texture,uint32_t mip,das::uint3 origin,das::uint3 size) {
    SDL_GPUTextureRegion region{}; region.texture=texture; region.mip_level=mip;
    region.x=origin.x; region.y=origin.y; region.z=origin.z;
    region.w=size.x; region.h=size.y; region.d=size.z; return region;
}
inline uint64_t SDL_CreateGPUVolume(SDL_GPUDevice * device,das::uint3 size,uint32_t levels,uint32_t format) {
    if (!SDL_GPUTransferDevice(device) || !SDL_GPUTransferIDAvailable()) return 0;
    const auto texelBytes=SDL_GPUTransferColorBytes(format); if (!texelBytes) return 0;
    SDL_GPUVolumeFootprint base{}; if (!SDL_GPUVolumeFootprintFor(size,texelBytes,base,device)) return 0;
    uint32_t maxLevels=1; for (auto n=std::max({size.x,size.y,size.z});n>1;n>>=1) ++maxLevels;
    if (!levels || levels>maxLevels) { SDL_SetError("GPU volume: invalid mip count"); return 0; }
    SDL_GPUVolume entry{device,nullptr,size,levels,format,texelBytes,std::vector<bool>(levels,true)};
    uint64_t total=0;
    for (uint32_t mip=0;mip<levels;++mip) {
        SDL_GPUVolumeFootprint f{}; if (!SDL_GPUVolumeFootprintFor(SDL_GPUVolumeMipSize(entry,mip),texelBytes,f,device)) return 0;
        total+=f.size;
    }
    if (total>SDL_GPUDataLimit) { SDL_SetError("GPU volume: complete mip footprint exceeds 64 MiB"); return 0; }
    SDL_GPUTextureCreateInfo info{}; info.type=SDL_GPU_TEXTURETYPE_3D; info.format=SDL_GPUTextureFormat(format);
    info.usage=SDL_GPU_TEXTUREUSAGE_SAMPLER; info.width=size.x; info.height=size.y;
    info.layer_count_or_depth=size.z; info.num_levels=levels; info.sample_count=SDL_GPU_SAMPLECOUNT_1;
    if (!SDL_GPUTextureSupportsFormat(device,info.format,info.type,info.usage)) { SDL_SetError("GPU volume: format unsupported"); return 0; }
    SDL_GPUTransferBuild build{device}; build.texture=SDL_CreateGPUTexture(device,&info); if (!build.texture) return 0;
    if (!build.staging(base.size,SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD)) return 0;
    auto * mapped=SDL_MapGPUTransferBuffer(device,build.transfer,false); if (!mapped) return 0;
    std::memset(mapped,0,base.size); SDL_UnmapGPUTransferBuffer(device,build.transfer);
    auto * pass=build.begin(); if (!pass) return 0;
    for (uint32_t mip=0;mip<levels;++mip) {
        const auto extent=SDL_GPUVolumeMipSize(entry,mip);
        SDL_GPUVolumeFootprint f{}; SDL_GPUVolumeFootprintFor(extent,texelBytes,f,device);
        SDL_GPUTextureTransferInfo from{}; from.transfer_buffer=build.transfer;
        from.pixels_per_row=f.rowPitch/texelBytes; from.rows_per_layer=extent.y;
        const auto to=SDL_GPUVolumeNativeRegion(build.texture,mip,{0,0,0},extent);
        SDL_UploadToGPUTexture(pass,&from,&to,false);
    }
    SDL_EndGPUCopyPass(pass); if (!build.submit()) return 0;
    entry.texture=build.texture; const auto id=SDL_GPUNextResourceID++;
    SDL_GPUVolumes.emplace(id,std::move(entry)); build.texture=nullptr; return id;
}
inline bool SDL_ReleaseGPUVolume(SDL_GPUDevice * device,uint64_t id) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUVolumes,device,id); if (!entry) return false;
    SDL_ReleaseGPUTexture(device,entry->texture); SDL_GPUVolumes.erase(id); return true;
}
inline bool SDL_GPUVolumeSourceBytes(const das::TArray<uint8_t> & bytes,das::uint3 size,uint32_t rowBytes,uint32_t rowPitch,uint32_t slicePitch) {
    const uint64_t required=uint64_t(size.z-1)*slicePitch+uint64_t(size.y-1)*rowPitch+rowBytes;
    return (bytes.data && bytes.size<=SDL_GPUDataLimit && rowPitch>=rowBytes &&
        uint64_t(slicePitch)>=uint64_t(rowPitch)*size.y && required<=bytes.size) ||
        SDL_SetError("GPU volume: source row/slice pitch or byte array invalid");
}
using SDL_GPUVolumeSubmitFn=bool (*)(SDL_GPUCommandBuffer *);
inline bool SDL_UploadGPUVolumeWithSubmit(SDL_GPUDevice * device,uint64_t id,uint32_t mip,das::uint3 origin,das::uint3 size,
        const das::TArray<uint8_t> & bytes,uint32_t rowPitch,uint32_t slicePitch,bool cycle,SDL_GPUVolumeSubmitFn submit) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUVolumes,device,id); if (!entry) return false;
    SDL_GPUVolumeFootprint f{};
    if (!SDL_GPUVolumeRegion(*entry,mip,origin,size,f) || !SDL_GPUVolumeSourceBytes(bytes,size,f.rowBytes,rowPitch,slicePitch)) return false;
    const bool full=SDL_GPUVolumeFull(*entry,mip,origin,size);
    if ((!entry->valid[mip] && !full) || (cycle && (!full || entry->levels!=1)))
        return SDL_SetError("GPU volume: recovery needs full mip; cycling needs full single-mip volume");
    SDL_GPUTransferBuild build{device}; if (!build.staging(f.size,SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD)) return false;
    auto * mapped=static_cast<uint8_t *>(SDL_MapGPUTransferBuffer(device,build.transfer,false)); if (!mapped) return false;
    std::memset(mapped,0,f.size);
    for (uint32_t z=0;z<size.z;++z) for (uint32_t y=0;y<size.y;++y)
        std::memcpy(mapped+uint64_t(z)*f.slicePitch+uint64_t(y)*f.rowPitch,
            bytes.data+uint64_t(z)*slicePitch+uint64_t(y)*rowPitch,f.rowBytes);
    SDL_UnmapGPUTransferBuffer(device,build.transfer);
    auto * pass=build.begin(); if (!pass) return false;
    SDL_GPUTextureTransferInfo from{}; from.transfer_buffer=build.transfer;
    from.pixels_per_row=f.rowPitch/entry->texelBytes; from.rows_per_layer=size.y;
    const auto to=SDL_GPUVolumeNativeRegion(entry->texture,mip,origin,size);
    SDL_UploadToGPUTexture(pass,&from,&to,cycle); SDL_EndGPUCopyPass(pass);
    auto * consumed=build.command; build.command=nullptr;
    const bool ok=submit(consumed); entry->valid[mip]=ok; return ok;
}
inline bool SDL_UploadGPUVolume(SDL_GPUDevice * device,uint64_t id,uint32_t mip,das::uint3 origin,das::uint3 size,
        const das::TArray<uint8_t> & bytes,uint32_t rowPitch,uint32_t slicePitch,bool cycle) {
    return SDL_UploadGPUVolumeWithSubmit(device,id,mip,origin,size,bytes,rowPitch,slicePitch,cycle,SDL_SubmitGPUCommandBuffer);
}
inline bool SDL_CopyGPUVolumeWithSubmit(SDL_GPUDevice * device,uint64_t source,uint32_t sourceMip,das::uint3 sourceOrigin,
        das::uint3 size,uint64_t destination,uint32_t destMip,das::uint3 destOrigin,SDL_GPUVolumeSubmitFn submit) {
    auto * src=SDL_GPUTransferFind(SDL_GPUVolumes,device,source); if (!src) return false;
    auto * dst=SDL_GPUTransferFind(SDL_GPUVolumes,device,destination); if (!dst) return false;
    if (source==destination || src->format!=dst->format) return SDL_SetError("GPU volume copy: distinct volumes with matching formats required");
    SDL_GPUVolumeFootprint f{};
    if (!SDL_GPUVolumeRegion(*src,sourceMip,sourceOrigin,size,f) || !SDL_GPUVolumeRegion(*dst,destMip,destOrigin,size,f)) return false;
    if (!src->valid[sourceMip] || !dst->valid[destMip]) return SDL_SetError("GPU volume copy: full successful upload required");
    SDL_GPUTransferBuild build{device}; auto * pass=build.begin(); if (!pass) return false;
    SDL_GPUTextureLocation from{}; from.texture=src->texture; from.mip_level=sourceMip;
    from.x=sourceOrigin.x; from.y=sourceOrigin.y; from.z=sourceOrigin.z;
    SDL_GPUTextureLocation to{}; to.texture=dst->texture; to.mip_level=destMip;
    to.x=destOrigin.x; to.y=destOrigin.y; to.z=destOrigin.z;
    SDL_CopyGPUTextureToTexture(pass,&from,&to,size.x,size.y,size.z,false); SDL_EndGPUCopyPass(pass);
    auto * consumed=build.command; build.command=nullptr;
    const bool ok=submit(consumed); dst->valid[destMip]=ok; return ok;
}
inline bool SDL_CopyGPUVolume(SDL_GPUDevice * device,uint64_t source,uint32_t sourceMip,das::uint3 sourceOrigin,
        das::uint3 size,uint64_t destination,uint32_t destMip,das::uint3 destOrigin) {
    return SDL_CopyGPUVolumeWithSubmit(device,source,sourceMip,sourceOrigin,size,destination,destMip,destOrigin,SDL_SubmitGPUCommandBuffer);
}
inline uint64_t SDL_RequestGPUVolumeReadback(SDL_GPUDevice * device,uint64_t id,uint32_t mip,das::uint3 origin,das::uint3 size) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUVolumes,device,id); if (!entry) return 0;
    SDL_GPUVolumeFootprint f{};
    if (!SDL_GPUTransferIDAvailable() || !SDL_GPUVolumeRegion(*entry,mip,origin,size,f)) return 0;
    if (!entry->valid[mip]) { SDL_SetError("GPU volume readback: full successful upload required"); return 0; }
    SDL_GPUTransferBuild build{device}; if (!build.staging(f.size,SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD)) return 0;
    auto * pass=build.begin(); if (!pass) return 0;
    const auto source=SDL_GPUVolumeNativeRegion(entry->texture,mip,origin,size);
    SDL_GPUTextureTransferInfo dest{}; dest.transfer_buffer=build.transfer;
    dest.pixels_per_row=f.rowPitch/entry->texelBytes; dest.rows_per_layer=size.y;
    SDL_DownloadFromGPUTexture(pass,&source,&dest); SDL_EndGPUCopyPass(pass);
    if (!build.submitFence()) return 0;
    const auto ticket=SDL_GPUNextResourceID++;
    SDL_GPUReadbacks.emplace(ticket,SDL_GPUReadback{device,build.transfer,build.fence,f.rowBytes*f.rows,false,f.rowBytes,f.rowPitch,f.rows});
    build.transfer=nullptr; build.fence=nullptr; return ticket;
}
inline void SDL_ReleaseGPUVolumesForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPUVolumes.begin();it!=SDL_GPUVolumes.end();) {
        if (it->second.device!=device) { ++it; continue; }
        SDL_ReleaseGPUTexture(device,it->second.texture); it=SDL_GPUVolumes.erase(it);
    }
}
inline const bool SDL_GPUVolumeCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPUVolumesForDevice);
