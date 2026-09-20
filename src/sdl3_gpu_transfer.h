#pragma once
#include "daScript/daScript.h"
#include "sdl3_gpu.h"
#include <type_traits>

// Main-thread, checked IDs. Native recording never calls script. Byte offsets
// and sizes are 4-aligned in this first public transfer contract.
inline constexpr uint32_t SDL_GPUDataLimit = 64u * 1024u * 1024u;
struct SDL_GPUDataBuffer {
    SDL_GPUDevice * device;
    SDL_GPUBuffer * buffer;
    uint32_t size;
    bool valid;
    uint32_t usage=0;
};
struct SDL_GPUReadback {
    SDL_GPUDevice * device;
    SDL_GPUTransferBuffer * transfer;
    SDL_GPUFence * fence;
    uint32_t size;
    bool retired = false;
    uint32_t rowBytes = 0, rowPitch = 0, rows = 0;
};
inline std::unordered_map<uint64_t, SDL_GPUDataBuffer> SDL_GPUDataBuffers;
inline std::unordered_map<uint64_t, SDL_GPUReadback> SDL_GPUReadbacks;
// SDL 3.2.18 Vulkan can return a released, unsignaled fence to its pool.
// Keep retired tickets alive until completion; no blocking wait on scope exit.
inline void SDL_CollectGPUReadbacks(SDL_GPUDevice * device) {
    for (auto it=SDL_GPUReadbacks.begin();it!=SDL_GPUReadbacks.end();) {
        auto & entry=it->second;
        if (entry.device!=device || !entry.retired || !SDL_QueryGPUFence(device,entry.fence)) { ++it; continue; }
        SDL_ReleaseGPUFence(device,entry.fence);
        SDL_ReleaseGPUTransferBuffer(device,entry.transfer);
        it=SDL_GPUReadbacks.erase(it);
    }
}
inline bool SDL_GPUTransferDevice(SDL_GPUDevice * device) {
    if (!SDL_IsMainThread() || !SDL_ScopedGPUDevices.count(device))
        return SDL_SetError("GPU transfer: live scoped device and main thread required");
    SDL_CollectGPUReadbacks(device);
    return true;
}
inline bool SDL_GPUTransferIDAvailable() {
    return SDL_GPUNextResourceID != std::numeric_limits<uint64_t>::max() ||
        SDL_SetError("GPU transfer: ID space exhausted");
}
template <typename T>
inline T * SDL_GPUTransferFind(std::unordered_map<uint64_t,T> & entries, SDL_GPUDevice * device, uint64_t id) {
    if (!SDL_GPUTransferDevice(device)) return nullptr;
    const auto it = entries.find(id);
    if (it == entries.end() || it->second.device != device) {
        SDL_SetError("GPU transfer: stale, wrong-kind or foreign-device ID"); return nullptr;
    }
    if constexpr (std::is_same<T,SDL_GPUReadback>::value) {
        if (it->second.retired) { SDL_SetError("GPU readback: released ticket"); return nullptr; }
    }
    return &it->second;
}
inline bool SDL_GPUTransferRange(uint32_t capacity, uint32_t offset, uint32_t size) {
    return (size && size <= SDL_GPUDataLimit && !(size % 4) && !(offset % 4) &&
        offset <= capacity && size <= capacity-offset) ||
        SDL_SetError("GPU transfer: nonempty 4-aligned range within capacity required");
}
inline bool SDL_GPUTransferBytes(const das::TArray<uint8_t> & bytes) {
    return bytes.data && bytes.size <= SDL_GPUDataLimit &&
        SDL_GPUTransferRange(SDL_GPUDataLimit,0,uint32_t(bytes.size)) ? true :
        SDL_SetError("GPU transfer: missing bytes, invalid size or more than 64 MiB");
}
// Guards also cover partial creation and C++ allocation exceptions. A submitted
// command is cleared before submission, including a failed submit.
struct SDL_GPUTransferBuild {
    SDL_GPUDevice * device;
    SDL_GPUBuffer * buffer = nullptr;
    SDL_GPUTexture * texture = nullptr;
    SDL_GPUTransferBuffer * transfer = nullptr;
    SDL_GPUFence * fence = nullptr;
    SDL_GPUCommandBuffer * command = nullptr;
    ~SDL_GPUTransferBuild() {
        const std::string error = SDL_GetError();
        if (command) SDL_CancelGPUCommandBuffer(command); // No swapchain in this API.
        if (fence) {
            // Only exceptional creation cleanup reaches here after submission.
            SDL_WaitForGPUFences(device,true,&fence,1);
            SDL_ReleaseGPUFence(device,fence);
        }
        if (transfer) SDL_ReleaseGPUTransferBuffer(device,transfer);
        if (buffer) SDL_ReleaseGPUBuffer(device,buffer);
        if (texture) SDL_ReleaseGPUTexture(device,texture);
        SDL_SetError("%s",error.c_str());
    }
    bool staging(uint32_t size, SDL_GPUTransferBufferUsage usage) {
        SDL_GPUTransferBufferCreateInfo info{}; info.size=size; info.usage=usage;
        transfer=SDL_CreateGPUTransferBuffer(device,&info); return transfer!=nullptr;
    }
    SDL_GPUCopyPass * begin() {
        command=SDL_AcquireGPUCommandBuffer(device);
        return command ? SDL_BeginGPUCopyPass(command) : nullptr;
    }
    bool submit() {
        auto * consumed=command; command=nullptr;
        return SDL_SubmitGPUCommandBuffer(consumed);
    }
    bool submitFence() {
        auto * consumed=command; command=nullptr;
        fence=SDL_SubmitGPUCommandBufferAndAcquireFence(consumed); return fence!=nullptr;
    }
};
inline bool SDL_GPUUploadData(SDL_GPUDevice * device, SDL_GPUBuffer * buffer,
        uint32_t offset, const das::TArray<uint8_t> & bytes, bool cycle, bool & submitted) {
    submitted=false;
    SDL_GPUTransferBuild build{device};
    if (!build.staging(bytes.size,SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD)) return false;
    auto * mapped=SDL_MapGPUTransferBuffer(device,build.transfer,false); if (!mapped) return false;
    std::memcpy(mapped,bytes.data,bytes.size); SDL_UnmapGPUTransferBuffer(device,build.transfer);
    auto * pass=build.begin(); if (!pass) return false;
    SDL_GPUTransferBufferLocation src{}; src.transfer_buffer=build.transfer;
    SDL_GPUBufferRegion dst{}; dst.buffer=buffer; dst.offset=offset; dst.size=bytes.size;
    SDL_UploadToGPUBuffer(pass,&src,&dst,cycle); SDL_EndGPUCopyPass(pass);
    submitted=true; return build.submit();
}
inline uint64_t SDL_CreateGPUDataBuffer(SDL_GPUDevice * device, const das::TArray<uint8_t> & bytes, uint32_t usage) {
    if (!SDL_GPUTransferDevice(device) || !SDL_GPUTransferIDAvailable() || !SDL_GPUTransferBytes(bytes)) return 0;
    constexpr uint32_t allowed=SDL_GPU_BUFFERUSAGE_VERTEX|SDL_GPU_BUFFERUSAGE_INDEX|SDL_GPU_BUFFERUSAGE_INDIRECT|
        SDL_GPU_BUFFERUSAGE_GRAPHICS_STORAGE_READ|SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ|SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE;
    if (!usage || (usage & ~allowed) || ((usage & SDL_GPU_BUFFERUSAGE_VERTEX) && (usage & SDL_GPU_BUFFERUSAGE_INDEX))) {
        SDL_SetError("GPU data buffer: invalid usage flags"); return 0;
    }
    SDL_GPUTransferBuild build{device};
    SDL_GPUBufferCreateInfo info{}; info.size=bytes.size; info.usage=usage;
    build.buffer=SDL_CreateGPUBuffer(device,&info); if (!build.buffer) return 0;
    bool submitted=false;
    if (!SDL_GPUUploadData(device,build.buffer,0,bytes,false,submitted)) return 0;
    const auto id=SDL_GPUNextResourceID++;
    SDL_GPUDataBuffers.emplace(id,SDL_GPUDataBuffer{device,build.buffer,uint32_t(bytes.size),true,usage});
    build.buffer=nullptr; return id;
}
inline bool SDL_ReleaseGPUDataBuffer(SDL_GPUDevice * device,uint64_t id) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUDataBuffers,device,id); if (!entry) return false;
    SDL_ReleaseGPUBuffer(device,entry->buffer); SDL_GPUDataBuffers.erase(id); return true;
}
inline bool SDL_UpdateGPUDataBuffer(SDL_GPUDevice * device,uint64_t id,uint32_t offset,
        const das::TArray<uint8_t> & bytes,bool cycle) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUDataBuffers,device,id); if (!entry) return false;
    if (!SDL_GPUTransferBytes(bytes) || !SDL_GPUTransferRange(entry->size,offset,bytes.size)) return false;
    const bool full=offset==0 && bytes.size==entry->size;
    if ((!entry->valid || cycle) && !full) return SDL_SetError("GPU data buffer: full update required for cycling or recovery");
    bool submitted=false;
    const bool ok=SDL_GPUUploadData(device,entry->buffer,offset,bytes,cycle,submitted);
    if (submitted) entry->valid=ok;
    return ok;
}
inline bool SDL_CopyGPUDataBuffer(SDL_GPUDevice * device,uint64_t source,uint32_t sourceOffset,
        uint64_t destination,uint32_t destinationOffset,uint32_t size) {
    auto * src=SDL_GPUTransferFind(SDL_GPUDataBuffers,device,source); if (!src) return false;
    auto * dst=SDL_GPUTransferFind(SDL_GPUDataBuffers,device,destination); if (!dst) return false;
    if (source==destination) return SDL_SetError("GPU copy: source and destination must be different buffers");
    if (!src->valid || !dst->valid) return SDL_SetError("GPU copy: buffer requires a full successful update");
    if (!SDL_GPUTransferRange(src->size,sourceOffset,size) || !SDL_GPUTransferRange(dst->size,destinationOffset,size)) return false;
    SDL_GPUTransferBuild build{device}; auto * pass=build.begin(); if (!pass) return false;
    SDL_GPUBufferLocation from{}; from.buffer=src->buffer; from.offset=sourceOffset;
    SDL_GPUBufferLocation to{}; to.buffer=dst->buffer; to.offset=destinationOffset;
    SDL_CopyGPUBufferToBuffer(pass,&from,&to,size,false); SDL_EndGPUCopyPass(pass);
    dst->valid=build.submit(); return dst->valid;
}
inline uint64_t SDL_RequestGPUBufferReadback(SDL_GPUDevice * device,uint64_t id,uint32_t offset,uint32_t size) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUDataBuffers,device,id); if (!entry) return 0;
    if (!SDL_GPUTransferIDAvailable() || !SDL_GPUTransferRange(entry->size,offset,size)) return 0;
    if (!entry->valid) { SDL_SetError("GPU readback: buffer requires a full successful update"); return 0; }
    SDL_GPUTransferBuild build{device}; if (!build.staging(size,SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD)) return 0;
    auto * pass=build.begin(); if (!pass) return 0;
    SDL_GPUBufferRegion source{}; source.buffer=entry->buffer; source.offset=offset; source.size=size;
    SDL_GPUTransferBufferLocation dest{}; dest.transfer_buffer=build.transfer;
    SDL_DownloadFromGPUBuffer(pass,&source,&dest); SDL_EndGPUCopyPass(pass);
    if (!build.submitFence()) return 0;
    const auto ticket=SDL_GPUNextResourceID++;
    SDL_GPUReadbacks.emplace(ticket,SDL_GPUReadback{device,build.transfer,build.fence,size});
    build.transfer=nullptr; build.fence=nullptr; return ticket;
}
inline int SDL_PollGPUReadback(SDL_GPUDevice * device,uint64_t id) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUReadbacks,device,id); if (!entry) return -1;
    return SDL_QueryGPUFence(device,entry->fence) ? 1 : 0;
}
inline bool SDL_WaitGPUReadback(SDL_GPUDevice * device,uint64_t id) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUReadbacks,device,id); if (!entry) return false;
    return SDL_WaitForGPUFences(device,true,&entry->fence,1);
}
inline bool SDL_ReadGPUReadback(SDL_GPUDevice * device,uint64_t id,das::TArray<uint8_t> & bytes) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUReadbacks,device,id); if (!entry) return false;
    if (bytes.size!=entry->size || !bytes.data) return SDL_SetError("GPU readback: output size must match request");
    if (!SDL_QueryGPUFence(device,entry->fence)) return SDL_SetError("GPU readback: not ready");
    auto * mapped=SDL_MapGPUTransferBuffer(device,entry->transfer,false); if (!mapped) return false;
    if (entry->rows) {
        for (uint32_t row=0;row<entry->rows;++row)
            std::memcpy(bytes.data+uint64_t(row)*entry->rowBytes,
                static_cast<const uint8_t *>(mapped)+uint64_t(row)*entry->rowPitch,entry->rowBytes);
    } else std::memcpy(bytes.data,mapped,entry->size);
    SDL_UnmapGPUTransferBuffer(device,entry->transfer);
    return true;
}
inline bool SDL_ReleaseGPUReadback(SDL_GPUDevice * device,uint64_t id) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUReadbacks,device,id); if (!entry) return false;
    entry->retired=true; SDL_CollectGPUReadbacks(device); return true;
}
inline void SDL_ReleaseGPUTransfersForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPUReadbacks.begin();it!=SDL_GPUReadbacks.end();) {
        if (it->second.device!=device) { ++it; continue; }
        SDL_ReleaseGPUFence(device,it->second.fence); SDL_ReleaseGPUTransferBuffer(device,it->second.transfer);
        it=SDL_GPUReadbacks.erase(it);
    }
    for (auto it=SDL_GPUDataBuffers.begin();it!=SDL_GPUDataBuffers.end();) {
        if (it->second.device!=device) { ++it; continue; }
        SDL_ReleaseGPUBuffer(device,it->second.buffer); it=SDL_GPUDataBuffers.erase(it);
    }
}
inline const bool SDL_GPUTransferCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPUTransfersForDevice);
