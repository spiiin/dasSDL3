#pragma once
#include "sdl3_gpu_lit.h"

// Scene owns only its depth attachment. Mesh IDs are resolved again on every draw.
inline std::unordered_map<uint64_t,SDL_GPU3DEntry> SDL_GPUScenes;
inline void SDL_ReleaseGPUScenesForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPUScenes.begin();it!=SDL_GPUScenes.end();) {
        if (it->second.device==device) { SDL_FreeGPU3D(it->second); it=SDL_GPUScenes.erase(it); }
        else ++it;
    }
}
inline const bool SDL_GPUSceneCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPUScenesForDevice);
inline SDL_GPU3DEntry * SDL_FindGPUScene(SDL_GPUDevice * device,uint64_t id) {
    auto it=SDL_GPUScenes.find(id);
    if (it==SDL_GPUScenes.end() || it->second.device!=device) {
        SDL_SetError("GPU scene: stale, invalid or foreign-device ID"); return nullptr;
    }
    return &it->second;
}
inline uint64_t SDL_CreateGPUSceneForFormat(SDL_GPUDevice * device,SDL_GPUTextureFormat color) {
    if (!SDL_IsMainThread() || !device) { SDL_SetError("GPU scene: main thread and device required"); return 0; }
    if (SDL_GPUNextPipeline==std::numeric_limits<uint64_t>::max()) { SDL_SetError("GPU scene: ID space exhausted"); return 0; }
    SDL_GPU3DEntry scene{}; scene.device=device; scene.colorFormat=color;
    scene.depthFormat=SDL_GPU3DDepthFormat(device); if (scene.depthFormat==SDL_GPU_TEXTUREFORMAT_INVALID) return 0;
    const uint64_t id=SDL_GPUNextPipeline++; SDL_GPUScenes.emplace(id,scene); return id;
}
inline uint64_t SDL_CreateGPULitScene(SDL_GPUDevice * device,SDL_Window * window) {
    if (!SDL_IsMainThread() || !SDL_GPUWindowClaimedBy(device,window)) { SDL_SetError("GPU scene: main thread and claimed window required"); return 0; }
    return SDL_CreateGPUSceneForFormat(device,SDL_GetGPUSwapchainTextureFormat(device,window));
}
inline bool SDL_ReleaseGPULitScene(SDL_GPUDevice * device,uint64_t id) {
    if (!SDL_IsMainThread()) return SDL_SetError("GPU scene: main thread required");
    auto * scene=SDL_FindGPUScene(device,id); if (!scene) return false;
    SDL_FreeGPU3D(*scene); SDL_GPUScenes.erase(id); return true;
}
struct SDL_GPUSceneDraw {
    const SDL_GPULitEntry * mesh=nullptr;
    SDL_GPULitUniforms uniforms{};
    SDL_GPULight light{};
};
inline bool SDL_GPUSceneSizes(uint32_t meshes,uint32_t columns,uint32_t lights) {
    return (meshes<=1024 && columns==meshes*4 && lights==meshes) ||
        SDL_SetError("GPU scene: <=1024 objects, four model columns and one light per object required");
}
inline bool SDL_PrepareGPUScene(const SDL_GPU3DEntry & scene,const das::TArray<uint64_t> & meshes,
        const das::TArray<das::float4> & columns,const das::TArray<das::float4> & lights,
        const SDL_GPU3DMatrix & camera,std::vector<SDL_GPUSceneDraw> & draws) {
    draws.clear();
    if (!SDL_GPUSceneSizes(meshes.size,columns.size,lights.size) || !SDL_GPU3DMatrixValid(camera)) return false;
    if (meshes.size && (!meshes.data || !columns.data || !lights.data)) return SDL_SetError("GPU scene: missing array storage");
    std::vector<SDL_GPUSceneDraw> prepared; prepared.reserve(meshes.size);
    for (uint32_t i=0;i<meshes.size;++i) {
        uint64_t id; std::memcpy(&id,meshes.data+size_t(i)*8,8);
        auto * mesh=SDL_FindGPULit(scene.device,id); if (!mesh) return false;
        if (mesh->instances) return SDL_SetError("GPU scene: instanced mesh requires instanced draw");
        if (mesh->colorFormat!=scene.colorFormat || mesh->depthFormat!=scene.depthFormat)
            return SDL_SetError("GPU scene: incompatible mesh target formats");
        SDL_GPU3DMatrix model,mvp{}; std::memcpy(&model,columns.data+size_t(i)*64,64);
        if (!SDL_GPU3DMatrixValid(model)) return false;
        for (int col=0;col<4;++col) for (int row=0;row<4;++row) {
            double value=0; for (int k=0;k<4;++k) value+=double(camera.c[k][row])*model.c[col][k];
            if (!std::isfinite(value) || std::abs(value)>std::numeric_limits<float>::max()) return SDL_SetError("GPU scene: MVP overflow");
            mvp.c[col][row]=float(value);
        }
        das::float4 light; std::memcpy(&light,lights.data+size_t(i)*16,16);
        SDL_GPUSceneDraw draw{}; draw.mesh=mesh;
        if (!SDL_PrepareGPULit(mvp,model,light,draw.uniforms,draw.light)) return false;
        prepared.push_back(draw);
    }
    draws.swap(prepared); return true;
}
inline void SDL_RecordGPUScene(SDL_GPURenderPass * pass,SDL_GPUCommandBuffer * command,
        const std::vector<SDL_GPUSceneDraw> & draws) {
    for (const auto & draw:draws) SDL_RecordGPULit(pass,command,*draw.mesh,draw.uniforms,draw.light);
}
// API template lets tests prove validation happens before any command acquisition.
template<typename API>
inline int SDL_GPUSceneFrame(SDL_GPUDevice * device,SDL_Window * window,SDL_GPU3DEntry & scene,
        const das::TArray<uint64_t> & meshes,const das::TArray<das::float4> & columns,
        const das::TArray<das::float4> & lights,const SDL_GPU3DMatrix & camera) {
    std::vector<SDL_GPUSceneDraw> draws;
    if (!SDL_PrepareGPUScene(scene,meshes,columns,lights,camera,draws)) return -1;
    uint32_t w=0,h=0;
    return SDL_GPUFrameWithTarget<API>(device,window,{0,0,0,1},w,h,
        [&draws](SDL_GPURenderPass * pass,SDL_GPUCommandBuffer * command) { SDL_RecordGPUScene(pass,command,draws); },
        [&scene](SDL_GPUCommandBuffer * command,const SDL_GPUColorTargetInfo & target,uint32_t width,uint32_t height) {
            return SDL_BeginGPU3DPass(command,target,scene,width,height);
        });
}
inline int SDL_DrawGPULitScene(SDL_GPUDevice * device,SDL_Window * window,uint64_t id,
        const das::TArray<uint64_t> & meshes,const das::TArray<das::float4> & columns,
        const das::TArray<das::float4> & lights,das::float4 a,das::float4 b,das::float4 c,das::float4 d) {
    if (!SDL_IsMainThread()) { SDL_SetError("GPU scene: main thread required"); return -1; }
    auto * scene=SDL_FindGPUScene(device,id); if (!scene) return -1;
    if (!SDL_GPUWindowClaimedBy(device,window)) { SDL_SetError("GPU scene: unclaimed window"); return -1; }
    if (scene->colorFormat!=SDL_GetGPUSwapchainTextureFormat(device,window)) { SDL_SetError("GPU scene: target format mismatch"); return -1; }
    return SDL_GPUSceneFrame<SDL_GPUClearAPI>(device,window,*scene,meshes,columns,lights,SDL_GPU3DColumns(a,b,c,d));
}
