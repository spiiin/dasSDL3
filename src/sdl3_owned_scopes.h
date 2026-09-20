#pragma once
#include "sdl3_scopes.h"
#include "sdl3_audio.h"
#include "sdl3_gpu_commands.h"
#include "sdl3_gpu_batches.h"

// Script owns the lexical scope; this layer owns invocation + cleanup together.
// Existing invoke-only exports remain available for compatibility.
inline void SDL_ScopeWindow(SDL_Window * resource,const das::TBlock<void,SDL_Window * const> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<SDL_Window *>::from(resource)};
    SDL_InvokeWithCleanup(block,args,[&] { SDL_DestroyWindow(resource); return true; },context,at);
}
inline void SDL_ScopeRenderer(SDL_Renderer * resource,const das::TBlock<void,SDL_Renderer * const> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<SDL_Renderer *>::from(resource)};
    SDL_InvokeWithCleanup(block,args,[&] { SDL_DestroyRenderer(resource); return true; },context,at);
}
inline void SDL_ScopeSurface(SDL_Surface * resource,const das::TBlock<void,SDL_Surface * const> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<SDL_Surface *>::from(resource)};
    SDL_InvokeWithCleanup(block,args,[&] { SDL_DestroySurface(resource); return true; },context,at);
}
inline void SDL_ScopeTexture(SDL_Texture * resource,const das::TBlock<void,SDL_Texture * const> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<SDL_Texture *>::from(resource)};
    SDL_InvokeWithCleanup(block,args,[&] { SDL_DestroyTexture(resource); return true; },context,at);
}
inline void SDL_ScopeWav(SDL_Wav * resource,const das::TBlock<void,SDL_Wav * const> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<SDL_Wav *>::from(resource)};
    SDL_InvokeWithCleanup(block,args,[&] { SDL_DestroyWav(resource); return true; },context,at);
}
inline void SDL_ScopeAudioStream(SDL_AudioStream * resource,const das::TBlock<void,SDL_AudioStream * const> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<SDL_AudioStream *>::from(resource)};
    SDL_InvokeWithCleanup(block,args,[&] { SDL_DestroyAudioStream(resource); return true; },context,at);
}
inline void SDL_ScopeReleaseGPU3DMesh(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPU3DMesh(device,id); },context,at);
}
inline void SDL_ScopeReleaseGPUBatchScene(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPUBatchScene(device,id); },context,at);
}
inline void SDL_ScopeReleaseGPUCommandPlan(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPUCommandPlan(device,id); },context,at);
}
inline void SDL_ScopeReleaseGPUDataBuffer(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPUDataBuffer(device,id); },context,at);
}
inline void SDL_ScopeReleaseGPUGeometry(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPUGeometry(device,id); },context,at);
}
inline void SDL_ScopeReleaseGPULitMesh(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPULitMesh(device,id); },context,at);
}
inline void SDL_ScopeReleaseGPULitScene(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPULitScene(device,id); },context,at);
}
inline void SDL_ScopeReleaseGPUMaterial(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPUMaterial(device,id); },context,at);
}
inline void SDL_ScopeReleaseGPUReadback(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPUReadback(device,id); },context,at);
}
inline void SDL_ScopeReleaseGPUSharedMesh(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPUSharedMesh(device,id); },context,at);
}
inline void SDL_ScopeReleaseGPUTexturedMesh(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPUTexturedMesh(device,id); },context,at);
}
inline void SDL_ScopeReleaseGPUTransferTexture(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPUTransferTexture(device,id); },context,at);
}
inline void SDL_ScopeReleaseGPUVertexIDPipeline(SDL_GPUDevice * device,uint64_t id,const das::TBlock<void,uint64_t> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<uint64_t>::from(id)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_ReleaseGPUVertexIDPipeline(device,id); },context,at);
}
inline void SDL_ScopeSDL(const das::TBlock<void> & block,das::Context * context,das::LineInfoArg * at) {
    SDL_InvokeWithCleanup(block,nullptr,[] { SDL_Quit(); return true; },context,at);
}
inline void SDL_ScopeGPUDevice(SDL_GPUDevice * device,const das::TBlock<void,SDL_GPUDevice * const> & block,
        das::Context * context,das::LineInfoArg * at) {
    vec4f args[]={das::cast<SDL_GPUDevice *>::from(device)};
    SDL_InvokeWithCleanup(block,args,[&] { return SDL_DestroyGPUDeviceScoped(device); },context,at);
}
inline void SDL_ScopeGPUWindow(SDL_GPUDevice * device,SDL_Window * window,const das::TBlock<void> & block,
        das::Context * context,das::LineInfoArg * at) {
    SDL_InvokeWithCleanup(block,nullptr,[&] { return SDL_ReleaseGPUWindowScoped(device,window); },context,at);
}
inline void SDL_ScopeRenderTarget(SDL_Renderer * renderer,SDL_Texture * previous,const das::TBlock<void> & block,
        das::Context * context,das::LineInfoArg * at) {
    SDL_InvokeWithCleanup(block,nullptr,[&] { return SDL_SetRenderTarget(renderer,previous); },context,at);
}
inline void SDL_ScopeTextInput(SDL_Window * window,bool owned,const das::TBlock<void> & block,
        das::Context * context,das::LineInfoArg * at) {
    SDL_InvokeWithCleanup(block,nullptr,[&] { return !owned || SDL_StopTextInput(window); },context,at);
}
inline SDL_Texture * SDL_LoadBMPTextureOwned(SDL_Renderer * renderer,const char * path) {
    if (!renderer) { SDL_SetError("load_texture: null renderer"); return nullptr; }
    auto * surface=SDL_LoadBMP(path); if (!surface) return nullptr;
    auto * texture=SDL_CreateTextureFromSurface(renderer,surface);
    // Destruction must not replace a creation failure's SDL error.
    if (!texture) {
        const std::string error=SDL_GetError();
        SDL_DestroySurface(surface); SDL_SetError("%s",error.c_str());
    } else SDL_DestroySurface(surface);
    return texture;
}
