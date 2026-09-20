#pragma once
#include "sdl3_gpu_transfer.h"

inline bool SDL_GPUFormatValid(uint32_t format) {
    return (format>SDL_GPU_TEXTUREFORMAT_INVALID && format<=SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT) ||
        SDL_SetError("GPU format: unknown or INVALID format");
}
inline uint32_t SDL_GPUFormatBlockSizeChecked(uint32_t format) {
    return SDL_GPUFormatValid(format) ? SDL_GPUTextureFormatTexelBlockSize(SDL_GPUTextureFormat(format)) : 0;
}
inline das::uint2 SDL_GPUFormatBlockExtentChecked(uint32_t format) {
    if (!SDL_GPUFormatValid(format)) return {0,0};
    if ((format>=SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM && format<=SDL_GPU_TEXTUREFORMAT_BC6H_RGB_UFLOAT) ||
        (format>=SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM_SRGB && format<=SDL_GPU_TEXTUREFORMAT_BC7_RGBA_UNORM_SRGB)) return {4,4};
    if (format>=SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM) {
        // The pinned header has the same fourteen footprints in each of three families.
        static_assert(SDL_GPU_TEXTUREFORMAT_ASTC_12x12_UNORM-SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM==13);
        static_assert(SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM_SRGB-SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM==14);
        static_assert(SDL_GPU_TEXTUREFORMAT_ASTC_4x4_FLOAT-SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM==28);
        static_assert(SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT-SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM==41);
        static const das::uint2 extents[]={{4,4},{5,4},{5,5},{6,5},{6,6},{8,5},{8,6},{8,8},{10,5},{10,6},{10,8},{10,10},{12,10},{12,12}};
        return extents[(format-SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM)%14];
    }
    return {1,1};
}
// Bounds prevent SDL's Uint32 rounding/product from overflowing. These are
// descriptor limits, not hardware capability claims; the result is tight bytes.
inline uint32_t SDL_GPUFormatSizeChecked(uint32_t format,uint32_t width,uint32_t height,uint32_t layers) {
    if (!SDL_GPUFormatValid(format)) return 0;
    if (!width || !height || !layers || width>8192 || height>8192 || layers>256) {
        SDL_SetError("GPU format size: dimensions 1..8192, depth/layers 1..256 required"); return 0;
    }
    const auto f=SDL_GPUTextureFormat(format);
    const uint32_t block=SDL_GPUTextureFormatTexelBlockSize(f);
    const uint64_t row=SDL_CalculateGPUTextureFormatSize(f,width,1,1);
    const uint64_t rows=SDL_CalculateGPUTextureFormatSize(f,1,height,1)/block;
    if (row*rows*layers>std::numeric_limits<uint32_t>::max()) {
        SDL_SetError("GPU format size: Uint32 result overflow"); return 0;
    }
    return SDL_CalculateGPUTextureFormatSize(f,width,height,layers);
}
inline int SDL_GPUFormatSupportedChecked(SDL_GPUDevice * device,uint32_t format,uint32_t type,uint32_t usage) {
    if (!SDL_GPUTransferDevice(device) || !SDL_GPUFormatValid(format)) return -1;
    constexpr uint32_t mask=SDL_GPU_TEXTUREUSAGE_SAMPLER|SDL_GPU_TEXTUREUSAGE_COLOR_TARGET|SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET|
        SDL_GPU_TEXTUREUSAGE_GRAPHICS_STORAGE_READ|SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_READ|SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_WRITE|
        SDL_GPU_TEXTUREUSAGE_COMPUTE_STORAGE_SIMULTANEOUS_READ_WRITE;
    if (type>SDL_GPU_TEXTURETYPE_CUBE_ARRAY || !usage || (usage&~mask)) {
        SDL_SetError("GPU format support: invalid texture type or usage bits"); return -1;
    }
    return SDL_GPUTextureSupportsFormat(device,SDL_GPUTextureFormat(format),SDL_GPUTextureType(type),usage) ? 1 : 0;
}
inline int SDL_GPUSampleCountSupportedChecked(SDL_GPUDevice * device,uint32_t format,uint32_t samples) {
    if (!SDL_GPUTransferDevice(device) || !SDL_GPUFormatValid(format)) return -1;
    if (samples>SDL_GPU_SAMPLECOUNT_8) { SDL_SetError("GPU sample count: invalid enum value"); return -1; }
    return SDL_GPUTextureSupportsSampleCount(device,SDL_GPUTextureFormat(format),SDL_GPUSampleCount(samples)) ? 1 : 0;
}
inline uint32_t SDL_GPUTransferColorBytes(uint32_t format) {
    // All uncompressed color entries in the pinned header. No depth or block formats.
    if ((format>=SDL_GPU_TEXTUREFORMAT_A8_UNORM && format<=SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM) ||
        (format>=SDL_GPU_TEXTUREFORMAT_R8_SNORM && format<=SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB))
        return SDL_GPUTextureFormatTexelBlockSize(SDL_GPUTextureFormat(format));
    SDL_SetError("GPU texture transfer: uncompressed color format required"); return 0;
}
