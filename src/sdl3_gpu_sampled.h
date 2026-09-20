#pragma once
#include "sdl3_gpu_sampler.h"
#include "sdl3_gpu_texture_transfer.h"
#include <array>

inline bool SDL_GPUValidateSampledTextures(SDL_GPUDevice * device,const uint64_t * textures,const uint64_t * samplers,size_t count,
        uint64_t target,SDL_GPUTextureSamplerBinding * bindings) {
    if (count>16 || (count && (!textures || !samplers)))
        return SDL_SetError("GPU bindings: at most 16 texture/sampler pairs required");
    for (size_t i=0;i<count;++i) {
        auto * texture=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,textures[i]);
        auto * sampler=SDL_GPUTransferFind(SDL_GPUOwnedSamplers,device,samplers[i]);
        if (!texture || !sampler) return false;
        if (textures[i]==target || texture->type!=SDL_GPU_TEXTURETYPE_2D || texture->layers!=1 || !(texture->usage&SDL_GPU_TEXTUREUSAGE_SAMPLER) ||
            sampler->info.enable_compare || (texture->format!=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM &&
            texture->format!=SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM))
            return SDL_SetError("GPU bindings: distinct RGBA8/BGRA8 UNORM 2D sampled texture and noncomparison sampler required");
        for (bool valid:texture->valid) if (!valid) return SDL_SetError("GPU bindings: all sampled mip levels must be valid");
        if (bindings) bindings[i]={texture->texture,sampler->sampler};
    }
    return true;
}
