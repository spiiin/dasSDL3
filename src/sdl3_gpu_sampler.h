#pragma once
#include "sdl3_gpu_transfer.h"
#include <cmath>
#include <memory>

struct SDL_GPUOwnedSampler {
    SDL_GPUDevice * device;
    SDL_GPUSampler * sampler;
    SDL_GPUSamplerCreateInfo info;
};
inline std::unordered_map<uint64_t,SDL_GPUOwnedSampler> SDL_GPUOwnedSamplers;

// Conservative cross-backend subset; SDL does not expose sampler device limits.
// Copy fields explicitly so caller padding never reaches the driver.
inline bool SDL_GPUValidateSampler(const SDL_GPUSamplerCreateInfo & in,SDL_GPUSamplerCreateInfo & out) {
    if (uint32_t(in.min_filter)>SDL_GPU_FILTER_LINEAR || uint32_t(in.mag_filter)>SDL_GPU_FILTER_LINEAR ||
        uint32_t(in.mipmap_mode)>SDL_GPU_SAMPLERMIPMAPMODE_LINEAR ||
        uint32_t(in.address_mode_u)>SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE ||
        uint32_t(in.address_mode_v)>SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE ||
        uint32_t(in.address_mode_w)>SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE ||
        uint32_t(in.compare_op)>SDL_GPU_COMPAREOP_ALWAYS || (in.enable_compare && in.compare_op==SDL_GPU_COMPAREOP_INVALID))
        return SDL_SetError("GPU sampler: invalid enum value");
    if (!std::isfinite(in.min_lod) || !std::isfinite(in.max_lod) || !std::isfinite(in.mip_lod_bias) ||
        !std::isfinite(in.max_anisotropy) || in.min_lod<0 || in.max_lod<in.min_lod || in.max_lod>1000 ||
        in.mip_lod_bias < -2 || in.mip_lod_bias > 2)
        return SDL_SetError("GPU sampler: finite LOD 0..1000, min <= max, bias -2..2 required");
    if (in.enable_anisotropy && (in.max_anisotropy<1 || in.max_anisotropy>16 ||
        in.min_filter!=SDL_GPU_FILTER_LINEAR || in.mag_filter!=SDL_GPU_FILTER_LINEAR ||
        in.mipmap_mode!=SDL_GPU_SAMPLERMIPMAPMODE_LINEAR))
        return SDL_SetError("GPU sampler: anisotropy requires linear filters and value 1..16");
    if (in.props) return SDL_SetError("GPU sampler: extension properties not supported by checked API");
    out={};
    out.min_filter=in.min_filter; out.mag_filter=in.mag_filter; out.mipmap_mode=in.mipmap_mode;
    out.address_mode_u=in.address_mode_u; out.address_mode_v=in.address_mode_v; out.address_mode_w=in.address_mode_w;
    out.mip_lod_bias=in.mip_lod_bias; out.min_lod=in.min_lod; out.max_lod=in.max_lod;
    out.enable_anisotropy=in.enable_anisotropy; out.max_anisotropy=in.enable_anisotropy ? in.max_anisotropy : 1.0f;
    out.enable_compare=in.enable_compare; out.compare_op=in.enable_compare ? in.compare_op : SDL_GPU_COMPAREOP_ALWAYS;
    return true;
}
inline uint64_t SDL_CreateGPUCheckedSampler(SDL_GPUDevice * device,const SDL_GPUSamplerCreateInfo & info) {
    if (!SDL_GPUTransferDevice(device) || !SDL_GPUTransferIDAvailable()) return 0;
    SDL_GPUSamplerCreateInfo normalized{}; if (!SDL_GPUValidateSampler(info,normalized)) return 0;
    auto release=[device](SDL_GPUSampler * sampler) { SDL_ReleaseGPUSampler(device,sampler); };
    std::unique_ptr<SDL_GPUSampler,decltype(release)> sampler(SDL_CreateGPUSampler(device,&normalized),release);
    if (!sampler) return 0;
    const auto id=SDL_GPUNextResourceID++;
    SDL_GPUOwnedSamplers.emplace(id,SDL_GPUOwnedSampler{device,sampler.get(),normalized});
    sampler.release(); return id;
}
inline bool SDL_ReleaseGPUCheckedSampler(SDL_GPUDevice * device,uint64_t id) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUOwnedSamplers,device,id); if (!entry) return false;
    SDL_ReleaseGPUSampler(device,entry->sampler); SDL_GPUOwnedSamplers.erase(id); return true;
}
// Owned descriptor copy, never a reference into the registry. Clear output on failure.
inline bool SDL_GetGPUCheckedSamplerInfo(SDL_GPUDevice * device,uint64_t id,SDL_GPUSamplerCreateInfo & out) {
    out={}; auto * entry=SDL_GPUTransferFind(SDL_GPUOwnedSamplers,device,id); if (!entry) return false;
    out=entry->info; return true;
}
inline void SDL_ReleaseGPUCheckedSamplersForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPUOwnedSamplers.begin();it!=SDL_GPUOwnedSamplers.end();) {
        if (it->second.device!=device) { ++it; continue; }
        SDL_ReleaseGPUSampler(device,it->second.sampler); it=SDL_GPUOwnedSamplers.erase(it);
    }
}
inline const bool SDL_GPUCheckedSamplerCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPUCheckedSamplersForDevice);
