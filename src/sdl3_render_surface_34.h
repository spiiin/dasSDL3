#pragma once
#include "daScript/daScript.h"
#include <SDL3/SDL.h>
#include <climits>
inline bool SDL_GetDefaultTextureScaleModeRef(SDL_Renderer* renderer, SDL_ScaleMode& mode) { return SDL_GetDefaultTextureScaleMode(renderer,&mode); }
inline bool SDL_GetRenderTextureAddressModeRef(SDL_Renderer* renderer, SDL_TextureAddressMode& u, SDL_TextureAddressMode& v) { return SDL_GetRenderTextureAddressMode(renderer,&u,&v); }
inline bool SDL_RenderTexture9GridTiledRefs(SDL_Renderer* renderer, SDL_Texture* texture, const SDL_FRect& src,
    float left, float right, float top, float bottom, float scale, const SDL_FRect& dst, float tile_scale) {
    return SDL_RenderTexture9GridTiled(renderer,texture,&src,left,right,top,bottom,scale,&dst,tile_scale);
}
// SDL copies the descriptor arrays; pointed-to GPU resources remain borrowed.
inline SDL_GPURenderState* SDL_CreateGPURenderStateArrays(SDL_Renderer* renderer, SDL_GPUShader* shader,
    const das::TArray<SDL_GPUTextureSamplerBinding>& samplers, const das::TArray<SDL_GPUTexture*>& textures,
    const das::TArray<SDL_GPUBuffer*>& buffers, uint32_t props) {
    if(samplers.size>INT_MAX || textures.size>INT_MAX || buffers.size>INT_MAX) { SDL_SetError("GPU render state array exceeds Sint32"); return nullptr; }
    SDL_GPURenderStateCreateInfo info{};
    info.fragment_shader=shader; info.num_sampler_bindings=int(samplers.size); info.sampler_bindings=reinterpret_cast<const SDL_GPUTextureSamplerBinding*>(samplers.data);
    info.num_storage_textures=int(textures.size); info.storage_textures=reinterpret_cast<SDL_GPUTexture* const*>(textures.data);
    info.num_storage_buffers=int(buffers.size); info.storage_buffers=reinterpret_cast<SDL_GPUBuffer* const*>(buffers.data); info.props=props;
    return SDL_CreateGPURenderState(renderer,&info);
}
inline bool SDL_SetGPURenderStateFragmentUniformBytes(SDL_GPURenderState* state, uint32_t slot, const das::TArray<uint8_t>& data) {
    if(!data.size) return SDL_SetError("Uniform data must not be empty");
    return SDL_SetGPURenderStateFragmentUniforms(state,slot,data.data,data.size);
}
inline bool SDL_SetGPURenderStateFragmentUniformFloats(SDL_GPURenderState* state, uint32_t slot, const das::TArray<float>& data) {
    if(!data.size || data.size>UINT32_MAX/sizeof(float)) return SDL_SetError("Invalid uniform byte count");
    return SDL_SetGPURenderStateFragmentUniforms(state,slot,data.data,uint32_t(data.size*sizeof(float)));
}
