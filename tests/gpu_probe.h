#pragma once
#include "sdl3_gpu.h"
#include <limits>
namespace sdl3_test {
inline int gpu_devices() { return SDL_TestGPUDevices; }
inline int gpu_claims() { return SDL_TestGPUClaims; }
inline bool gpu_resize(SDL_Window * window) {
    return SDL_SetWindowSize(window, 240, 180) && SDL_SyncWindow(window);
}
// 1 = observed state; 0 = window manager declined; -1 = SDL error.
inline int gpu_minimized(SDL_Window * window, bool minimized) {
    if (!(minimized ? SDL_MinimizeWindow(window) : SDL_RestoreWindow(window))) return -1;
    if (!SDL_SyncWindow(window)) return -1;
    for (int i = 0; i != 100; ++i) {
        SDL_PumpEvents();
        if (bool(SDL_GetWindowFlags(window) & SDL_WINDOW_MINIMIZED) == minimized) return 1;
        SDL_Delay(10);
    }
    return 0;
}
}
