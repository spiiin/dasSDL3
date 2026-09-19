#pragma once
#include "gpu_batches_probe.h"
namespace sdl3_test {
inline bool gpu_culling_compare(SDL_GPUDevice * device,uint64_t id,
        const das::TArray<uint64_t> & allIds,const das::TArray<das::float4> & allModels,const das::TArray<das::float4> & allColors,
        const das::TArray<uint64_t> & visibleIds,const das::TArray<das::float4> & visibleModels,const das::TArray<das::float4> & visibleColors,
        das::float4 a,das::float4 b,das::float4 c,das::float4 d,bool expectPixels) {
    auto * scene=SDL_FindGPUBatchScene(device,id);
    if (!scene || scene->colorFormat!=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) return false;
    auto camera=SDL_GPU3DColumns(a,b,c,d); GPUReadback full{device},culled{device};
    if (!gpu_batches_submit(full,*scene,allIds,allModels,allColors,&camera) ||
        !gpu_batches_submit(culled,*scene,visibleIds,visibleModels,visibleColors,&camera)) return false;
    SDL_GPUFence * fences[2]={full.fence,culled.fence};
    if (!SDL_WaitForGPUFences(device,true,fences,2)) return false;
    std::array<uint8_t,64*64*4> reference{};
    auto * source=SDL_MapGPUTransferBuffer(device,full.transfer,false); if (!source) return false;
    std::memcpy(reference.data(),source,reference.size()); SDL_UnmapGPUTransferBuffer(device,full.transfer);
    source=SDL_MapGPUTransferBuffer(device,culled.transfer,false); if (!source) return false;
    const bool equal=std::memcmp(reference.data(),source,reference.size())==0;
    SDL_UnmapGPUTransferBuffer(device,culled.transfer);
    bool any=false;
    for (size_t i=0;i<reference.size();i+=4) any|=reference[i]!=0 || reference[i+1]!=0 || reference[i+2]!=0;
    if (!expectPixels) for (size_t i=3;i<reference.size();i+=4) if (reference[i]!=255) return false;
    if (!equal || any!=expectPixels) SDL_SetError("culling readback mismatch or unexpected empty frame");
    return equal && any==expectPixels;
}
}
