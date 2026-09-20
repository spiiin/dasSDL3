#pragma once
#include "sdl3_gpu_shader.h"
#include "gpu_pixel_reference.h"
#include <thread>
namespace sdl3_test {
inline uint32_t shader_count(SDL_GPUDevice * device) {
    uint32_t count=0; for (const auto & item:SDL_GPUOwnedShaders) if (item.second.device==device) ++count; return count;
}
inline bool shader_exists(uint64_t id) { return SDL_GPUOwnedShaders.count(id)!=0; }
inline bool shader_hidden_fields_clear(const SDL_GPUShaderCreateInfo & info) {
    return !info.code && !info.code_size && !info.entrypoint;
}
inline void shader_fill_info(SDL_GPUShaderCreateInfo & info) {
    info={}; info.format=SDL_GPU_SHADERFORMAT_DXIL; info.stage=SDL_GPU_SHADERSTAGE_FRAGMENT;
    info.num_samplers=1; info.num_storage_textures=2; info.num_storage_buffers=3; info.num_uniform_buffers=4; info.props=123;
}
inline bool shader_check_info(const SDL_GPUShaderCreateInfo & info) {
    return info.format==SDL_GPU_SHADERFORMAT_SPIRV && info.stage==SDL_GPU_SHADERSTAGE_VERTEX &&
        info.num_samplers==5 && info.num_storage_textures==6 && info.num_storage_buffers==7 &&
        info.num_uniform_buffers==2 && info.props==456 && shader_hidden_fields_clear(info);
}
inline bool shader_wrong_thread(SDL_GPUDevice * device,uint64_t id) {
    bool rejected=false;
    std::thread worker([&] {
        SDL_GPUShaderCreateInfo info{};
        rejected=!SDL_GetGPUCheckedShaderInfo(device,id,info) && !SDL_ReleaseGPUCheckedShader(device,id);
    }); worker.join(); return rejected;
}
inline bool shader_invalid_metadata() {
    SDL_GPUShaderCreateInfo base{}; base.format=SDL_GPU_SHADERFORMAT_SPIRV;
    const uint8_t shortCode[]={3,2,35,7};
    if (SDL_GPUValidateShaderBytes(shortCode,4,base.format) ||
        SDL_GPUValidateShaderBytes(shortCode,SDL_GPUShaderByteLimit+1,base.format) ||
        SDL_GPUValidateShaderBytes(shortCode,(uint64_t(1)<<32)+20,base.format) ||
        SDL_GPUValidateShaderBytes(nullptr,20,base.format)) return false;
    for (int n=0;n<8;++n) {
        auto info=base;
        switch(n) {
        case 0: info.stage=SDL_GPUShaderStage(2); break;
        case 1: info.stage=SDL_GPUShaderStage(-1); break;
        case 2: info.num_samplers=17; break;
        case 3: info.num_storage_textures=9; break;
        case 4: info.num_storage_buffers=9; break;
        case 5: info.num_uniform_buffers=5; break;
        case 6: info.props=1; break;
        case 7: info.format|=SDL_GPU_SHADERFORMAT_DXIL; break;
        }
        if (SDL_GPUValidateShaderInfo(info,"main")) return false;
    }
    base.num_samplers=16; base.num_storage_textures=8; base.num_storage_buffers=8; base.num_uniform_buffers=4;
    return SDL_GPUValidateShaderInfo(base,"_entry123") &&
        !SDL_GPUValidateShaderInfo(base,"") && !SDL_GPUValidateShaderInfo(base,nullptr) &&
        !SDL_GPUValidateShaderInfo(base,"1entry") && !SDL_GPUValidateShaderInfo(base,"bad entry") &&
        !SDL_GPUValidateShaderInfo(base,std::string(128,'x').c_str());
}
// Trusted triangle fixtures only. Build a native test pipeline, release both
// standalone shaders, then compare actual pixels to the existing CPU oracle.
inline bool shader_pipeline_pixels(SDL_GPUDevice * device,uint64_t vertex,uint64_t fragment) {
    const auto * vs=SDL_GPUTransferFind(SDL_GPUOwnedShaders,device,vertex);
    const auto * fs=SDL_GPUTransferFind(SDL_GPUOwnedShaders,device,fragment);
    if (!vs || !fs || vs->info.stage!=SDL_GPU_SHADERSTAGE_VERTEX || fs->info.stage!=SDL_GPU_SHADERSTAGE_FRAGMENT) return false;
    SDL_GPUColorTargetDescription color{}; color.format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    SDL_GPUGraphicsPipelineCreateInfo info{};
    info.vertex_shader=vs->shader; info.fragment_shader=fs->shader;
    info.primitive_type=SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
    info.rasterizer_state.fill_mode=SDL_GPU_FILLMODE_FILL;
    info.rasterizer_state.cull_mode=SDL_GPU_CULLMODE_NONE; info.rasterizer_state.enable_depth_clip=true;
    info.multisample_state.sample_count=SDL_GPU_SAMPLECOUNT_1;
    info.target_info.num_color_targets=1; info.target_info.color_target_descriptions=&color;
    auto release=[device](SDL_GPUGraphicsPipeline * p) { SDL_ReleaseGPUGraphicsPipeline(device,p); };
    std::unique_ptr<SDL_GPUGraphicsPipeline,decltype(release)> pipeline(SDL_CreateGPUGraphicsPipeline(device,&info),release);
    if (!pipeline) return false;
    SDL_ReleaseGPUCheckedShader(device,vertex); SDL_ReleaseGPUCheckedShader(device,fragment);
    return gpu_triangle_native_pixels(device,pipeline.get());
}
}
