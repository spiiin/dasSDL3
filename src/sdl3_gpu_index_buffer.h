#pragma once
#include "sdl3_gpu_transfer.h"
#include <cmath>

// Immutable index storage keeps CPU validation consistent with queued GPU data.
struct SDL_GPUCheckedIndexBuffer {
    SDL_GPUDevice * device;
    SDL_GPUBuffer * buffer;
    SDL_GPUIndexElementSize element;
    std::vector<uint32_t> indices;
};
inline std::unordered_map<uint64_t,SDL_GPUCheckedIndexBuffer> SDL_GPUCheckedIndexBuffers;
inline uint64_t SDL_CreateGPUCheckedIndexBuffer(SDL_GPUDevice * device,const das::TArray<uint32_t> & values,
        SDL_GPUIndexElementSize element) {
    if (!SDL_GPUTransferDevice(device) || !SDL_GPUTransferIDAvailable()) return 0;
    if (!values.data || !values.size || values.size>1048576 || uint32_t(element)>SDL_GPU_INDEXELEMENTSIZE_32BIT) {
        SDL_SetError("GPU index buffer: 1..1048576 indices and UINT16/UINT32 format required"); return 0;
    }
    SDL_GPUCheckedIndexBuffer entry{device,nullptr,element,{}};
    const auto * source=reinterpret_cast<const uint32_t *>(values.data);
    const uint32_t limit=element==SDL_GPU_INDEXELEMENTSIZE_16BIT ? 65535u : UINT32_MAX;
    for (uint64_t i=0;i<values.size;++i) if (source[i]>=limit) {
        SDL_SetError("GPU index buffer: index exceeds format range or is a primitive-restart sentinel"); return 0;
    }
    entry.indices.assign(source,source+values.size);
    const uint32_t stride=element==SDL_GPU_INDEXELEMENTSIZE_16BIT ? 2 : 4;
    std::vector<uint8_t> packed((values.size*stride+3)&~uint64_t(3),0);
    for (size_t i=0;i<values.size;++i) {
        const uint32_t value=source[i]; std::memcpy(packed.data()+i*stride,&value,stride);
    }
    SDL_GPUTransferBuild build{device};
    SDL_GPUBufferCreateInfo info{}; info.size=uint32_t(packed.size()); info.usage=SDL_GPU_BUFFERUSAGE_INDEX;
    build.buffer=SDL_CreateGPUBuffer(device,&info); if (!build.buffer) return 0;
    das::TArray<uint8_t> bytes{}; bytes.data=reinterpret_cast<char *>(packed.data()); bytes.size=packed.size();
    bool submitted=false; if (!SDL_GPUUploadData(device,build.buffer,0,bytes,false,submitted)) return 0;
    entry.buffer=build.buffer;
    const auto id=SDL_GPUNextResourceID++;
    SDL_GPUCheckedIndexBuffers.emplace(id,std::move(entry)); build.buffer=nullptr; return id;
}
inline bool SDL_ReleaseGPUCheckedIndexBuffer(SDL_GPUDevice * device,uint64_t id) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUCheckedIndexBuffers,device,id); if (!entry) return false;
    SDL_ReleaseGPUBuffer(device,entry->buffer); SDL_GPUCheckedIndexBuffers.erase(id); return true;
}
inline void SDL_ReleaseGPUCheckedIndicesForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPUCheckedIndexBuffers.begin();it!=SDL_GPUCheckedIndexBuffers.end();)
        if (it->second.device==device) {
            SDL_ReleaseGPUBuffer(device,it->second.buffer); it=SDL_GPUCheckedIndexBuffers.erase(it);
        } else ++it;
}
inline const bool SDL_GPUCheckedIndexCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPUCheckedIndicesForDevice);

// Convenience float32 packing; arbitrary byte layouts still use with_gpu_buffer.
inline uint64_t SDL_CreateGPUFloatVertexBuffer(SDL_GPUDevice * device,const das::TArray<float> & values) {
    if (!values.data || !values.size || values.size>SDL_GPUDataLimit/sizeof(float)) {
        SDL_SetError("GPU vertex buffer: nonempty float32 array up to 64 MiB required"); return 0;
    }
    const auto * source=reinterpret_cast<const float *>(values.data);
    for (uint64_t i=0;i<values.size;++i) if (!std::isfinite(source[i])) {
        SDL_SetError("GPU vertex buffer: finite float32 values required"); return 0;
    }
    das::TArray<uint8_t> bytes{}; bytes.data=values.data; bytes.size=values.size*sizeof(float);
    return SDL_CreateGPUDataBuffer(device,bytes,SDL_GPU_BUFFERUSAGE_VERTEX);
}
