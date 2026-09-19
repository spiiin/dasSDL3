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
    SDL_ReleaseGPUPipelinesForDevice(device);
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

// Small injectable backend: tests exercise the exact production state transitions.
struct SDL_GPUClearAPI {
    static SDL_GPUCommandBuffer * acquire(SDL_GPUDevice * d) { return SDL_AcquireGPUCommandBuffer(d); }
    static bool swapchain(SDL_GPUCommandBuffer * c, SDL_Window * w, SDL_GPUTexture ** t, uint32_t * x, uint32_t * y) {
        return SDL_WaitAndAcquireGPUSwapchainTexture(c, w, t, x, y);
    }
    static SDL_GPURenderPass * begin(SDL_GPUCommandBuffer * c, const SDL_GPUColorTargetInfo & t) {
        return SDL_BeginGPURenderPass(c, &t, 1, nullptr);
    }
    static void end(SDL_GPURenderPass * p) { SDL_EndGPURenderPass(p); }
    static bool submit(SDL_GPUCommandBuffer * c) { return SDL_SubmitGPUCommandBuffer(c); }
    static bool cancel(SDL_GPUCommandBuffer * c) { return SDL_CancelGPUCommandBuffer(c); }
};
template <typename API, typename Record>
inline int SDL_GPUFrame(SDL_GPUDevice * device, SDL_Window * window, const SDL_FColor & color,
                       uint32_t & width, uint32_t & height, Record record) {
    width = height = 0;
    if (!device || !window || !std::isfinite(color.r) || !std::isfinite(color.g) ||
        !std::isfinite(color.b) || !std::isfinite(color.a) || color.r < 0 || color.r > 1 ||
        color.g < 0 || color.g > 1 || color.b < 0 || color.b > 1 || color.a < 0 || color.a > 1) {
        SDL_SetError("GPU clear: null handle or color outside 0..1"); return -1;
    }
    auto * command = API::acquire(device);
    if (!command) return -1;
    SDL_GPUTexture * texture = nullptr;
    uint32_t w = 0, h = 0;
    const bool acquired = API::swapchain(command, window, &texture, &w, &h);
    if (!acquired) {
        const std::string error = SDL_GetError();
        // SDL's common header marks acquisition whenever output texture != null.
        const bool finished = texture ? API::submit(command) : API::cancel(command);
        const std::string finishError = finished ? "" : SDL_GetError();
        SDL_SetError("GPU acquire: %s%s%s", error.c_str(), finished ? "" : "; finalize: ", finishError.c_str());
        return -1;
    }
    if (!texture) return API::cancel(command) ? 0 : -1;
    SDL_GPUColorTargetInfo target{};
    target.texture = texture;
    target.clear_color = color;
    target.load_op = SDL_GPU_LOADOP_CLEAR;
    target.store_op = SDL_GPU_STOREOP_STORE;
    auto * pass = API::begin(command, target);
    if (!pass) {
        const std::string error = SDL_GetError();
        const bool finished = API::submit(command); // cancel is illegal after acquisition.
        const std::string finishError = finished ? "" : SDL_GetError();
        SDL_SetError("GPU begin pass: %s%s%s", error.c_str(), finished ? "" : "; submit: ", finishError.c_str());
        return -1;
    }
    record(pass); // Native, non-throwing commands only; never a script callback.
    API::end(pass);
    // Never retry, cancel or reference the command after a submit, even on failure.
    if (!API::submit(command)) return -1;
    width = w; height = h;
    return 1;
}
template <typename API>
inline int SDL_GPUClearFrame(SDL_GPUDevice * device, SDL_Window * window, const SDL_FColor & color,
                            uint32_t & width, uint32_t & height) {
    return SDL_GPUFrame<API>(device, window, color, width, height, [](SDL_GPURenderPass *) {});
}
inline int SDL_ClearGPUWindow(SDL_GPUDevice * device, SDL_Window * window,
        float r, float g, float b, float a, uint32_t & width, uint32_t & height) {
    width = height = 0;
    if (!SDL_GPUWindowClaimedBy(device, window)) {
        SDL_SetError("GPU clear: mismatched or unclaimed window"); return -1;
    }
    return SDL_GPUClearFrame<SDL_GPUClearAPI>(device, window, {r, g, b, a}, width, height);
}
inline uint64_t SDL_CreateGPUVertexIDPipeline(SDL_GPUDevice * device, SDL_Window * window,
                                            const char * vertex, const char * fragment, uint32_t format) {
    if (!SDL_IsMainThread()) { SDL_SetError("GPU pipeline: main thread required"); return 0; }
    if (!SDL_GPUWindowClaimedBy(device, window)) { SDL_SetError("GPU pipeline: unclaimed window"); return 0; }
    return SDL_CreateGPUVertexIDPipelineForFormat(device, SDL_GetGPUSwapchainTextureFormat(device, window), vertex, fragment, format);
}
inline int SDL_DrawGPUVertexIDTriangle(SDL_GPUDevice * device, SDL_Window * window, uint64_t id,
                                       uint32_t & width, uint32_t & height) {
    width = height = 0;
    if (!SDL_IsMainThread()) { SDL_SetError("GPU draw: main thread required"); return -1; }
    const auto * entry = SDL_FindGPUPipeline(device, id);
    if (!entry) return -1;
    if (!SDL_GPUWindowClaimedBy(device, window)) { SDL_SetError("GPU draw: unclaimed window"); return -1; }
    if (entry->format != SDL_GetGPUSwapchainTextureFormat(device, window)) {
        SDL_SetError("GPU draw: incompatible target format"); return -1;
    }
    auto * pipeline = entry->pipeline;
    return SDL_GPUFrame<SDL_GPUClearAPI>(device, window, {0,0,0,1}, width, height,
        [pipeline](SDL_GPURenderPass * pass) {
            SDL_BindGPUGraphicsPipeline(pass, pipeline);
            SDL_DrawGPUPrimitives(pass, 3, 1, 0, 0);
        });
}
