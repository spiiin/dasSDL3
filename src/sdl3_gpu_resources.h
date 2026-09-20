#pragma once
#include <SDL3/SDL.h>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <unordered_map>
#include <limits>
#include <vector>
#include <algorithm>

using SDL_GPUDeviceCleanup = void (*)(SDL_GPUDevice *);
inline std::vector<SDL_GPUDeviceCleanup> SDL_GPUDeviceCleanups;
inline bool SDL_RegisterGPUDeviceCleanup(SDL_GPUDeviceCleanup cleanup) {
    if (std::find(SDL_GPUDeviceCleanups.begin(), SDL_GPUDeviceCleanups.end(), cleanup) == SDL_GPUDeviceCleanups.end())
        SDL_GPUDeviceCleanups.push_back(cleanup);
    return true;
}

// Shared monotonic IDs for checked SDL resource handles, never reused.
inline uint64_t SDL_GPUNextResourceID = 1;
