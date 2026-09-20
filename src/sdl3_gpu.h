#pragma once
#include <SDL3/SDL.h>
#include <cmath>
#include <string>
#include <unordered_set>
#include "sdl3_gpu_resources.h"

inline constexpr const char * SDL_GPUClaimKey = "dassdl3.gpu.scoped_claim";
inline std::unordered_set<SDL_GPUDevice *> SDL_ScopedGPUDevices;
#ifdef DASSDL3_TESTING
inline int SDL_TestGPUDevices = 0;
inline int SDL_TestGPUClaims = 0;
#endif
inline SDL_GPUDevice * SDL_CreateGPUDeviceScoped(uint32_t formats, bool debug, const char * driver) {
    if (!SDL_IsMainThread()) { SDL_SetError("GPU device: main thread required"); return nullptr; }
    auto * device = SDL_CreateGPUDevice(formats, debug, driver && *driver ? driver : nullptr);
    if (device) {
        try { SDL_ScopedGPUDevices.insert(device); }
        catch (...) { SDL_DestroyGPUDevice(device); throw; }
    }
#ifdef DASSDL3_TESTING
    if (device) ++SDL_TestGPUDevices;
#endif
    return device;
}
inline bool SDL_DestroyGPUDeviceScoped(SDL_GPUDevice * device) {
    if (!device) return true;
    if (!SDL_IsMainThread() || !SDL_ScopedGPUDevices.count(device))
        return SDL_SetError("GPU device: not a live scoped device or wrong thread");
    const bool idle = SDL_WaitForGPUIdle(device);
    const std::string error = idle ? "" : SDL_GetError();
    for (auto cleanup : SDL_GPUDeviceCleanups) cleanup(device);
    SDL_DestroyGPUDevice(device);
    SDL_ScopedGPUDevices.erase(device);
#ifdef DASSDL3_TESTING
    --SDL_TestGPUDevices;
#endif
    if (!idle) SDL_SetError("GPU shutdown wait: %s", error.c_str());
    return idle;
}
inline bool SDL_GPUWindowClaimedBy(SDL_GPUDevice * device, SDL_Window * window) {
    return device && window && SDL_GetPointerProperty(SDL_GetWindowProperties(window), SDL_GPUClaimKey, nullptr) == device;
}
inline bool SDL_ClaimGPUWindowScoped(SDL_GPUDevice * device, SDL_Window * window) {
    if (!device || !window) return SDL_SetError("GPU claim: null handle");
    if (SDL_GetRenderer(window)) return SDL_SetError("GPU claim: window already has an SDL renderer");
    const auto properties = SDL_GetWindowProperties(window);
    if (!properties) return false;
    if (SDL_GetPointerProperty(properties, SDL_GPUClaimKey, nullptr))
        return SDL_SetError("GPU claim: window already in a GPU scope");
    if (!SDL_ClaimWindowForGPUDevice(device, window)) return false;
    if (!SDL_SetPointerProperty(properties, SDL_GPUClaimKey, device)) {
        const std::string error = SDL_GetError();
        SDL_ReleaseWindowFromGPUDevice(device, window);
        return SDL_SetError("GPU claim property: %s", error.c_str());
    }
#ifdef DASSDL3_TESTING
    ++SDL_TestGPUClaims;
#endif
    return true;
}
inline bool SDL_ReleaseGPUWindowScoped(SDL_GPUDevice * device, SDL_Window * window) {
    if (!SDL_GPUWindowClaimedBy(device, window)) return SDL_SetError("GPU release: mismatched or unclaimed window");
    const bool idle = SDL_WaitForGPUIdle(device);
    const std::string error = idle ? "" : SDL_GetError();
    SDL_ReleaseWindowFromGPUDevice(device, window);
    const bool cleared = SDL_ClearProperty(SDL_GetWindowProperties(window), SDL_GPUClaimKey);
#ifdef DASSDL3_TESTING
    --SDL_TestGPUClaims;
#endif
    if (!idle) return SDL_SetError("GPU release wait: %s", error.c_str());
    return cleared;
}
