#pragma once
#include "sdl3_gpu.h"

inline bool SDL_GPUControlDevice(SDL_GPUDevice * device) {
    return (SDL_IsMainThread() && SDL_ScopedGPUDevices.count(device)) ||
        SDL_SetError("GPU control: live scoped device and main thread required");
}
inline bool SDL_GPUControlWindow(SDL_GPUDevice * device,SDL_Window * window) {
    if (!SDL_GPUControlDevice(device)) return false;
    // Compare addresses before using a caller-supplied window pointer. Window
    // enumeration and control stay on the main thread, so this cannot race destruction.
    int count=0;
    auto ** windows=SDL_GetWindows(&count);
    if (!windows) return false;
    bool live=false;
    for (int i=0;i<count;++i) if (windows[i]==window) { live=true; break; }
    SDL_free(windows);
    if (!live || !SDL_GPUWindowClaimedBy(device,window))
        return SDL_SetError("GPU control: live window claimed by this device required");
    return true;
}
inline bool SDL_GPUPresentValue(uint32_t mode) {
    return mode<=SDL_GPU_PRESENTMODE_MAILBOX || SDL_SetError("GPU present mode: invalid enum value");
}
inline bool SDL_GPUCompositionValue(uint32_t composition) {
    return composition<=SDL_GPU_SWAPCHAINCOMPOSITION_HDR10_ST2084 || SDL_SetError("GPU composition: invalid enum value");
}
// -1 invalid/error, 0 unsupported, 1 supported. Query only after claim.
inline int SDL_GPUWindowPresentSupported(SDL_GPUDevice * device,SDL_Window * window,uint32_t mode) {
    if (!SDL_GPUControlWindow(device,window) || !SDL_GPUPresentValue(mode)) return -1;
    return SDL_WindowSupportsGPUPresentMode(device,window,SDL_GPUPresentMode(mode)) ? 1 : 0;
}
inline int SDL_GPUWindowCompositionSupported(SDL_GPUDevice * device,SDL_Window * window,uint32_t composition) {
    if (!SDL_GPUControlWindow(device,window) || !SDL_GPUCompositionValue(composition)) return -1;
    return SDL_WindowSupportsGPUSwapchainComposition(device,window,SDL_GPUSwapchainComposition(composition)) ? 1 : 0;
}
inline uint32_t SDL_GPUWindowFormatChecked(SDL_GPUDevice * device,SDL_Window * window) {
    if (!SDL_GPUControlWindow(device,window)) return SDL_GPU_TEXTUREFORMAT_INVALID;
    return uint32_t(SDL_GetGPUSwapchainTextureFormat(device,window));
}
inline int SDL_ConfigureGPUSwapchainChecked(SDL_GPUDevice * device,SDL_Window * window,uint32_t composition,uint32_t mode) {
    if (!SDL_GPUControlWindow(device,window) || !SDL_GPUCompositionValue(composition) || !SDL_GPUPresentValue(mode)) return -1;
    if (!SDL_WindowSupportsGPUSwapchainComposition(device,window,SDL_GPUSwapchainComposition(composition)) ||
        !SDL_WindowSupportsGPUPresentMode(device,window,SDL_GPUPresentMode(mode))) return 0;
    return SDL_SetGPUSwapchainParameters(device,window,SDL_GPUSwapchainComposition(composition),SDL_GPUPresentMode(mode)) ? 1 : -1;
}
inline bool SDL_SetGPUFramesInFlightChecked(SDL_GPUDevice * device,uint32_t count) {
    if (!SDL_GPUControlDevice(device)) return false;
    if (count<1 || count>3) return SDL_SetError("GPU frames in flight: count must be 1..3");
    return SDL_SetGPUAllowedFramesInFlight(device,count);
}
inline bool SDL_WaitGPUSwapchainChecked(SDL_GPUDevice * device,SDL_Window * window) {
    return SDL_GPUControlWindow(device,window) && SDL_WaitForGPUSwapchain(device,window);
}
