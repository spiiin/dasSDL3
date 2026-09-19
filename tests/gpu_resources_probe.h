#pragma once
#include "gpu_batches_probe.h"
namespace sdl3_test {
inline int gpu_geometries_live() { return int(SDL_GPUGeometries.size()); }
inline int gpu_materials_live() { return int(SDL_GPUMaterials.size()); }
inline int gpu_shared_live() { return int(SDL_GPUSharedMeshes.size()); }
inline uint64_t gpu_material_offscreen(SDL_GPUDevice * device,const das::TArray<uint8_t> & pixels,const char * vs,const char * fs,uint32_t format) {
    return SDL_CreateGPUMaterialForFormat(device,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,pixels,1,1,vs,fs,format);
}
inline bool gpu_resources_shared(SDL_GPUDevice * device,uint64_t geometry,uint64_t first,uint64_t second,uint64_t a,uint64_t b) {
    auto * g=SDL_FindGPUResource(SDL_GPUGeometries,device,geometry);
    auto * ma=SDL_FindGPUResource(SDL_GPUMaterials,device,first); auto * mb=SDL_FindGPUResource(SDL_GPUMaterials,device,second);
    SDL_GPULitEntry va{},vb{}; std::pair<uint64_t,uint64_t> ka,kb;
    if (!g || !ma || !mb || !SDL_ResolveGPUBatchMesh(device,a,va,ka) || !SDL_ResolveGPUBatchMesh(device,b,vb,kb)) return false;
    return va.vertices==g->vertices && vb.vertices==g->vertices && va.indices==g->indices && vb.indices==g->indices &&
        va.texture==ma->texture && vb.texture==mb->texture && va.texture!=vb.texture &&
        !g->texture && !g->pipeline && !ma->vertices && !mb->vertices && !g->instances && !ma->instances && !mb->instances;
}
inline bool gpu_resources_pending_release(SDL_GPUDevice * device,uint64_t sceneId,uint64_t geometry,uint64_t material,uint64_t mesh,
        const das::TArray<uint64_t> & ids,const das::TArray<das::float4> & models,const das::TArray<das::float4> & colors) {
    auto * scene=SDL_FindGPUBatchScene(device,sceneId); if (!scene) return false;
    GPUReadback readback{device};
    if (!gpu_batches_submit(readback,*scene,ids,models,colors)) return false;
    // SDL defers native destruction while submitted commands still reference resources.
    if (!SDL_ReleaseGPUGeometry(device,geometry) || !SDL_ReleaseGPUMaterial(device,material) || !SDL_ReleaseGPUSharedMesh(device,mesh)) return false;
    return gpu_batches_check(readback,ids,models,colors,mesh,0);
}
}
