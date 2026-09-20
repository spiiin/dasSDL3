#pragma once
#include "sdl3_gpu_shader.h"
#include <cmath>
#include <array>

struct SDL_GPUOwnedGraphicsPipeline {
    SDL_GPUDevice * device=nullptr;
    SDL_GPUGraphicsPipeline * pipeline=nullptr;
    SDL_GPUGraphicsPipelineCreateInfo info{}; // No borrowed pointers/counts.
    SDL_GPUShaderCreateInfo vertexResources{},fragmentResources{};
    std::vector<SDL_GPUVertexBufferDescription> buffers;
    std::vector<SDL_GPUVertexAttribute> attributes;
    std::vector<SDL_GPUColorTargetDescription> colors;
};
inline std::unordered_map<uint64_t,SDL_GPUOwnedGraphicsPipeline> SDL_GPUOwnedGraphicsPipelines;

inline bool SDL_GPUPipelineVertexElement(SDL_GPUVertexElementFormat format,uint32_t & size,uint32_t & align) {
    const auto f=uint32_t(format);
    if (!f || f>SDL_GPU_VERTEXELEMENTFORMAT_HALF4) return SDL_SetError("GPU pipeline: invalid vertex element format");
    static_assert(SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4==12 && SDL_GPU_VERTEXELEMENTFORMAT_HALF4==30);
    if (f<=12) { align=4; size=4*((f-1)%4+1); }
    else if (f<=20) { align=1; size=(f%2) ? 2 : 4; }
    else { align=2; size=(f%2) ? 4 : 8; }
    return true;
}
inline bool SDL_GPUPipelineLayout(const std::vector<SDL_GPUVertexBufferDescription> & buffers,
        const std::vector<SDL_GPUVertexAttribute> & attributes) {
    if (buffers.size()>16 || attributes.size()>16) return SDL_SetError("GPU pipeline: at most 16 vertex buffers/attributes");
    std::array<const SDL_GPUVertexBufferDescription *,16> slots{};
    std::array<bool,16> locations{},used{};
    for (const auto & b:buffers) {
        if (b.slot>=buffers.size() || slots[b.slot] || !b.pitch || b.pitch>2048 ||
            uint32_t(b.input_rate)>SDL_GPU_VERTEXINPUTRATE_INSTANCE || b.instance_step_rate)
            return SDL_SetError("GPU pipeline: dense unique slots from zero, pitch 1..2048, valid rate and zero step rate required");
        slots[b.slot]=&b;
    }
    for (const auto & a:attributes) {
        uint32_t size=0,align=0;
        if (!SDL_GPUPipelineVertexElement(a.format,size,align)) return false;
        if (a.location>=16 || locations[a.location] || a.buffer_slot>=16 || !slots[a.buffer_slot])
            return SDL_SetError("GPU pipeline: unique locations 0..15 and an existing buffer slot required");
        const auto pitch=slots[a.buffer_slot]->pitch;
        if (a.offset>pitch || size>pitch-a.offset || a.offset%align || pitch%align)
            return SDL_SetError("GPU pipeline: aligned vertex attribute must fit inside pitch");
        locations[a.location]=true; used[a.buffer_slot]=true;
    }
    for (const auto & b:buffers) if (!used[b.slot]) return SDL_SetError("GPU pipeline: unused vertex buffer description");
    return true;
}
inline bool SDL_GPUPipelineStencil(const SDL_GPUStencilOpState & in,bool enabled,SDL_GPUStencilOpState & out) {
    if (uint32_t(in.compare_op)>SDL_GPU_COMPAREOP_ALWAYS || uint32_t(in.fail_op)>SDL_GPU_STENCILOP_DECREMENT_AND_WRAP ||
        uint32_t(in.pass_op)>SDL_GPU_STENCILOP_DECREMENT_AND_WRAP || uint32_t(in.depth_fail_op)>SDL_GPU_STENCILOP_DECREMENT_AND_WRAP ||
        (enabled && (!in.compare_op || !in.fail_op || !in.pass_op || !in.depth_fail_op)))
        return SDL_SetError("GPU pipeline: invalid stencil state");
    out={}; out.compare_op=enabled ? in.compare_op : SDL_GPU_COMPAREOP_ALWAYS;
    out.fail_op=enabled ? in.fail_op : SDL_GPU_STENCILOP_KEEP;
    out.pass_op=enabled ? in.pass_op : SDL_GPU_STENCILOP_KEEP;
    out.depth_fail_op=enabled ? in.depth_fail_op : SDL_GPU_STENCILOP_KEEP; return true;
}
inline bool SDL_GPUPipelineState(const SDL_GPUGraphicsPipelineCreateInfo & in,SDL_GPUGraphicsPipelineCreateInfo & out) {
    out={}; const auto & r=in.rasterizer_state; const auto & m=in.multisample_state; const auto & d=in.depth_stencil_state;
    if (uint32_t(in.primitive_type)>SDL_GPU_PRIMITIVETYPE_POINTLIST || r.fill_mode!=SDL_GPU_FILLMODE_FILL ||
        uint32_t(r.cull_mode)>SDL_GPU_CULLMODE_BACK || uint32_t(r.front_face)>SDL_GPU_FRONTFACE_CLOCKWISE ||
        uint32_t(m.sample_count)>SDL_GPU_SAMPLECOUNT_8 || m.enable_mask || m.sample_mask || in.props)
        return SDL_SetError("GPU pipeline: invalid/unsupported topology, raster, multisample or extension state");
    if (!std::isfinite(r.depth_bias_constant_factor) || std::abs(r.depth_bias_constant_factor)>65536 ||
        !std::isfinite(r.depth_bias_slope_factor) || std::abs(r.depth_bias_slope_factor)>16 || r.depth_bias_clamp!=0)
        return SDL_SetError("GPU pipeline: finite bounded depth bias and zero bias clamp required");
    const bool depth=in.target_info.has_depth_stencil_target;
    const auto format=in.target_info.depth_stencil_format;
    const bool stencil=format==SDL_GPU_TEXTUREFORMAT_D24_UNORM_S8_UINT || format==SDL_GPU_TEXTUREFORMAT_D32_FLOAT_S8_UINT;
    if ((depth && format!=SDL_GPU_TEXTUREFORMAT_D16_UNORM && format!=SDL_GPU_TEXTUREFORMAT_D24_UNORM &&
        format!=SDL_GPU_TEXTUREFORMAT_D32_FLOAT && !stencil) ||
        (!depth && (d.enable_depth_test || d.enable_depth_write || d.enable_stencil_test)) ||
        (d.enable_depth_write && !d.enable_depth_test) || (d.enable_stencil_test && !stencil) ||
        uint32_t(d.compare_op)>SDL_GPU_COMPAREOP_ALWAYS || (d.enable_depth_test && !d.compare_op))
        return SDL_SetError("GPU pipeline: incompatible depth/stencil state and target");
    out.primitive_type=in.primitive_type;
    auto & nr=out.rasterizer_state; nr.fill_mode=r.fill_mode; nr.cull_mode=r.cull_mode; nr.front_face=r.front_face;
    nr.enable_depth_clip=r.enable_depth_clip; nr.enable_depth_bias=r.enable_depth_bias;
    nr.depth_bias_constant_factor=r.enable_depth_bias ? r.depth_bias_constant_factor : 0;
    nr.depth_bias_slope_factor=r.enable_depth_bias ? r.depth_bias_slope_factor : 0;
    out.multisample_state.sample_count=m.sample_count;
    auto & nd=out.depth_stencil_state;
    nd.enable_depth_test=d.enable_depth_test; nd.enable_depth_write=d.enable_depth_write; nd.enable_stencil_test=d.enable_stencil_test;
    nd.compare_op=d.enable_depth_test ? d.compare_op : SDL_GPU_COMPAREOP_ALWAYS;
    nd.compare_mask=d.enable_stencil_test ? d.compare_mask : 0; nd.write_mask=d.enable_stencil_test ? d.write_mask : 0;
    if (!SDL_GPUPipelineStencil(d.front_stencil_state,d.enable_stencil_test,nd.front_stencil_state) ||
        !SDL_GPUPipelineStencil(d.back_stencil_state,d.enable_stencil_test,nd.back_stencil_state)) return false;
    out.target_info.has_depth_stencil_target=depth;
    out.target_info.depth_stencil_format=depth ? format : SDL_GPU_TEXTUREFORMAT_INVALID; return true;
}
inline bool SDL_GPUPipelineAlphaFactor(SDL_GPUBlendFactor f) {
    return f!=SDL_GPU_BLENDFACTOR_SRC_COLOR && f!=SDL_GPU_BLENDFACTOR_ONE_MINUS_SRC_COLOR &&
        f!=SDL_GPU_BLENDFACTOR_DST_COLOR && f!=SDL_GPU_BLENDFACTOR_ONE_MINUS_DST_COLOR;
}
inline bool SDL_GPUPipelineColor(const SDL_GPUColorTargetDescription & in,SDL_GPUColorTargetDescription & out) {
    const auto f=in.format; const auto & b=in.blend_state;
    if (f!=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM && f!=SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM &&
        f!=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM_SRGB && f!=SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM_SRGB)
        return SDL_SetError("GPU pipeline: RGBA8/BGRA8 UNORM or SRGB color targets required");
    for (auto factor:{b.src_color_blendfactor,b.dst_color_blendfactor,b.src_alpha_blendfactor,b.dst_alpha_blendfactor})
        if (uint32_t(factor)>SDL_GPU_BLENDFACTOR_ONE_MINUS_CONSTANT_COLOR || (b.enable_blend && !factor))
            return SDL_SetError("GPU pipeline: invalid blend factor");
    if (uint32_t(b.color_blend_op)>SDL_GPU_BLENDOP_MAX || uint32_t(b.alpha_blend_op)>SDL_GPU_BLENDOP_MAX ||
        (b.enable_blend && (!b.color_blend_op || !b.alpha_blend_op ||
        !SDL_GPUPipelineAlphaFactor(b.src_alpha_blendfactor) || !SDL_GPUPipelineAlphaFactor(b.dst_alpha_blendfactor))) ||
        (b.color_write_mask & ~15u)) return SDL_SetError("GPU pipeline: invalid blend operation, alpha factor or write mask");
    out={}; out.format=f; auto & nb=out.blend_state;
    nb.enable_blend=b.enable_blend; nb.enable_color_write_mask=b.enable_color_write_mask;
    nb.color_write_mask=b.enable_color_write_mask ? b.color_write_mask : 15;
    nb.src_color_blendfactor=b.enable_blend ? b.src_color_blendfactor : SDL_GPU_BLENDFACTOR_ONE;
    nb.dst_color_blendfactor=b.enable_blend ? b.dst_color_blendfactor : SDL_GPU_BLENDFACTOR_ZERO;
    nb.src_alpha_blendfactor=b.enable_blend ? b.src_alpha_blendfactor : SDL_GPU_BLENDFACTOR_ONE;
    nb.dst_alpha_blendfactor=b.enable_blend ? b.dst_alpha_blendfactor : SDL_GPU_BLENDFACTOR_ZERO;
    nb.color_blend_op=b.enable_blend ? b.color_blend_op : SDL_GPU_BLENDOP_ADD;
    nb.alpha_blend_op=b.enable_blend ? b.alpha_blend_op : SDL_GPU_BLENDOP_ADD; return true;
}
inline uint64_t SDL_CreateGPUCheckedGraphicsPipeline(SDL_GPUDevice * device,uint64_t vertex,uint64_t fragment,
        const SDL_GPUGraphicsPipelineCreateInfo & info,const das::TArray<SDL_GPUVertexBufferDescription> & buffers,
        const das::TArray<SDL_GPUVertexAttribute> & attributes,const das::TArray<SDL_GPUColorTargetDescription> & colors) {
    if (!SDL_GPUTransferDevice(device) || !SDL_GPUTransferIDAvailable()) return 0;
    const auto * vs=SDL_GPUTransferFind(SDL_GPUOwnedShaders,device,vertex);
    const auto * fs=SDL_GPUTransferFind(SDL_GPUOwnedShaders,device,fragment);
    if (!vs || !fs) return 0;
    if (vs->info.stage!=SDL_GPU_SHADERSTAGE_VERTEX || fs->info.stage!=SDL_GPU_SHADERSTAGE_FRAGMENT) {
        SDL_SetError("GPU pipeline: shader stages do not match their roles"); return 0;
    }
    if (buffers.size>16 || attributes.size>16 || colors.size<1 || colors.size>4 ||
        (buffers.size && !buffers.data) || (attributes.size && !attributes.data) || !colors.data) {
        SDL_SetError("GPU pipeline: arrays require at most 16 buffers/attributes and 1..4 color targets"); return 0;
    }
    SDL_GPUOwnedGraphicsPipeline entry{}; entry.device=device;
    if (!SDL_GPUPipelineState(info,entry.info)) return 0;
    for (uint32_t i=0;i<buffers.size;++i) entry.buffers.push_back(buffers[i]);
    for (uint32_t i=0;i<attributes.size;++i) entry.attributes.push_back(attributes[i]);
    if (!SDL_GPUPipelineLayout(entry.buffers,entry.attributes)) return 0;
    // Pinned D3D12 indexes the description array with attribute.buffer_slot.
    std::sort(entry.buffers.begin(),entry.buffers.end(),[](const auto & a,const auto & b) { return a.slot<b.slot; });
    for (uint32_t i=0;i<colors.size;++i) {
        SDL_GPUColorTargetDescription color{}; if (!SDL_GPUPipelineColor(colors[i],color)) return 0;
        if (!SDL_GPUTextureSupportsFormat(device,color.format,SDL_GPU_TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) ||
            !SDL_GPUTextureSupportsSampleCount(device,color.format,entry.info.multisample_state.sample_count)) {
            SDL_SetError("GPU pipeline: color format/sample count unsupported"); return 0;
        }
        entry.colors.push_back(color);
    }
    const auto & target=entry.info.target_info;
    if (target.has_depth_stencil_target &&
        (!SDL_GPUTextureSupportsFormat(device,target.depth_stencil_format,SDL_GPU_TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) ||
        !SDL_GPUTextureSupportsSampleCount(device,target.depth_stencil_format,entry.info.multisample_state.sample_count))) {
        SDL_SetError("GPU pipeline: depth format/sample count unsupported"); return 0;
    }
    entry.vertexResources=vs->info; entry.fragmentResources=fs->info;
    auto native=entry.info; native.vertex_shader=vs->shader; native.fragment_shader=fs->shader;
    native.vertex_input_state.vertex_buffer_descriptions=entry.buffers.empty() ? nullptr : entry.buffers.data();
    native.vertex_input_state.num_vertex_buffers=uint32_t(entry.buffers.size());
    native.vertex_input_state.vertex_attributes=entry.attributes.empty() ? nullptr : entry.attributes.data();
    native.vertex_input_state.num_vertex_attributes=uint32_t(entry.attributes.size());
    native.target_info.color_target_descriptions=entry.colors.data(); native.target_info.num_color_targets=uint32_t(entry.colors.size());
    auto release=[device](SDL_GPUGraphicsPipeline * p) { SDL_ReleaseGPUGraphicsPipeline(device,p); };
    std::unique_ptr<SDL_GPUGraphicsPipeline,decltype(release)> pipeline(SDL_CreateGPUGraphicsPipeline(device,&native),release);
    if (!pipeline) return 0;
    entry.pipeline=pipeline.get(); const auto id=SDL_GPUNextResourceID++;
    SDL_GPUOwnedGraphicsPipelines.emplace(id,std::move(entry)); pipeline.release(); return id;
}
inline bool SDL_ReleaseGPUCheckedGraphicsPipeline(SDL_GPUDevice * device,uint64_t id) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUOwnedGraphicsPipelines,device,id); if (!entry) return false;
    SDL_ReleaseGPUGraphicsPipeline(device,entry->pipeline); SDL_GPUOwnedGraphicsPipelines.erase(id); return true;
}
inline bool SDL_GetGPUCheckedGraphicsPipelineInfo(SDL_GPUDevice * device,uint64_t id,SDL_GPUGraphicsPipelineCreateInfo & out) {
    out={}; auto * entry=SDL_GPUTransferFind(SDL_GPUOwnedGraphicsPipelines,device,id); if (!entry) return false;
    out=entry->info; return true;
}
inline void SDL_ReleaseGPUCheckedGraphicsPipelinesForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPUOwnedGraphicsPipelines.begin();it!=SDL_GPUOwnedGraphicsPipelines.end();) {
        if (it->second.device!=device) { ++it; continue; }
        SDL_ReleaseGPUGraphicsPipeline(device,it->second.pipeline); it=SDL_GPUOwnedGraphicsPipelines.erase(it);
    }
}
inline const bool SDL_GPUCheckedGraphicsPipelineCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPUCheckedGraphicsPipelinesForDevice);
