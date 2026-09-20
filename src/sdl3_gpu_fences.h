#pragma once
#include "daScript/daScript.h"
#include <SDL3/SDL.h>
#include <cstdint>

// Borrow the pointer array only during SDL's synchronous wait. No registry,
// fence ownership, automatic submission, or exception policy is introduced.
inline bool SDL_WaitForGPUFencesArray(SDL_GPUDevice * device, bool wait_all,
                                     const das::TArray<SDL_GPUFence *> & fences) {
    if (!device) return SDL_SetError("GPU fences: null device");
    if (!fences.size || fences.size > UINT32_MAX || !fences.data)
        return SDL_SetError("GPU fences: nonempty array with uint32 count and storage required");
    auto * handles = reinterpret_cast<SDL_GPUFence * const *>(fences.data);
    for (uint32_t i = 0; i < uint32_t(fences.size); ++i)
        if (!handles[i]) return SDL_SetError("GPU fences: null fence");
    return SDL_WaitForGPUFences(device, wait_all, handles, uint32_t(fences.size));
}
