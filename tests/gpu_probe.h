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
struct GPUFake {
    inline static int scenario = 0;
    inline static std::string trace;
    inline static bool target_ok = false;
    inline static char token;
    template <typename T> static T * handle() { return reinterpret_cast<T *>(&token); }
    static SDL_GPUCommandBuffer * acquire(SDL_GPUDevice *) {
        trace += 'A';
        if (scenario == 1) { SDL_SetError("acquire-failure"); return nullptr; }
        return handle<SDL_GPUCommandBuffer>();
    }
    static bool swapchain(SDL_GPUCommandBuffer *, SDL_Window *, SDL_GPUTexture ** t, uint32_t * w, uint32_t * h) {
        trace += 'W'; *w = 320; *h = 240;
        *t = (scenario == 2 || scenario == 3 || scenario == 7 || scenario == 8) ? nullptr : handle<SDL_GPUTexture>();
        if (scenario == 2 || scenario == 4 || scenario == 8) return SDL_SetError("swap-failure");
        return true;
    }
    static SDL_GPURenderPass * begin(SDL_GPUCommandBuffer *, const SDL_GPUColorTargetInfo & t) {
        trace += 'B';
        target_ok = t.texture == handle<SDL_GPUTexture>() && t.load_op == SDL_GPU_LOADOP_CLEAR &&
            t.store_op == SDL_GPU_STOREOP_STORE && t.clear_color.r == 0.25f && t.clear_color.a == 1.0f &&
            !t.mip_level && !t.layer_or_depth_plane && !t.resolve_texture && !t.resolve_mip_level &&
            !t.resolve_layer && !t.cycle && !t.cycle_resolve_texture;
        if (scenario == 5 || scenario == 9) { SDL_SetError("begin-failure"); return nullptr; }
        return handle<SDL_GPURenderPass>();
    }
    static void end(SDL_GPURenderPass *) { trace += 'E'; }
    static bool submit(SDL_GPUCommandBuffer *) {
        trace += 'S';
        return scenario == 6 || scenario == 9 ? SDL_SetError("submit-failure") : true;
    }
    static bool cancel(SDL_GPUCommandBuffer *) {
        trace += 'C';
        return scenario == 7 || scenario == 8 ? SDL_SetError("cancel-failure") : true;
    }
};
inline bool gpu_state_contracts() {
    const char * expected[] = {"AWBES", "A", "AWC", "AWC", "AWS", "AWBS", "AWBES", "AWC", "AWC", "AWBS"};
    for (int i = 0; i != 10; ++i) {
        GPUFake::scenario = i; GPUFake::trace.clear(); GPUFake::target_ok = false;
        uint32_t w = 99, h = 99;
        const int result = SDL_GPUClearFrame<GPUFake>(GPUFake::handle<SDL_GPUDevice>(), GPUFake::handle<SDL_Window>(), {0.25f,0.5f,0.75f,1}, w, h);
        if (result != (i == 0 ? 1 : i == 3 ? 0 : -1) || GPUFake::trace != expected[i] ||
            w != (i == 0 ? 320u : 0u) || h != (i == 0 ? 240u : 0u) ||
            (GPUFake::trace.find('B') != std::string::npos && !GPUFake::target_ok))
            return SDL_SetError("GPU state test scenario %d: %s", i, GPUFake::trace.c_str());
        const std::string error = SDL_GetError();
        if ((i == 8 && (error.find("swap-failure") == std::string::npos || error.find("cancel-failure") == std::string::npos)) ||
            (i == 9 && (error.find("begin-failure") == std::string::npos || error.find("submit-failure") == std::string::npos)))
            return SDL_SetError("GPU lost original/finalization error in scenario %d", i);
        GPUFake::trace.clear();
        const int recorded = SDL_GPUFrame<GPUFake>(GPUFake::handle<SDL_GPUDevice>(), GPUFake::handle<SDL_Window>(),
            {0.25f,0.5f,0.75f,1}, w, h, [](SDL_GPURenderPass *) { GPUFake::trace += 'R'; });
        std::string recordingTrace = expected[i];
        const auto end = recordingTrace.find('E');
        if (end != std::string::npos) recordingTrace.insert(end, "R");
        if (recorded != result || GPUFake::trace != recordingTrace)
            return SDL_SetError("GPU recording called at wrong state, scenario %d", i);
    }
    for (float value : {-1.0f, 1.1f, std::numeric_limits<float>::infinity(), std::numeric_limits<float>::quiet_NaN()}) {
        GPUFake::trace.clear(); uint32_t w = 1, h = 1;
        if (SDL_GPUClearFrame<GPUFake>(GPUFake::handle<SDL_GPUDevice>(), GPUFake::handle<SDL_Window>(), {value,0,0,1}, w,h) != -1 ||
            !GPUFake::trace.empty() || w || h) return SDL_SetError("GPU invalid color reached backend");
    }
    GPUFake::trace.clear(); uint32_t w = 1, h = 1;
    return SDL_GPUClearFrame<GPUFake>(nullptr, nullptr, {0,0,0,1}, w,h) == -1 && GPUFake::trace.empty() && !w && !h;
}
}
