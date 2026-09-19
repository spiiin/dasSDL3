#pragma once
#include "sdl3_gpu_lit.h"

inline uint64_t SDL_CreateGPUInstancedMesh(SDL_GPUDevice * device,SDL_Window * window,
        const das::TArray<das::float4> & positions,const das::TArray<das::float4> & normals,const das::TArray<das::float2> & uv,
        const das::TArray<uint8_t> & pixels,uint32_t width,uint32_t height,
        const das::TArray<uint32_t> & indices,const das::TArray<das::float4> & models,
        const char * vertex,const char * fragment,uint32_t format) {
    if (!SDL_IsMainThread() || !SDL_GPUWindowClaimedBy(device,window)) { SDL_SetError("GPU instancing: main thread and claimed window required"); return 0; }
    return SDL_CreateGPULitForFormat(device,SDL_GetGPUSwapchainTextureFormat(device,window),positions,normals,uv,pixels,width,height,indices,vertex,fragment,format,&models);
}
inline void SDL_RecordGPUInstances(SDL_GPURenderPass * pass,SDL_GPUCommandBuffer * command,
        const SDL_GPULitEntry & m,const SDL_GPU3DMatrix & camera,const SDL_GPULight & light) {
    SDL_PushGPUVertexUniformData(command,0,&camera,sizeof(camera));
    SDL_PushGPUFragmentUniformData(command,0,&light,sizeof(light));
    SDL_BindGPUGraphicsPipeline(pass,m.pipeline);
    SDL_GPUBufferBinding buffers[2]{}; buffers[0].buffer=m.vertices; buffers[1].buffer=m.instances;
    SDL_BindGPUVertexBuffers(pass,0,buffers,2);
    SDL_GPUBufferBinding index{}; index.buffer=m.indices;
    SDL_BindGPUIndexBuffer(pass,&index,SDL_GPU_INDEXELEMENTSIZE_32BIT);
    SDL_GPUTextureSamplerBinding sample{}; sample.texture=m.texture; sample.sampler=m.sampler;
    SDL_BindGPUFragmentSamplers(pass,0,&sample,1);
    SDL_DrawGPUIndexedPrimitives(pass,m.count,m.instanceCount,0,0,0);
}
template<typename API>
inline int SDL_GPUInstancesFrame(SDL_GPUDevice * device,SDL_Window * window,SDL_GPULitEntry & mesh,
        const SDL_GPU3DMatrix & camera,das::float4 light) {
    if (!mesh.instances || !mesh.instanceCount) { SDL_SetError("GPU instancing: instanced mesh required"); return -1; }
    SDL_GPU3DMatrix identity{}; for (int i=0;i<4;++i) identity.c[i][i]=1;
    SDL_GPULitUniforms unused{}; SDL_GPULight lighting{};
    if (!SDL_PrepareGPULit(camera,identity,light,unused,lighting)) return -1;
    uint32_t w=0,h=0;
    return SDL_GPUFrameWithTarget<API>(device,window,{0,0,0,1},w,h,
        [&mesh,&camera,&lighting](SDL_GPURenderPass * pass,SDL_GPUCommandBuffer * command) { SDL_RecordGPUInstances(pass,command,mesh,camera,lighting); },
        [&mesh](SDL_GPUCommandBuffer * command,const SDL_GPUColorTargetInfo & target,uint32_t width,uint32_t height) {
            return SDL_BeginGPU3DPass(command,target,mesh,width,height);
        });
}
inline int SDL_DrawGPUInstancedMesh(SDL_GPUDevice * device,SDL_Window * window,uint64_t id,
        das::float4 a,das::float4 b,das::float4 c,das::float4 d,das::float4 light) {
    if (!SDL_IsMainThread()) { SDL_SetError("GPU instancing: main thread required"); return -1; }
    auto * mesh=SDL_FindGPULit(device,id); if (!mesh) return -1;
    if (!SDL_GPUWindowClaimedBy(device,window)) { SDL_SetError("GPU instancing: unclaimed window"); return -1; }
    if (mesh->colorFormat!=SDL_GetGPUSwapchainTextureFormat(device,window)) { SDL_SetError("GPU instancing: target format mismatch"); return -1; }
    return SDL_GPUInstancesFrame<SDL_GPUClearAPI>(device,window,*mesh,SDL_GPU3DColumns(a,b,c,d),light);
}
