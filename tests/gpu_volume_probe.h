#pragma once
#include "sdl3_gpu_volume.h"
namespace sdl3_test {
inline bool volume_cancel_submit(SDL_GPUCommandBuffer * command) {
    SDL_CancelGPUCommandBuffer(command);
    return SDL_SetError("volume injected submit failure");
}
inline bool volume_fail_upload(SDL_GPUDevice * device,uint64_t id,const das::TArray<uint8_t> & bytes) {
    const auto * entry=SDL_GPUTransferFind(SDL_GPUVolumes,device,id); if (!entry) return false;
    return SDL_UploadGPUVolumeWithSubmit(device,id,0,{0,0,0},entry->size,bytes,
        entry->size.x*entry->texelBytes,entry->size.x*entry->size.y*entry->texelBytes,false,volume_cancel_submit);
}
inline bool volume_fail_copy(SDL_GPUDevice * device,uint64_t source,uint64_t destination) {
    return SDL_CopyGPUVolumeWithSubmit(device,source,0,{0,0,0},{1,1,1},destination,0,{0,0,0},volume_cancel_submit);
}
inline uint32_t volume_count(SDL_GPUDevice * device) {
    uint32_t count=0; for (const auto & item:SDL_GPUVolumes) if (item.second.device==device) ++count; return count;
}
inline bool volume_exists(uint64_t id) { return SDL_GPUVolumes.count(id)!=0; }
}
