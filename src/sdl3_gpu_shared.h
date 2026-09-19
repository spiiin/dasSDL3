#pragma once
#include "sdl3_gpu_instancing.h"
#include <map>

// Each registry owns only its part of the fixed colored-instance ABI.
inline std::unordered_map<uint64_t,SDL_GPULitEntry> SDL_GPUGeometries,SDL_GPUMaterials;
struct SDL_GPUSharedMesh { SDL_GPUDevice * device; uint64_t geometry,material; };
inline std::unordered_map<uint64_t,SDL_GPUSharedMesh> SDL_GPUSharedMeshes;
inline bool SDL_GPUResourceCreateCheck(SDL_GPUDevice * device) {
    if (!SDL_IsMainThread() || !device) return SDL_SetError("GPU resources: main thread and device required");
    return SDL_GPUNextPipeline!=std::numeric_limits<uint64_t>::max() || SDL_SetError("GPU resources: ID space exhausted");
}
inline SDL_GPULitEntry * SDL_FindGPUResource(std::unordered_map<uint64_t,SDL_GPULitEntry> & entries,SDL_GPUDevice * device,uint64_t id) {
    auto it=entries.find(id);
    if (it==entries.end() || it->second.device!=device) {
        SDL_SetError("GPU resources: stale, wrong-kind or foreign-device resource"); return nullptr;
    }
    return &it->second;
}
inline bool SDL_ReleaseGPUResource(std::unordered_map<uint64_t,SDL_GPULitEntry> & entries,SDL_GPUDevice * device,uint64_t id) {
    if (!SDL_IsMainThread()) return SDL_SetError("GPU resources: main thread required");
    auto * entry=SDL_FindGPUResource(entries,device,id); if (!entry) return false;
    SDL_FreeGPULit(*entry); entries.erase(id); return true;
}
inline bool SDL_ReleaseGPUGeometry(SDL_GPUDevice * device,uint64_t id) { return SDL_ReleaseGPUResource(SDL_GPUGeometries,device,id); }
inline bool SDL_ReleaseGPUMaterial(SDL_GPUDevice * device,uint64_t id) { return SDL_ReleaseGPUResource(SDL_GPUMaterials,device,id); }
inline bool SDL_ReleaseGPUSharedMesh(SDL_GPUDevice * device,uint64_t id) {
    if (!SDL_IsMainThread()) return SDL_SetError("GPU shared mesh: main thread required");
    auto it=SDL_GPUSharedMeshes.find(id);
    if (it==SDL_GPUSharedMeshes.end() || it->second.device!=device) return SDL_SetError("GPU shared mesh: stale, wrong-kind or foreign-device ID");
    SDL_GPUSharedMeshes.erase(it); return true;
}
inline void SDL_ReleaseGPUResourcesForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPUSharedMeshes.begin();it!=SDL_GPUSharedMeshes.end();)
        if (it->second.device==device) it=SDL_GPUSharedMeshes.erase(it); else ++it;
    for (auto * entries:{&SDL_GPUMaterials,&SDL_GPUGeometries}) {
        for (auto it=entries->begin();it!=entries->end();) {
            if (it->second.device==device) { SDL_FreeGPULit(it->second); it=entries->erase(it); } else ++it;
        }
    }
}
inline const bool SDL_GPUResourceCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPUResourcesForDevice);

inline uint64_t SDL_CreateGPUGeometry(SDL_GPUDevice * device,const das::TArray<das::float4> & positions,
        const das::TArray<das::float4> & normals,const das::TArray<das::float2> & uv,const das::TArray<uint32_t> & indices) {
    if (!SDL_GPUResourceCreateCheck(device)) return 0;
    std::vector<SDL_GPULitVertex> packed;
    if (!SDL_PackGPULitGeometry(positions,normals,uv,indices,packed)) return 0;
    SDL_GPULitBuild build; auto & m=build.mesh; m.device=device; m.count=indices.size;
    const uint32_t vertexBytes=positions.size*48,indexBytes=indices.size*4;
    SDL_GPUBufferCreateInfo bi{}; bi.usage=SDL_GPU_BUFFERUSAGE_VERTEX; bi.size=vertexBytes;
    m.vertices=SDL_CreateGPUBuffer(device,&bi); if (!m.vertices) return 0;
    bi.usage=SDL_GPU_BUFFERUSAGE_INDEX; bi.size=indexBytes;
    m.indices=SDL_CreateGPUBuffer(device,&bi); if (!m.indices) return 0;
    SDL_GPUTransferBufferCreateInfo ti{}; ti.usage=SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD; ti.size=vertexBytes+indexBytes;
    build.transfer=SDL_CreateGPUTransferBuffer(device,&ti); if (!build.transfer) return 0;
    auto * bytes=static_cast<uint8_t*>(SDL_MapGPUTransferBuffer(device,build.transfer,false)); if (!bytes) return 0;
    std::memcpy(bytes,packed.data(),vertexBytes); std::memcpy(bytes+vertexBytes,indices.data,indexBytes);
    SDL_UnmapGPUTransferBuffer(device,build.transfer);
    build.command=SDL_AcquireGPUCommandBuffer(device); if (!build.command) return 0;
    auto * copy=SDL_BeginGPUCopyPass(build.command); if (!copy) return 0;
    SDL_GPUTransferBufferLocation source{}; source.transfer_buffer=build.transfer;
    SDL_GPUBufferRegion dest{}; dest.buffer=m.vertices; dest.size=vertexBytes; SDL_UploadToGPUBuffer(copy,&source,&dest,false);
    source.offset=vertexBytes; dest.buffer=m.indices; dest.size=indexBytes; SDL_UploadToGPUBuffer(copy,&source,&dest,false);
    SDL_EndGPUCopyPass(copy); auto * command=build.command; build.command=nullptr;
    if (!SDL_SubmitGPUCommandBuffer(command)) return 0;
    const auto id=SDL_GPUNextPipeline++; SDL_GPUGeometries.emplace(id,m); m={}; m.device=device; return id;
}
inline uint64_t SDL_CreateGPUMaterialForFormat(SDL_GPUDevice * device,SDL_GPUTextureFormat colorFormat,
        const das::TArray<uint8_t> & pixels,uint32_t width,uint32_t height,const char * vertex,const char * fragment,uint32_t format) {
    if (!SDL_GPUResourceCreateCheck(device)) return 0;
    if (!SDL_GPUMeshSizes(1,pixels.size,width,height,true)) return 0;
    if (!pixels.data) { SDL_SetError("GPU material: missing pixel storage"); return 0; }
    if ((format!=SDL_GPU_SHADERFORMAT_SPIRV && format!=SDL_GPU_SHADERFORMAT_DXIL) || !(SDL_GetGPUShaderFormats(device)&format)) {
        SDL_SetError("GPU material: unsupported shader format"); return 0;
    }
    SDL_GPULitBuild build; auto & m=build.mesh; m.device=device; m.colorFormat=colorFormat;
    m.depthFormat=SDL_GPU3DDepthFormat(device); if (m.depthFormat==SDL_GPU_TEXTUREFORMAT_INVALID) return 0;
    m.pipeline=SDL_CreateGPULitPipeline(device,colorFormat,m.depthFormat,vertex,fragment,format,true,true); if (!m.pipeline) return 0;
    m.instanceColors=true;
    SDL_GPUTextureCreateInfo texture{}; texture.type=SDL_GPU_TEXTURETYPE_2D; texture.format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    texture.usage=SDL_GPU_TEXTUREUSAGE_SAMPLER; texture.width=width; texture.height=height;
    texture.layer_count_or_depth=texture.num_levels=1; texture.sample_count=SDL_GPU_SAMPLECOUNT_1;
    m.texture=SDL_CreateGPUTexture(device,&texture); if (!m.texture) return 0;
    SDL_GPUSamplerCreateInfo sampler{}; sampler.min_filter=sampler.mag_filter=SDL_GPU_FILTER_NEAREST;
    sampler.mipmap_mode=SDL_GPU_SAMPLERMIPMAPMODE_NEAREST;
    sampler.address_mode_u=sampler.address_mode_v=sampler.address_mode_w=SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
    m.sampler=SDL_CreateGPUSampler(device,&sampler); if (!m.sampler) return 0;
    SDL_GPUTransferBufferCreateInfo ti{}; ti.usage=SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD; ti.size=pixels.size;
    build.transfer=SDL_CreateGPUTransferBuffer(device,&ti); if (!build.transfer) return 0;
    auto * bytes=SDL_MapGPUTransferBuffer(device,build.transfer,false); if (!bytes) return 0;
    std::memcpy(bytes,pixels.data,pixels.size); SDL_UnmapGPUTransferBuffer(device,build.transfer);
    build.command=SDL_AcquireGPUCommandBuffer(device); if (!build.command) return 0;
    auto * copy=SDL_BeginGPUCopyPass(build.command); if (!copy) return 0;
    SDL_GPUTextureTransferInfo source{}; source.transfer_buffer=build.transfer; source.pixels_per_row=width; source.rows_per_layer=height;
    SDL_GPUTextureRegion dest{}; dest.texture=m.texture; dest.w=width; dest.h=height; dest.d=1;
    SDL_UploadToGPUTexture(copy,&source,&dest,false);
    SDL_EndGPUCopyPass(copy); auto * command=build.command; build.command=nullptr;
    if (!SDL_SubmitGPUCommandBuffer(command)) return 0;
    const auto id=SDL_GPUNextPipeline++; SDL_GPUMaterials.emplace(id,m); m={}; m.device=device; return id;
}
inline uint64_t SDL_CreateGPUMaterial(SDL_GPUDevice * device,SDL_Window * window,const das::TArray<uint8_t> & pixels,
        uint32_t width,uint32_t height,const char * vertex,const char * fragment,uint32_t format) {
    if (!SDL_IsMainThread() || !SDL_GPUWindowClaimedBy(device,window)) { SDL_SetError("GPU material: main thread and claimed window required"); return 0; }
    return SDL_CreateGPUMaterialForFormat(device,SDL_GetGPUSwapchainTextureFormat(device,window),pixels,width,height,vertex,fragment,format);
}
inline uint64_t SDL_CreateGPUSharedMesh(SDL_GPUDevice * device,uint64_t geometry,uint64_t material) {
    if (!SDL_GPUResourceCreateCheck(device) || !SDL_FindGPUResource(SDL_GPUGeometries,device,geometry) || !SDL_FindGPUResource(SDL_GPUMaterials,device,material)) return 0;
    const auto id=SDL_GPUNextPipeline++; SDL_GPUSharedMeshes.emplace(id,SDL_GPUSharedMesh{device,geometry,material}); return id;
}
// Borrowed view only: never free it. Re-resolve both parents on every draw.
inline bool SDL_ResolveGPUBatchMesh(SDL_GPUDevice * device,uint64_t id,SDL_GPULitEntry & view,std::pair<uint64_t,uint64_t> & key) {
    auto shared=SDL_GPUSharedMeshes.find(id);
    if (shared!=SDL_GPUSharedMeshes.end()) {
        if (shared->second.device!=device) return SDL_SetError("GPU shared mesh: foreign device");
        auto * geometry=SDL_FindGPUResource(SDL_GPUGeometries,device,shared->second.geometry);
        auto * material=SDL_FindGPUResource(SDL_GPUMaterials,device,shared->second.material);
        if (!geometry || !material) return false;
        view=*material; view.vertices=geometry->vertices; view.indices=geometry->indices; view.count=geometry->count;
        key={shared->second.geometry,shared->second.material}; return true;
    }
    auto * mesh=SDL_FindGPULit(device,id); if (!mesh) return false;
    if (!mesh->instances || !mesh->instanceColors) return SDL_SetError("GPU batches: colored instanced mesh required");
    view=*mesh; key={id,0}; return true;
}
