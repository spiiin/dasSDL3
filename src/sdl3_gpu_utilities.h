#pragma once
#include "sdl3_gpu_texture_transfer.h"

inline int SDL_GPUDriverCountChecked() {
    if (!SDL_IsMainThread()) { SDL_SetError("GPU discovery: main thread required"); return -1; }
    return SDL_GetNumGPUDrivers();
}
// Copy the static SDL name into the script heap; no borrowed C string escapes.
inline char * SDL_GPUDriverNameCopy(int index,das::Context * context,das::LineInfoArg * at) {
    const int count=SDL_GPUDriverCountChecked();
    if (index<0 || index>=count) { SDL_SetError("GPU discovery: invalid driver index"); return nullptr; }
    const char * name=SDL_GetGPUDriver(index);
    return name ? context->allocateString(name,uint32_t(SDL_strlen(name)),at) : nullptr;
}
inline int SDL_GPUShaderSupportChecked(uint32_t formats,const char * driver) {
    constexpr uint32_t mask=SDL_GPU_SHADERFORMAT_PRIVATE|SDL_GPU_SHADERFORMAT_SPIRV|SDL_GPU_SHADERFORMAT_DXBC|
        SDL_GPU_SHADERFORMAT_DXIL|SDL_GPU_SHADERFORMAT_MSL|SDL_GPU_SHADERFORMAT_METALLIB;
    if (!SDL_IsMainThread() || !formats || (formats&~mask)) {
        SDL_SetError("GPU discovery: main thread and known nonempty shader format flags required"); return -1;
    }
    return SDL_GPUSupportsShaderFormats(formats,driver && *driver ? driver : nullptr) ? 1 : 0;
}
inline bool SDL_GPUResourceNameValid(const char * name) {
    return (!name || SDL_strlen(name)<=4096) || SDL_SetError("GPU resource name: maximum 4096 bytes");
}
inline bool SDL_SetGPUDataBufferNameChecked(SDL_GPUDevice * device,uint64_t id,const char * name) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUDataBuffers,device,id);
    if (!entry || !SDL_GPUResourceNameValid(name)) return false;
    SDL_SetGPUBufferName(device,entry->buffer,name ? name : ""); return true;
}
inline bool SDL_SetGPUTransferTextureNameChecked(SDL_GPUDevice * device,uint64_t id,const char * name) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,id);
    if (!entry || !SDL_GPUResourceNameValid(name)) return false;
    SDL_SetGPUTextureName(device,entry->texture,name ? name : ""); return true;
}
