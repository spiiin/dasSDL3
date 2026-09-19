#pragma once
#include "sdl3_gpu_batches.h"
#include "gpu_instancing_probe.h"
namespace sdl3_test {
inline int gpu_batches_live() { return int(SDL_GPUBatchScenes.size()); }
inline uint64_t gpu_batches_offscreen(SDL_GPUDevice * device) { return SDL_CreateGPUBatchSceneForFormat(device,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM); }
inline SDL_GPU3DMatrix gpu_batches_camera() { SDL_GPU3DMatrix m{}; for (int i=0;i<4;++i) m.c[i][i]=1; return m; }
inline int gpu_batches_count(SDL_GPUDevice * device,uint64_t sceneId,const das::TArray<uint64_t> & meshes,
        const das::TArray<das::float4> & models,const das::TArray<das::float4> & colors) {
    auto * scene=SDL_FindGPUBatchScene(device,sceneId); if (!scene) return -1;
    SDL_GPUBatchPlan plan;
    if (!SDL_PrepareGPUBatches(*scene,meshes,models,colors,gpu_batches_camera(),{0,0,1,.2f},plan)) return -1;
    uint32_t size=0;
    for (auto & group:plan.groups) { if (!group.count || group.offset!=size) return -1; size+=group.count*128; }
    return size==meshes.size*128 && plan.bytes.size()==size ? int(plan.groups.size()) : -1;
}
inline bool gpu_batches_depth(SDL_GPUDevice * device,SDL_Window * window,uint64_t id) {
    auto * scene=SDL_FindGPUBatchScene(device,id); int w=0,h=0;
    return scene && SDL_GetWindowSizeInPixels(window,&w,&h) && scene->depth && scene->width==uint32_t(w) && scene->height==uint32_t(h);
}
inline bool gpu_batches_preflight(SDL_GPUDevice * device,uint64_t id,const das::TArray<uint64_t> & meshes,
        const das::TArray<das::float4> & models,const das::TArray<das::float4> & colors) {
    auto * scene=SDL_FindGPUBatchScene(device,id); if (!scene || scene->instances || scene->upload) return false;
    GPUFake::scenario=1; GPUFake::trace.clear();
    return SDL_GPUBatchFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),*scene,meshes,models,colors,gpu_batches_camera(),{0,0,1,.2f})==-1 &&
        GPUFake::trace.empty() && !scene->instances && !scene->upload;
}
inline bool gpu_batches_failure(SDL_GPUDevice * device,uint64_t id,const das::TArray<uint64_t> & meshes,
        const das::TArray<das::float4> & models,const das::TArray<das::float4> & colors) {
    auto * scene=SDL_FindGPUBatchScene(device,id); if (!scene) return false;
    struct Reset { ~Reset() { SDL_TestGPUBatchFailSubmit=false; } } reset;
    SDL_TestGPUBatchFailSubmit=true; GPUFake::scenario=1; GPUFake::trace.clear();
    return SDL_GPUBatchFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),*scene,meshes,models,colors,gpu_batches_camera(),{0,0,1,.2f})==-1 &&
        GPUFake::trace.empty() && std::string(SDL_GetError())=="injected batch upload failure";
}
inline bool gpu_batches_submit(GPUReadback & r,SDL_GPUBatchScene & scene,const das::TArray<uint64_t> & meshes,
        const das::TArray<das::float4> & models,const das::TArray<das::float4> & colors,
        const SDL_GPU3DMatrix * overrideCamera=nullptr) {
    const auto camera=overrideCamera?*overrideCamera:gpu_batches_camera(); SDL_GPUBatchPlan plan;
    if (!SDL_PrepareGPUBatches(scene,meshes,models,colors,camera,{0,0,1,.2f},plan) || !SDL_UploadGPUBatches(scene,plan)) return false;
    SDL_GPUTextureCreateInfo ti{}; ti.type=SDL_GPU_TEXTURETYPE_2D; ti.format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    ti.usage=SDL_GPU_TEXTUREUSAGE_COLOR_TARGET; ti.width=ti.height=64; ti.layer_count_or_depth=ti.num_levels=1; ti.sample_count=SDL_GPU_SAMPLECOUNT_1;
    r.texture=SDL_CreateGPUTexture(r.device,&ti); if (!r.texture) return false;
    SDL_GPUTransferBufferCreateInfo transfer{}; transfer.usage=SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD; transfer.size=64*64*4;
    r.transfer=SDL_CreateGPUTransferBuffer(r.device,&transfer); if (!r.transfer) return false;
    r.command=SDL_AcquireGPUCommandBuffer(r.device); if (!r.command) return false;
    SDL_GPUColorTargetInfo target{}; target.texture=r.texture; target.clear_color={0,0,0,1}; target.load_op=SDL_GPU_LOADOP_CLEAR; target.store_op=SDL_GPU_STOREOP_STORE;
    auto * pass=SDL_BeginGPU3DPass(r.command,target,scene,64,64); if (!pass) return false;
    SDL_RecordGPUBatches(pass,r.command,scene,plan,camera); SDL_EndGPURenderPass(pass);
    auto * copy=SDL_BeginGPUCopyPass(r.command); if (!copy) return false;
    SDL_GPUTextureRegion source{}; source.texture=r.texture; source.w=source.h=64; source.d=1;
    SDL_GPUTextureTransferInfo dest{}; dest.transfer_buffer=r.transfer; dest.pixels_per_row=dest.rows_per_layer=64;
    SDL_DownloadFromGPUTexture(copy,&source,&dest); SDL_EndGPUCopyPass(copy);
    r.fence=SDL_SubmitGPUCommandBufferAndAcquireFence(r.command); r.command=nullptr; r.submitted=true;
    return r.fence!=nullptr;
}
inline bool gpu_batches_check(GPUReadback & r,const das::TArray<uint64_t> & meshes,const das::TArray<das::float4> & models,
        const das::TArray<das::float4> & colors,uint64_t first,uint64_t second) {
    if (!meshes.size) {
        if (!SDL_WaitForGPUFences(r.device,true,&r.fence,1)) return false;
        auto * p=static_cast<uint8_t*>(SDL_MapGPUTransferBuffer(r.device,r.transfer,false)); if (!p) return false;
        bool valid=true;
        for (int i=0;i<4096;++i) if (p[i*4] || p[i*4+1] || p[i*4+2] || p[i*4+3]!=255) valid=false;
        SDL_UnmapGPUTransferBuffer(r.device,r.transfer); return valid;
    }
    if (meshes.size!=3 || models.size!=12 || colors.size!=3) return false;
    std::array<std::array<int,4>,3> textures{};
    for (int i=0;i<3;++i) {
        uint64_t id; std::memcpy(&id,meshes.data+i*8,8);
        if (id!=first && id!=second) return false;
        textures[i]=id==first?std::array<int,4>{160,210,96,192}:std::array<int,4>{32,100,240,255};
    }
    return gpu_instances_check(r,models,gpu_batches_camera(),&colors,&textures);
}
inline bool gpu_batches_pixels(SDL_GPUDevice * device,uint64_t id,const das::TArray<uint64_t> & meshes,
        const das::TArray<das::float4> & models,const das::TArray<das::float4> & colors,uint64_t first,uint64_t second) {
    auto * scene=SDL_FindGPUBatchScene(device,id); if (!scene || scene->colorFormat!=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) return false;
    GPUReadback r{device};
    return gpu_batches_submit(r,*scene,meshes,models,colors) && gpu_batches_check(r,meshes,models,colors,first,second);
}
inline bool gpu_batches_pending(SDL_GPUDevice * device,uint64_t id,const das::TArray<uint64_t> & meshes,
        const das::TArray<das::float4> & models,const das::TArray<das::float4> & colors,uint64_t first,uint64_t second) {
    auto * scene=SDL_FindGPUBatchScene(device,id); if (!scene || meshes.size!=3 || models.size!=12 || colors.size!=3) return false;
    uint64_t allFirst[3]={first,first,first}; das::TArray<uint64_t> one;
    std::memset(static_cast<das::Array*>(&one),0,sizeof(das::Array)); one.data=reinterpret_cast<char*>(allFirst); one.size=3;
    std::vector<std::unique_ptr<GPUReadback>> pending;
    for (int frame=0;frame<12;++frame) {
        auto readback=std::make_unique<GPUReadback>(); readback->device=device;
        if (!gpu_batches_submit(*readback,*scene,frame%2?one:meshes,models,colors)) return false;
        pending.push_back(std::move(readback));
    }
    for (int frame=0;frame<12;++frame)
        if (!gpu_batches_check(*pending[frame],frame%2?one:meshes,models,colors,first,second)) return false;
    return true;
}
}
