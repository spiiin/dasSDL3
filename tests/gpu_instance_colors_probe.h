#pragma once
#include "gpu_instancing_probe.h"
namespace sdl3_test {
inline uint64_t gpu_colors_offscreen(SDL_GPUDevice * device,const das::TArray<das::float4> & positions,
        const das::TArray<das::float4> & normals,const das::TArray<das::float2> & uv,
        const das::TArray<uint8_t> & pixels,const das::TArray<uint32_t> & indices,
        const das::TArray<das::float4> & models,const das::TArray<das::float4> & colors,
        const char * vs,const char * fs,uint32_t format) {
    return SDL_CreateGPULitForFormat(device,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,positions,normals,uv,pixels,1,1,indices,vs,fs,format,&models,&colors);
}
inline bool gpu_colors_pixels(SDL_GPUDevice * device,uint64_t id,const das::TArray<das::float4> & models,
        const das::TArray<das::float4> & colors) {
    auto * mesh=SDL_FindGPULit(device,id);
    if (!mesh || !mesh->instancesReady || !mesh->instanceColors || mesh->instanceCount!=3 || models.size!=12 || colors.size!=3) return false;
    SDL_GPU3DMatrix camera{}; for (int i=0;i<4;++i) camera.c[i][i]=1;
    GPUReadback readback{device};
    return gpu_instances_submit(readback,*mesh,camera) && gpu_instances_check(readback,models,camera,&colors);
}
inline bool gpu_colors_pending(SDL_GPUDevice * device,uint64_t id,const das::TArray<das::float4> & models,
        const das::TArray<das::float4> & first,const das::TArray<das::float4> & second) {
    auto * mesh=SDL_FindGPULit(device,id);
    if (!mesh || !mesh->instanceColors || mesh->instanceCount!=3 || models.size!=12 || first.size!=3 || second.size!=3) return false;
    SDL_GPU3DMatrix camera{}; for (int i=0;i<4;++i) camera.c[i][i]=1;
    std::vector<std::unique_ptr<GPUReadback>> pending;
    for (int frame=0;frame<12;++frame) {
        const auto & colors=frame%2?second:first;
        if (!SDL_UpdateGPUColoredInstances(device,id,models,colors)) return false;
        auto readback=std::make_unique<GPUReadback>(); readback->device=device;
        if (!gpu_instances_submit(*readback,*mesh,camera)) return false;
        pending.push_back(std::move(readback));
    }
    for (int frame=0;frame<12;++frame)
        if (!gpu_instances_check(*pending[frame],models,camera,frame%2?&second:&first)) return false;
    return true;
}
inline bool gpu_colors_failure(SDL_GPUDevice * device,uint64_t id,const das::TArray<das::float4> & models,
        const das::TArray<das::float4> & colors) {
    struct Reset { ~Reset() { SDL_TestGPUInstancesFailSubmit=false; } } reset;
    SDL_TestGPUInstancesFailSubmit=true;
    if (SDL_UpdateGPUColoredInstances(device,id,models,colors)) return false;
    if (std::string(SDL_GetError())!="injected instance upload submit failure") return false;
    auto * mesh=SDL_FindGPULit(device,id); if (!mesh || mesh->instancesReady) return false;
    SDL_GPU3DMatrix camera{}; for (int i=0;i<4;++i) camera.c[i][i]=1;
    GPUFake::scenario=1; GPUFake::trace.clear();
    return SDL_GPUInstancesFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),*mesh,camera,{0,0,1,.2f})==-1 && GPUFake::trace.empty();
}
inline bool gpu_colors_guards(const das::TArray<das::float4> & models) {
    if (models.size!=12) return false;
    float values[3][4]={{1,1,1,1},{1,1,1,1},{1,1,1,1}};
    das::TArray<das::float4> colors;
    std::memset(static_cast<das::Array*>(&colors),0,sizeof(das::Array));
    colors.data=reinterpret_cast<char*>(values); colors.size=3;
    std::vector<uint8_t> packed;
    if (!SDL_PackGPUInstances(models,&colors,packed)) return false;
    for (int channel=0;channel<4;++channel) {
        for (float value : {-.01f,1.01f,std::numeric_limits<float>::infinity(),std::numeric_limits<float>::quiet_NaN()}) {
            values[2][channel]=value;
            if (SDL_PackGPUInstances(models,&colors,packed)) return false;
        }
        values[2][channel]=1;
    }
    colors.size=2;
    if (SDL_PackGPUInstances(models,&colors,packed)) return false;
    colors.size=3; colors.data=nullptr;
    return !SDL_PackGPUInstances(models,&colors,packed);
}
}
