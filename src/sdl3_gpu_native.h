#pragma once
#include "daScript/daScript.h"
#include <SDL3/SDL.h>
#include <cstdint>

// Managed records are evaluated as addresses. SDL_SetGPUBlendConstants is
// the GPU API's by-value record argument; copy it for the native C ABI.
namespace das {
template <> struct cast_arg<SDL_FColor> {
    static SDL_FColor to(Context & context, SimNode * node) {
        return *reinterpret_cast<const SDL_FColor *>(node->evalPtr(context));
    }
};
}

namespace sdl3_native_gpu {
template <typename T> inline bool array_valid(const das::TArray<T> & values) {
    if (values.size > UINT32_MAX || (values.size && !values.data))
        return SDL_SetError("GPU array: uint32 count and valid storage required");
    return true;
}
template <typename T> inline const T * data(const das::TArray<T> & values) {
    return values.size ? reinterpret_cast<const T *>(values.data) : nullptr;
}
}

#ifdef DASSDL3_TESTING
// Deterministic unavailable-frame injection; production always calls SDL.
inline bool SDL_TestSwapchainUnavailable=false;
#endif
inline bool SDL_AcquireGPUSwapchainTextureRef(SDL_GPUCommandBuffer * commands,
    SDL_Window * window, SDL_GPUTexture * & texture, uint32_t & width, uint32_t & height) {
#ifdef DASSDL3_TESTING
    if(SDL_TestSwapchainUnavailable && commands && window){texture=nullptr;width=height=0;return true;}
#endif
    return SDL_AcquireGPUSwapchainTexture(commands, window, &texture, &width, &height);
}
inline bool SDL_WaitAndAcquireGPUSwapchainTextureRef(SDL_GPUCommandBuffer * commands,
    SDL_Window * window, SDL_GPUTexture * & texture, uint32_t & width, uint32_t & height) {
#ifdef DASSDL3_TESTING
    if(SDL_TestSwapchainUnavailable && commands && window){texture=nullptr;width=height=0;return true;}
#endif
    return SDL_WaitAndAcquireGPUSwapchainTexture(commands, window, &texture, &width, &height);
}
inline SDL_GPURenderPass * SDL_BeginGPURenderPassArray(SDL_GPUCommandBuffer * commands,
    const das::TArray<SDL_GPUColorTargetInfo> & colors, const SDL_GPUDepthStencilTargetInfo * depth) {
    if (!sdl3_native_gpu::array_valid(colors)) return nullptr;
    return SDL_BeginGPURenderPass(commands, sdl3_native_gpu::data(colors), uint32_t(colors.size), depth);
}
inline SDL_GPUComputePass * SDL_BeginGPUComputePassArray(SDL_GPUCommandBuffer * commands,
    const das::TArray<SDL_GPUStorageTextureReadWriteBinding> & textures,
    const das::TArray<SDL_GPUStorageBufferReadWriteBinding> & buffers) {
    if (!sdl3_native_gpu::array_valid(textures) || !sdl3_native_gpu::array_valid(buffers)) return nullptr;
    return SDL_BeginGPUComputePass(commands, sdl3_native_gpu::data(textures), uint32_t(textures.size),
        sdl3_native_gpu::data(buffers), uint32_t(buffers.size));
}

inline bool SDL_BindGPUVertexBuffersArray(SDL_GPURenderPass * gpu_pass, uint32_t first_slot,
    const das::TArray<SDL_GPUBufferBinding> & bindings) {
    if (!sdl3_native_gpu::array_valid(bindings)) return false;
    if (bindings.size > UINT32_MAX - first_slot)
        return SDL_SetError("GPU bindings: slot range overflow");
    if (bindings.size) SDL_BindGPUVertexBuffers(gpu_pass, first_slot,
        sdl3_native_gpu::data(bindings), uint32_t(bindings.size));
    return true;
}

inline bool SDL_BindGPUVertexSamplersArray(SDL_GPURenderPass * gpu_pass, uint32_t first_slot,
    const das::TArray<SDL_GPUTextureSamplerBinding> & bindings) {
    if (!sdl3_native_gpu::array_valid(bindings)) return false;
    if (bindings.size > UINT32_MAX - first_slot)
        return SDL_SetError("GPU bindings: slot range overflow");
    if (bindings.size) SDL_BindGPUVertexSamplers(gpu_pass, first_slot,
        sdl3_native_gpu::data(bindings), uint32_t(bindings.size));
    return true;
}

inline bool SDL_BindGPUVertexStorageTexturesArray(SDL_GPURenderPass * gpu_pass, uint32_t first_slot,
    const das::TArray<SDL_GPUTexture *> & bindings) {
    if (!sdl3_native_gpu::array_valid(bindings)) return false;
    if (bindings.size > UINT32_MAX - first_slot)
        return SDL_SetError("GPU bindings: slot range overflow");
    if (bindings.size) SDL_BindGPUVertexStorageTextures(gpu_pass, first_slot,
        sdl3_native_gpu::data(bindings), uint32_t(bindings.size));
    return true;
}

inline bool SDL_BindGPUVertexStorageBuffersArray(SDL_GPURenderPass * gpu_pass, uint32_t first_slot,
    const das::TArray<SDL_GPUBuffer *> & bindings) {
    if (!sdl3_native_gpu::array_valid(bindings)) return false;
    if (bindings.size > UINT32_MAX - first_slot)
        return SDL_SetError("GPU bindings: slot range overflow");
    if (bindings.size) SDL_BindGPUVertexStorageBuffers(gpu_pass, first_slot,
        sdl3_native_gpu::data(bindings), uint32_t(bindings.size));
    return true;
}

inline bool SDL_BindGPUFragmentSamplersArray(SDL_GPURenderPass * gpu_pass, uint32_t first_slot,
    const das::TArray<SDL_GPUTextureSamplerBinding> & bindings) {
    if (!sdl3_native_gpu::array_valid(bindings)) return false;
    if (bindings.size > UINT32_MAX - first_slot)
        return SDL_SetError("GPU bindings: slot range overflow");
    if (bindings.size) SDL_BindGPUFragmentSamplers(gpu_pass, first_slot,
        sdl3_native_gpu::data(bindings), uint32_t(bindings.size));
    return true;
}

inline bool SDL_BindGPUFragmentStorageTexturesArray(SDL_GPURenderPass * gpu_pass, uint32_t first_slot,
    const das::TArray<SDL_GPUTexture *> & bindings) {
    if (!sdl3_native_gpu::array_valid(bindings)) return false;
    if (bindings.size > UINT32_MAX - first_slot)
        return SDL_SetError("GPU bindings: slot range overflow");
    if (bindings.size) SDL_BindGPUFragmentStorageTextures(gpu_pass, first_slot,
        sdl3_native_gpu::data(bindings), uint32_t(bindings.size));
    return true;
}

inline bool SDL_BindGPUFragmentStorageBuffersArray(SDL_GPURenderPass * gpu_pass, uint32_t first_slot,
    const das::TArray<SDL_GPUBuffer *> & bindings) {
    if (!sdl3_native_gpu::array_valid(bindings)) return false;
    if (bindings.size > UINT32_MAX - first_slot)
        return SDL_SetError("GPU bindings: slot range overflow");
    if (bindings.size) SDL_BindGPUFragmentStorageBuffers(gpu_pass, first_slot,
        sdl3_native_gpu::data(bindings), uint32_t(bindings.size));
    return true;
}

inline bool SDL_BindGPUComputeSamplersArray(SDL_GPUComputePass * gpu_pass, uint32_t first_slot,
    const das::TArray<SDL_GPUTextureSamplerBinding> & bindings) {
    if (!sdl3_native_gpu::array_valid(bindings)) return false;
    if (bindings.size > UINT32_MAX - first_slot)
        return SDL_SetError("GPU bindings: slot range overflow");
    if (bindings.size) SDL_BindGPUComputeSamplers(gpu_pass, first_slot,
        sdl3_native_gpu::data(bindings), uint32_t(bindings.size));
    return true;
}

inline bool SDL_BindGPUComputeStorageTexturesArray(SDL_GPUComputePass * gpu_pass, uint32_t first_slot,
    const das::TArray<SDL_GPUTexture *> & bindings) {
    if (!sdl3_native_gpu::array_valid(bindings)) return false;
    if (bindings.size > UINT32_MAX - first_slot)
        return SDL_SetError("GPU bindings: slot range overflow");
    if (bindings.size) SDL_BindGPUComputeStorageTextures(gpu_pass, first_slot,
        sdl3_native_gpu::data(bindings), uint32_t(bindings.size));
    return true;
}

inline bool SDL_BindGPUComputeStorageBuffersArray(SDL_GPUComputePass * gpu_pass, uint32_t first_slot,
    const das::TArray<SDL_GPUBuffer *> & bindings) {
    if (!sdl3_native_gpu::array_valid(bindings)) return false;
    if (bindings.size > UINT32_MAX - first_slot)
        return SDL_SetError("GPU bindings: slot range overflow");
    if (bindings.size) SDL_BindGPUComputeStorageBuffers(gpu_pass, first_slot,
        sdl3_native_gpu::data(bindings), uint32_t(bindings.size));
    return true;
}

inline bool SDL_PushGPUVertexUniformDataArray(SDL_GPUCommandBuffer * commands, uint32_t slot,
    const das::TArray<uint8_t> & bytes) {
    if (!sdl3_native_gpu::array_valid(bytes)) return false;
    if (bytes.size) SDL_PushGPUVertexUniformData(commands, slot, sdl3_native_gpu::data(bytes), uint32_t(bytes.size));
    return true;
}

inline bool SDL_PushGPUFragmentUniformDataArray(SDL_GPUCommandBuffer * commands, uint32_t slot,
    const das::TArray<uint8_t> & bytes) {
    if (!sdl3_native_gpu::array_valid(bytes)) return false;
    if (bytes.size) SDL_PushGPUFragmentUniformData(commands, slot, sdl3_native_gpu::data(bytes), uint32_t(bytes.size));
    return true;
}

inline bool SDL_PushGPUComputeUniformDataArray(SDL_GPUCommandBuffer * commands, uint32_t slot,
    const das::TArray<uint8_t> & bytes) {
    if (!sdl3_native_gpu::array_valid(bytes)) return false;
    if (bytes.size) SDL_PushGPUComputeUniformData(commands, slot, sdl3_native_gpu::data(bytes), uint32_t(bytes.size));
    return true;
}
