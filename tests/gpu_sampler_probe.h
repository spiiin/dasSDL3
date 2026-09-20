#pragma once
#include "sdl3_gpu_sampler.h"
#include <thread>
namespace sdl3_test {
inline uint32_t sampler_count(SDL_GPUDevice * device) {
    uint32_t count=0; for (const auto & item:SDL_GPUOwnedSamplers) if (item.second.device==device) ++count; return count;
}
inline bool sampler_exists(uint64_t id) { return SDL_GPUOwnedSamplers.count(id)!=0; }
inline bool sampler_invalid_descriptors(SDL_GPUDevice * device) {
    const auto before=sampler_count(device);
    SDL_GPUSamplerCreateInfo base{}; base.max_lod=1000; base.max_anisotropy=1;
    for (int n=0;n<23;++n) {
        auto info=base;
        switch (n) {
        case 0: info.min_filter=SDL_GPUFilter(-1); break;
        case 1: info.mag_filter=SDL_GPUFilter(2); break;
        case 2: info.mipmap_mode=SDL_GPUSamplerMipmapMode(2); break;
        case 3: info.address_mode_u=SDL_GPUSamplerAddressMode(3); break;
        case 4: info.address_mode_v=SDL_GPUSamplerAddressMode(-1); break;
        case 5: info.address_mode_w=SDL_GPUSamplerAddressMode(99); break;
        case 6: info.compare_op=SDL_GPUCompareOp(99); break;
        case 7: info.enable_compare=true; break; // INVALID compare op.
        case 8: info.min_lod=-1; break;
        case 9: info.min_lod=2; info.max_lod=1; break;
        case 10: info.max_lod=1001; break;
        case 11: info.mip_lod_bias=-2.01f; break;
        case 12: info.mip_lod_bias=2.01f; break;
        case 13: info.min_lod=std::numeric_limits<float>::quiet_NaN(); break;
        case 14: info.max_lod=std::numeric_limits<float>::infinity(); break;
        case 15: info.mip_lod_bias=std::numeric_limits<float>::quiet_NaN(); break;
        case 16: info.max_anisotropy=std::numeric_limits<float>::infinity(); break;
        case 17: info.enable_anisotropy=true; info.max_anisotropy=0; break;
        case 18: info.enable_anisotropy=true; info.max_anisotropy=17; break;
        case 19: info.enable_anisotropy=true; break; // Nonlinear filters.
        case 20: info.props=1; break;
        case 21: info.enable_anisotropy=true; info.min_filter=SDL_GPU_FILTER_LINEAR; info.mag_filter=SDL_GPU_FILTER_LINEAR; break;
        case 22: info.max_anisotropy=std::numeric_limits<float>::quiet_NaN(); break;
        }
        const auto id=SDL_CreateGPUCheckedSampler(device,info);
        if (id) { SDL_ReleaseGPUCheckedSampler(device,id); return false; }
        if (sampler_count(device)!=before) return false;
    }
    SDL_GPUSamplerCreateInfo normalized{};
    base.padding1=255; base.padding2=255; base.max_anisotropy=-9;
    return SDL_GPUValidateSampler(base,normalized) && normalized.padding1==0 && normalized.padding2==0 &&
        normalized.max_anisotropy==1 && normalized.compare_op==SDL_GPU_COMPAREOP_ALWAYS;
}
inline bool sampler_wrong_thread(SDL_GPUDevice * device,uint64_t id) {
    bool rejected=false;
    std::thread worker([&] {
        SDL_GPUSamplerCreateInfo info{};
        rejected=!SDL_CreateGPUCheckedSampler(device,info) && !SDL_GetGPUCheckedSamplerInfo(device,id,info) &&
            !SDL_ReleaseGPUCheckedSampler(device,id);
    });
    worker.join(); return rejected;
}
}
