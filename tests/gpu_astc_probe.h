#pragma once
#include "sdl3_gpu_texture_transfer.h"
namespace sdl3_test {
inline bool astc_footprints() {
    // SDL's size API is the independent reference for our rectangular block table.
    for (uint32_t format=SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM;format<=SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT;++format) {
        const auto block=SDL_GPUFormatBlockExtentChecked(format);
        for (uint32_t w:{1u,5u,11u,29u,127u}) for (uint32_t h:{1u,4u,7u,23u,63u}) {
            SDL_GPUTextureFootprint f{};
            if (!SDL_GPUTextureFootprintBlocks(w,h,16,block.x,block.y,f)) return false;
            const auto fmt=SDL_GPUTextureFormat(format);
            const auto row=SDL_CalculateGPUTextureFormatSize(fmt,w,1,1);
            const auto rows=SDL_CalculateGPUTextureFormatSize(fmt,1,h,1)/16;
            if (f.rowBytes!=row || f.rows!=rows || f.rowBytes*f.rows!=SDL_CalculateGPUTextureFormatSize(fmt,w,h,1) ||
                f.rowPitch%256 || f.rowPitch<row || f.size!=f.rowPitch*rows ||
                SDL_CalculateGPUTextureFormatSize(fmt,f.pixelsPerRow,1,1)!=f.rowPitch) return false;
        }
    }
    SDL_GPUTransferTexture texture{};
    texture.width=15; texture.height=12; texture.layers=2; texture.levels=4;
    texture.bytesPerTexel=16; texture.blockWidth=5; texture.blockHeight=4;
    SDL_GPUTextureFootprint f{};
    if (!SDL_GPUTextureSubregion(texture,{0,1},{5,4,10,8},f) || f.rowBytes!=32 || f.rows!=2 || f.size!=512) return false;
    if (!SDL_GPUTextureSubregion(texture,{1,1},{5,4,2,2},f) || f.rowBytes!=16 || f.rows!=1) return false;
    if (!SDL_GPUTextureSubregion(texture,{3,1},{0,0,1,1},f) || f.rowBytes!=16 || f.rows!=1) return false;
    for (das::uint4 rect: {das::uint4{1,4,5,4},{5,5,5,4},{5,4,6,4},{5,4,5,5},{0,0,0,4},{0,0,5,0},{UINT32_MAX,0,5,4},{0,UINT32_MAX,5,4}})
        if (SDL_GPUTextureSubregion(texture,{0,0},rect,f)) return false;
    if (SDL_GPUTextureSubregion(texture,{1,0},{5,4,1,2},f) || SDL_GPUTextureSubregion(texture,{1,0},{5,4,2,1},f) ||
        SDL_GPUTextureSubregion(texture,{4,0},{0,0,1,1},f) || SDL_GPUTextureSubregion(texture,{0,2},{0,0,5,4},f)) return false;
    if (SDL_GPUTextureFootprintBlocks(8193,1,16,5,4,f) || SDL_GPUTextureFootprintBlocks(1,1,16,0,4,f)) return false;
    return true;
}
}
