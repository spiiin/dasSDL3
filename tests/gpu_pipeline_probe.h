#pragma once
#include "sdl3_gpu_pipeline.h"
#include "gpu_pixel_reference.h"
#include <thread>
namespace sdl3_test {
inline uint32_t graphics_pipeline_count(SDL_GPUDevice * device) {
    uint32_t n=0; for (const auto & item:SDL_GPUOwnedGraphicsPipelines) if (item.second.device==device) ++n; return n;
}
inline bool graphics_pipeline_exists(uint64_t id) { return SDL_GPUOwnedGraphicsPipelines.count(id)!=0; }
inline bool graphics_pipeline_sorted(SDL_GPUDevice * device,uint64_t id) {
    auto * p=SDL_GPUTransferFind(SDL_GPUOwnedGraphicsPipelines,device,id);
    return p && p->buffers.size()==2 && p->buffers[0].slot==0 && p->buffers[1].slot==1 &&
        p->buffers[0].input_rate==SDL_GPU_VERTEXINPUTRATE_VERTEX && p->buffers[1].input_rate==SDL_GPU_VERTEXINPUTRATE_INSTANCE;
}
inline bool graphics_pipeline_hidden(const SDL_GPUGraphicsPipelineCreateInfo & info) {
    return !info.vertex_shader && !info.fragment_shader && !info.vertex_input_state.vertex_buffer_descriptions &&
        !info.vertex_input_state.vertex_attributes && !info.vertex_input_state.num_vertex_buffers &&
        !info.vertex_input_state.num_vertex_attributes && !info.target_info.color_target_descriptions && !info.target_info.num_color_targets;
}
inline bool graphics_pipeline_thread(SDL_GPUDevice * device,uint64_t id) {
    bool ok=false;
    std::thread worker([&] { SDL_GPUGraphicsPipelineCreateInfo info{};
        ok=!SDL_GetGPUCheckedGraphicsPipelineInfo(device,id,info) && !SDL_ReleaseGPUCheckedGraphicsPipeline(device,id);
    }); worker.join(); return ok;
}
inline bool graphics_pipeline_triangle(SDL_GPUDevice * device,uint64_t id,uint32_t mode) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUOwnedGraphicsPipelines,device,id); if (!entry || mode>2) return false;
    return gpu_triangle_native_pixels(device,entry->pipeline,mode==2 ? 1u : 15u,mode==1);
}
inline bool graphics_pipeline_validation() {
    SDL_GPUGraphicsPipelineCreateInfo base{},out{}; base.rasterizer_state.enable_depth_clip=true;
    if (!SDL_GPUPipelineState(base,out) || !graphics_pipeline_hidden(out)) return false;
    for (int n=0;n<17;++n) {
        auto bad=base;
        switch(n) {
        case 0: bad.primitive_type=SDL_GPUPrimitiveType(-1); break;
        case 1: bad.rasterizer_state.fill_mode=SDL_GPU_FILLMODE_LINE; break;
        case 2: bad.rasterizer_state.cull_mode=SDL_GPUCullMode(3); break;
        case 3: bad.rasterizer_state.front_face=SDL_GPUFrontFace(-1); break;
        case 4: bad.multisample_state.sample_count=SDL_GPUSampleCount(4); break;
        case 5: bad.multisample_state.sample_mask=1; break;
        case 6: bad.multisample_state.enable_mask=true; break;
        case 7: bad.props=1; break;
        case 8: bad.rasterizer_state.depth_bias_clamp=1; break;
        case 9: bad.rasterizer_state.depth_bias_constant_factor=std::numeric_limits<float>::quiet_NaN(); break;
        case 10: bad.rasterizer_state.depth_bias_slope_factor=std::numeric_limits<float>::infinity(); break;
        case 11: bad.depth_stencil_state.enable_depth_test=true; break;
        case 12: bad.target_info.has_depth_stencil_target=true; bad.target_info.depth_stencil_format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM; break;
        case 13: bad.depth_stencil_state.compare_op=SDL_GPUCompareOp(99); break;
        case 14: bad.depth_stencil_state.front_stencil_state.fail_op=SDL_GPUStencilOp(-1); break;
        case 15: bad.rasterizer_state.depth_bias_constant_factor=65537; break;
        case 16: bad.rasterizer_state.depth_bias_slope_factor=17; break;
        }
        if (SDL_GPUPipelineState(bad,out)) return false;
    }
    std::vector<SDL_GPUVertexBufferDescription> buffers{{0,16,SDL_GPU_VERTEXINPUTRATE_VERTEX,0}};
    std::vector<SDL_GPUVertexAttribute> attributes{{0,0,SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2,0},{1,0,SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2,8}};
    if (!SDL_GPUPipelineLayout(buffers,attributes)) return false;
    for (int n=0;n<17;++n) {
        auto b=buffers; auto a=attributes;
        switch(n) {
        case 0: b.push_back(b[0]); break;
        case 1: b[0].slot=16; break;
        case 2: b[0].pitch=0; break;
        case 3: b[0].pitch=2049; break;
        case 4: b[0].input_rate=SDL_GPUVertexInputRate(-1); break;
        case 5: b[0].instance_step_rate=1; break;
        case 6: a[1].location=0; break;
        case 7: a[1].location=16; break;
        case 8: a[0].buffer_slot=1; break;
        case 9: a[0].offset=0xffffffff; break;
        case 10: a[1].offset=9; break;
        case 11: a[0].format=SDL_GPU_VERTEXELEMENTFORMAT_INVALID; break;
        case 12: b[0].pitch=15; break;
        case 13: a.clear(); break;
        case 14: b.resize(17); break;
        case 15: a.resize(17); break;
        case 16: b[0].slot=1; a[0].buffer_slot=1; a[1].buffer_slot=1; break;
        }
        if (SDL_GPUPipelineLayout(b,a)) return false;
    }
    // Independent table covers every pinned vertex format's byte size/alignment.
    const uint32_t sizes[]={4,8,12,16,4,8,12,16,4,8,12,16,2,4,2,4,2,4,2,4,4,8,4,8,4,8,4,8,4,8};
    for (uint32_t f=1;f<=30;++f) {
        uint32_t size=0,align=0; if (!SDL_GPUPipelineVertexElement(SDL_GPUVertexElementFormat(f),size,align) || size!=sizes[f-1]) return false;
        if (align!=(f<=12 ? 4u : f<=20 ? 1u : 2u)) return false;
    }
    SDL_GPUColorTargetDescription color{},normalized{}; color.format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    color.blend_state.padding1=255; color.blend_state.padding2=255;
    if (!SDL_GPUPipelineColor(color,normalized) || normalized.blend_state.padding1 || normalized.blend_state.padding2) return false;
    color.blend_state.enable_blend=true; if (SDL_GPUPipelineColor(color,normalized)) return false;
    color.blend_state.enable_blend=false; color.blend_state.color_write_mask=16;
    if (SDL_GPUPipelineColor(color,normalized)) return false;
    color={}; color.format=SDL_GPUTextureFormat(-1);
    if (SDL_GPUPipelineColor(color,normalized)) return false;
    return true;
}
}
