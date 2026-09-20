#pragma once
#include "sdl3_gpu_fences.h"
namespace sdl3_test {
inline bool native_fence_array_bounds(SDL_GPUDevice * device) {
    das::TArray<SDL_GPUFence *> fences{};
    // TArray has an empty user-provided constructor; braces do not zero its base.
    fences.size=0;
    fences.data=nullptr;
    if (SDL_WaitForGPUFencesArray(device,true,fences)) return false;
    fences.size=1; // missing backing storage must be rejected before SDL.
    if (SDL_WaitForGPUFencesArray(device,false,fences)) return false;
    SDL_GPUFence * value=nullptr;
    fences.data=reinterpret_cast<char *>(&value);
    fences.size=uint64_t(UINT32_MAX)+1;
    if (SDL_WaitForGPUFencesArray(device,true,fences)) return false;
    fences.size=1;
    return !SDL_WaitForGPUFencesArray(device,true,fences);
}
}
