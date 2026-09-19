#pragma once
#include "sdl3_gpu_shared.h"

struct SDL_GPUBatchScene : SDL_GPU3DEntry {
    SDL_GPUBuffer * instances=nullptr;
    SDL_GPUTransferBuffer * upload=nullptr;
};
inline std::unordered_map<uint64_t,SDL_GPUBatchScene> SDL_GPUBatchScenes;
inline void SDL_FreeGPUBatchScene(SDL_GPUBatchScene & scene) {
    if (scene.upload) SDL_ReleaseGPUTransferBuffer(scene.device,scene.upload);
    if (scene.instances) SDL_ReleaseGPUBuffer(scene.device,scene.instances);
    scene.upload=nullptr; scene.instances=nullptr; SDL_FreeGPU3D(scene);
}
inline void SDL_ReleaseGPUBatchesForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPUBatchScenes.begin();it!=SDL_GPUBatchScenes.end();) {
        if (it->second.device==device) { SDL_FreeGPUBatchScene(it->second); it=SDL_GPUBatchScenes.erase(it); }
        else ++it;
    }
}
inline const bool SDL_GPUBatchCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPUBatchesForDevice);
inline SDL_GPUBatchScene * SDL_FindGPUBatchScene(SDL_GPUDevice * device,uint64_t id) {
    auto it=SDL_GPUBatchScenes.find(id);
    if (it==SDL_GPUBatchScenes.end() || it->second.device!=device) {
        SDL_SetError("GPU batches: stale, invalid or foreign-device scene"); return nullptr;
    }
    return &it->second;
}
inline uint64_t SDL_CreateGPUBatchSceneForFormat(SDL_GPUDevice * device,SDL_GPUTextureFormat color) {
    if (!SDL_IsMainThread() || !device) { SDL_SetError("GPU batches: main thread and device required"); return 0; }
    if (SDL_GPUNextPipeline==std::numeric_limits<uint64_t>::max()) { SDL_SetError("GPU batches: ID space exhausted"); return 0; }
    SDL_GPUBatchScene scene{}; scene.device=device; scene.colorFormat=color;
    scene.depthFormat=SDL_GPU3DDepthFormat(device); if (scene.depthFormat==SDL_GPU_TEXTUREFORMAT_INVALID) return 0;
    const auto id=SDL_GPUNextPipeline++; SDL_GPUBatchScenes.emplace(id,scene); return id;
}
inline uint64_t SDL_CreateGPUBatchScene(SDL_GPUDevice * device,SDL_Window * window) {
    if (!SDL_IsMainThread() || !SDL_GPUWindowClaimedBy(device,window)) { SDL_SetError("GPU batches: main thread and claimed window required"); return 0; }
    return SDL_CreateGPUBatchSceneForFormat(device,SDL_GetGPUSwapchainTextureFormat(device,window));
}
inline bool SDL_ReleaseGPUBatchScene(SDL_GPUDevice * device,uint64_t id) {
    if (!SDL_IsMainThread()) return SDL_SetError("GPU batches: main thread required");
    auto * scene=SDL_FindGPUBatchScene(device,id); if (!scene) return false;
    SDL_FreeGPUBatchScene(*scene); SDL_GPUBatchScenes.erase(id); return true;
}
struct SDL_GPUBatchGroup { SDL_GPULitEntry mesh; uint32_t offset,count; };
struct SDL_GPUBatchPlan { std::vector<SDL_GPUBatchGroup> groups; std::vector<uint8_t> bytes; SDL_GPULight light{}; };
inline bool SDL_PrepareGPUBatches(const SDL_GPUBatchScene & scene,const das::TArray<uint64_t> & meshes,
        const das::TArray<das::float4> & models,const das::TArray<das::float4> & colors,
        const SDL_GPU3DMatrix & camera,das::float4 light,SDL_GPUBatchPlan & result) {
    result={};
    if (meshes.size>4096 || models.size!=meshes.size*4 || colors.size!=meshes.size)
        return SDL_SetError("GPU batches: <=4096 objects, four model columns and one color per object required");
    SDL_GPU3DMatrix identity{}; for (int i=0;i<4;++i) identity.c[i][i]=1;
    SDL_GPULitUniforms unused{}; SDL_GPUBatchPlan plan;
    if (!SDL_PrepareGPULit(camera,identity,light,unused,plan.light)) return false;
    if (!meshes.size) { result=std::move(plan); return true; }
    if (!meshes.data) return SDL_SetError("GPU batches: missing mesh array storage");
    std::vector<uint8_t> source;
    if (!SDL_PackGPUInstances(models,&colors,source)) return false;
    std::map<std::pair<uint64_t,uint64_t>,uint32_t> groups;
    std::vector<std::vector<uint32_t>> objects;
    for (uint32_t i=0;i<meshes.size;++i) {
        uint64_t id; std::memcpy(&id,meshes.data+size_t(i)*8,8);
        SDL_GPULitEntry mesh{}; std::pair<uint64_t,uint64_t> key;
        if (!SDL_ResolveGPUBatchMesh(scene.device,id,mesh,key)) return false;
        if (mesh.colorFormat!=scene.colorFormat || mesh.depthFormat!=scene.depthFormat)
            return SDL_SetError("GPU batches: compatible colored mesh required");
        auto found=groups.find(key);
        if (found==groups.end()) {
            if (groups.size()==64) return SDL_SetError("GPU batches: at most 64 mesh/material groups");
            const auto index=uint32_t(objects.size()); groups.emplace(key,index);
            objects.push_back({i}); plan.groups.push_back({mesh,0,1});
        } else { objects[found->second].push_back(i); ++plan.groups[found->second].count; }
    }
    plan.bytes.reserve(source.size());
    for (size_t g=0;g<objects.size();++g) {
        plan.groups[g].offset=uint32_t(plan.bytes.size());
        for (auto index:objects[g]) plan.bytes.insert(plan.bytes.end(),source.begin()+size_t(index)*128,source.begin()+size_t(index+1)*128);
    }
    result=std::move(plan); return true;
}
#ifdef DASSDL3_TESTING
inline bool SDL_TestGPUBatchFailSubmit=false;
#endif
inline bool SDL_UploadGPUBatches(SDL_GPUBatchScene & scene,const SDL_GPUBatchPlan & plan) {
    if (plan.bytes.empty()) return true;
    if (!scene.instances) {
        SDL_GPUBufferCreateInfo info{}; info.usage=SDL_GPU_BUFFERUSAGE_VERTEX; info.size=4096*128;
        scene.instances=SDL_CreateGPUBuffer(scene.device,&info); if (!scene.instances) return false;
    }
    if (!scene.upload) {
        SDL_GPUTransferBufferCreateInfo info{}; info.usage=SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD; info.size=4096*128;
        scene.upload=SDL_CreateGPUTransferBuffer(scene.device,&info); if (!scene.upload) return false;
    }
    auto * mapped=SDL_MapGPUTransferBuffer(scene.device,scene.upload,true); if (!mapped) return false;
    std::memcpy(mapped,plan.bytes.data(),plan.bytes.size()); SDL_UnmapGPUTransferBuffer(scene.device,scene.upload);
    auto * command=SDL_AcquireGPUCommandBuffer(scene.device); if (!command) return false;
    auto * copy=SDL_BeginGPUCopyPass(command);
    if (!copy) { const std::string error=SDL_GetError(); SDL_CancelGPUCommandBuffer(command); return SDL_SetError("%s",error.c_str()); }
    SDL_GPUTransferBufferLocation source{}; source.transfer_buffer=scene.upload;
    SDL_GPUBufferRegion dest{}; dest.buffer=scene.instances; dest.size=uint32_t(plan.bytes.size());
    SDL_UploadToGPUBuffer(copy,&source,&dest,true); SDL_EndGPUCopyPass(copy);
#ifdef DASSDL3_TESTING
    if (SDL_TestGPUBatchFailSubmit) { SDL_CancelGPUCommandBuffer(command); return SDL_SetError("injected batch upload failure"); }
#endif
    return SDL_SubmitGPUCommandBuffer(command);
}
inline void SDL_RecordGPUBatches(SDL_GPURenderPass * pass,SDL_GPUCommandBuffer * command,
        const SDL_GPUBatchScene & scene,const SDL_GPUBatchPlan & plan,const SDL_GPU3DMatrix & camera) {
    for (const auto & group:plan.groups) {
        auto view=group.mesh; // Borrow material/geometry; this copy owns nothing and is never freed.
        view.instances=scene.instances; view.instanceCount=group.count;
        SDL_RecordGPUInstances(pass,command,view,camera,plan.light,group.offset);
    }
}
template<typename API>
inline int SDL_GPUBatchFrame(SDL_GPUDevice * device,SDL_Window * window,SDL_GPUBatchScene & scene,
        const das::TArray<uint64_t> & meshes,const das::TArray<das::float4> & models,
        const das::TArray<das::float4> & colors,const SDL_GPU3DMatrix & camera,das::float4 light) {
    SDL_GPUBatchPlan plan;
    if (!SDL_PrepareGPUBatches(scene,meshes,models,colors,camera,light,plan) || !SDL_UploadGPUBatches(scene,plan)) return -1;
    uint32_t w=0,h=0;
    return SDL_GPUFrameWithTarget<API>(device,window,{0,0,0,1},w,h,
        [&scene,&plan,&camera](SDL_GPURenderPass * pass,SDL_GPUCommandBuffer * command) { SDL_RecordGPUBatches(pass,command,scene,plan,camera); },
        [&scene](SDL_GPUCommandBuffer * command,const SDL_GPUColorTargetInfo & target,uint32_t width,uint32_t height) {
            return SDL_BeginGPU3DPass(command,target,scene,width,height);
        });
}
inline int SDL_DrawGPUBatches(SDL_GPUDevice * device,SDL_Window * window,uint64_t id,
        const das::TArray<uint64_t> & meshes,const das::TArray<das::float4> & models,const das::TArray<das::float4> & colors,
        das::float4 a,das::float4 b,das::float4 c,das::float4 d,das::float4 light) {
    if (!SDL_IsMainThread()) { SDL_SetError("GPU batches: main thread required"); return -1; }
    auto * scene=SDL_FindGPUBatchScene(device,id); if (!scene) return -1;
    if (!SDL_GPUWindowClaimedBy(device,window)) { SDL_SetError("GPU batches: unclaimed window"); return -1; }
    if (scene->colorFormat!=SDL_GetGPUSwapchainTextureFormat(device,window)) { SDL_SetError("GPU batches: target format mismatch"); return -1; }
    return SDL_GPUBatchFrame<SDL_GPUClearAPI>(device,window,*scene,meshes,models,colors,SDL_GPU3DColumns(a,b,c,d),light);
}
