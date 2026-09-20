#pragma once
#include <SDL3/SDL.h>
#include <array>
#include <vector>
#include <fstream>
#include <filesystem>
#include <cstring>
#include <cstdio>
// Test data only. GPU entry points under test must be called from gpu_raw.das.
namespace sdl3_test {
inline uint32_t raw_properties() {
    auto p=SDL_CreateProperties();
    SDL_SetBooleanProperty(p,SDL_PROP_GPU_DEVICE_CREATE_DEBUGMODE_BOOLEAN,true);
    SDL_SetBooleanProperty(p,SDL_PROP_GPU_DEVICE_CREATE_SHADERS_SPIRV_BOOLEAN,true);
    SDL_SetBooleanProperty(p,SDL_PROP_GPU_DEVICE_CREATE_SHADERS_DXIL_BOOLEAN,true);
    return p;
}
inline void raw_destroy_properties(uint32_t p) { SDL_DestroyProperties(p); }
inline const std::vector<uint8_t> & raw_code(bool dxil,int stage) {
    static std::array<std::vector<uint8_t>,6> blobs;
    auto & bytes=blobs[stage+(dxil?3:0)];
    if(bytes.empty()) {
        std::string path=(std::filesystem::path(__FILE__).parent_path()/"assets/raw_gpu/raw.").string();
        path+=(stage==0?"vert":stage==1?"frag":"comp"); path+=(dxil?".dxil":".spv");
        std::ifstream f(path,std::ios::binary);
        bytes.assign(std::istreambuf_iterator<char>(f),{});
    }
    return bytes;
}
inline bool raw_shader_info(bool dxil,int stage,SDL_GPUShaderCreateInfo & info) {
    const auto & code=raw_code(dxil,stage); info={};
    info.code=code.data(); info.code_size=code.size(); info.entrypoint="main";
    info.format=dxil?SDL_GPU_SHADERFORMAT_DXIL:SDL_GPU_SHADERFORMAT_SPIRV;
    info.stage=stage==0?SDL_GPU_SHADERSTAGE_VERTEX:SDL_GPU_SHADERSTAGE_FRAGMENT;
    info.num_samplers=info.num_storage_textures=info.num_storage_buffers=info.num_uniform_buffers=1;
    return !code.empty();
}
inline bool raw_compute_info(bool dxil,SDL_GPUComputePipelineCreateInfo & info) {
    const auto & code=raw_code(dxil,2); info={};
    info.code=code.data(); info.code_size=code.size(); info.entrypoint="main";
    info.format=dxil?SDL_GPU_SHADERFORMAT_DXIL:SDL_GPU_SHADERFORMAT_SPIRV;
    info.num_samplers=info.num_readonly_storage_textures=info.num_readonly_storage_buffers=1;
    info.num_readwrite_storage_textures=info.num_readwrite_storage_buffers=info.num_uniform_buffers=1;
    info.threadcount_x=4; info.threadcount_y=info.threadcount_z=1;
    return !code.empty();
}
inline void raw_pipeline_info(SDL_GPUGraphicsPipelineCreateInfo & info,SDL_GPUShader * vs,SDL_GPUShader * fs) {
    static const SDL_GPUVertexBufferDescription vb{0,8,SDL_GPU_VERTEXINPUTRATE_VERTEX,0};
    static const SDL_GPUVertexAttribute attr{0,0,SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2,0};
    static const SDL_GPUColorTargetDescription color=[] {
        SDL_GPUColorTargetDescription c{}; c.format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
        c.blend_state.enable_blend=true;
        c.blend_state.src_color_blendfactor=SDL_GPU_BLENDFACTOR_CONSTANT_COLOR;
        c.blend_state.dst_color_blendfactor=SDL_GPU_BLENDFACTOR_ZERO;
        c.blend_state.color_blend_op=SDL_GPU_BLENDOP_ADD;
        c.blend_state.src_alpha_blendfactor=SDL_GPU_BLENDFACTOR_ONE;
        c.blend_state.dst_alpha_blendfactor=SDL_GPU_BLENDFACTOR_ZERO;
        c.blend_state.alpha_blend_op=SDL_GPU_BLENDOP_ADD; return c;
    }();
    info={}; info.vertex_shader=vs; info.fragment_shader=fs;
    info.vertex_input_state={&vb,1,&attr,1};
    info.primitive_type=SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
    info.rasterizer_state.enable_depth_clip=true;
    info.target_info.color_target_descriptions=&color; info.target_info.num_color_targets=1;
}
inline bool raw_fill_upload(void * ptr) {
    if(!ptr)return false; auto * p=static_cast<uint8_t *>(ptr); std::memset(p,0,1024);
    const float vertices[]={-1,-1,3,-1,-1,3}, ones[]={1,1,1,1};
    const uint32_t indices[]={0,1,2};
    const SDL_GPUIndirectDrawCommand draw{3,1,0,0};
    const SDL_GPUIndexedIndirectDrawCommand indexed{3,1,0,0,0};
    const SDL_GPUIndirectDispatchCommand dispatch{2,1,1};
    std::memcpy(p,vertices,sizeof(vertices)); std::memcpy(p+32,indices,sizeof(indices));
    std::memcpy(p+64,ones,sizeof(ones)); std::memcpy(p+96,&draw,sizeof(draw));
    std::memcpy(p+128,&indexed,sizeof(indexed)); std::memcpy(p+160,&dispatch,sizeof(dispatch));
    std::memset(p+256,255,64);return true;
}
inline void * raw_uniform(bool compute,uint32_t base) {
    static float color[4]={1,1,1,1}; static uint32_t values[4]; values[0]=base;
    return compute?static_cast<void *>(values):static_cast<void *>(color);
}
inline bool raw_check_words(void * ptr,uint32_t offset,uint32_t base) {
    if(!ptr)return false;auto * p=static_cast<uint8_t *>(ptr)+offset;
    for(uint32_t i=0;i<8;++i) { uint32_t v; std::memcpy(&v,p+4*i,4);if(v!=base+i) {
        std::fprintf(stderr,"raw words offset=%u index=%u expected=%u actual=%u\n",offset,i,base+i,v); return false;
    }}return true;
}
inline bool raw_check_pixels(void * ptr,uint32_t offset,uint32_t count) {
    if(!ptr)return false;auto * p=static_cast<uint8_t *>(ptr)+offset;
    for(uint32_t i=0;i<count;++i) {
        if(p[4*i]<63 || p[4*i]>64 || p[4*i+1]<127 || p[4*i+1]>128 ||
           p[4*i+2]<191 || p[4*i+2]>192 || p[4*i+3]!=255) {
            std::fprintf(stderr,"raw pixels offset=%u index=%u actual=%u,%u,%u,%u\n",offset,i,p[4*i],p[4*i+1],p[4*i+2],p[4*i+3]);return false;
        }
    }return true;
}
inline bool raw_check_copy(void * ptr) {
    if(!ptr)return false; float ones[4];std::memcpy(ones,ptr,16);
    return ones[0]==1 && ones[1]==1 && ones[2]==1 && ones[3]==1;
}
}
