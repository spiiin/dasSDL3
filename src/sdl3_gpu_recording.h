#pragma once
#include "sdl3_gpu_pipeline.h"
#include "sdl3_gpu_index_buffer.h"
#include "sdl3_gpu_sampled.h"
#include "sdl3_gpu_image.h"

// Checked live SDL handles. No operation list, deferred draw or uniform snapshot.
struct SDL_GPURecording {
    SDL_GPUDevice * device;
    SDL_GPUCommandBuffer * command=nullptr;
    uint64_t pass=0;
    bool uniforms[2][4]{};
    struct Write { uint64_t texture; das::uint2 sub; };
    std::vector<Write> writes;
};
struct SDL_GPURecordingPass {
    SDL_GPUDevice * device;
    uint64_t command=0, target=0, pipeline=0, index=0;
    SDL_GPURenderPass * pass=nullptr;
    das::uint2 sub{};
    uint32_t width=0,height=0;
    std::array<uint64_t,16> vertices{};
    std::array<uint32_t,16> offsets{};
    struct Sampled { std::array<uint64_t,16> textures{}, samplers{}; size_t count=0; };
    std::array<Sampled,2> sampled;
};
inline std::unordered_map<uint64_t,SDL_GPURecording> SDL_GPURecordings;
inline std::unordered_map<uint64_t,SDL_GPURecordingPass> SDL_GPURecordingPasses;
inline SDL_GPURecording * SDL_GPURecordingFind(SDL_GPUDevice * device,uint64_t id) {
    return SDL_GPUTransferFind(SDL_GPURecordings,device,id);
}
inline SDL_GPURecordingPass * SDL_GPURecordingPassFind(SDL_GPUDevice * device,uint64_t id) {
    return SDL_GPUTransferFind(SDL_GPURecordingPasses,device,id);
}
inline uint64_t SDL_AcquireGPUCommandBufferChecked(SDL_GPUDevice * device) {
    if (!SDL_GPUTransferDevice(device) || !SDL_GPUTransferIDAvailable()) return 0;
    const auto id=SDL_GPUNextResourceID++;
    auto & entry=SDL_GPURecordings.emplace(id,SDL_GPURecording{device}).first->second;
    entry.command=SDL_AcquireGPUCommandBuffer(device);
    if (!entry.command) { SDL_GPURecordings.erase(id); return 0; }
    return id;
}
inline bool SDL_GPURecordingColor(const SDL_FColor & c) {
    return std::isfinite(c.r) && std::isfinite(c.g) && std::isfinite(c.b) && std::isfinite(c.a) &&
        c.r>=0 && c.r<=1 && c.g>=0 && c.g<=1 && c.b>=0 && c.b<=1 && c.a>=0 && c.a<=1;
}
inline uint64_t SDL_BeginGPURenderPassChecked(SDL_GPUDevice * device,uint64_t command,uint64_t target,
        das::uint2 sub,SDL_GPULoadOp load,const SDL_FColor & clear) {
    auto * c=SDL_GPURecordingFind(device,command); if (!c) return 0;
    auto * t=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,target); if (!t) return 0;
    if (c->pass || !SDL_GPUTransferIDAvailable() || !(t->usage&SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) ||
        !SDL_GPUImageFormat(t->format) || sub.x>=t->levels || sub.y>=t->layers ||
        !t->valid[sub.y*t->levels+sub.x] || !SDL_GPURecordingColor(clear) ||
        (load!=SDL_GPU_LOADOP_CLEAR && load!=SDL_GPU_LOADOP_LOAD)) {
        SDL_SetError("GPU recording: no active pass, valid color target, CLEAR/LOAD and normalized clear required"); return 0;
    }
    // Allocate bookkeeping before the native pass begins.
    c->writes.push_back({target,sub});
    const auto id=SDL_GPUNextResourceID++;
    auto & p=SDL_GPURecordingPasses.emplace(id,SDL_GPURecordingPass{device}).first->second;
    p.command=command; p.target=target; p.sub=sub;
    p.width=SDL_GPUTextureLevelSize(t->width,sub.x); p.height=SDL_GPUTextureLevelSize(t->height,sub.x);
    SDL_GPUColorTargetInfo info{}; info.texture=t->texture; info.mip_level=sub.x; info.layer_or_depth_plane=sub.y;
    info.load_op=load; info.store_op=SDL_GPU_STOREOP_STORE; info.clear_color=clear;
    p.pass=SDL_BeginGPURenderPass(c->command,&info,1,nullptr);
    if (!p.pass) { SDL_GPURecordingPasses.erase(id); c->writes.pop_back(); return 0; }
    c->pass=id; return id;
}
inline bool SDL_EndGPURenderPassChecked(SDL_GPUDevice * device,uint64_t pass) {
    auto * p=SDL_GPURecordingPassFind(device,pass); if (!p) return false;
    auto * c=SDL_GPURecordingFind(device,p->command); if (!c) return false;
    SDL_EndGPURenderPass(p->pass); c->pass=0; SDL_GPURecordingPasses.erase(pass); return true;
}
inline bool SDL_CancelGPUCommandBufferChecked(SDL_GPUDevice * device,uint64_t command) {
    auto * c=SDL_GPURecordingFind(device,command); if (!c) return false;
    if (c->pass) return SDL_SetError("GPU recording: end render pass before cancel");
    const bool ok=SDL_CancelGPUCommandBuffer(c->command);
    SDL_GPURecordings.erase(command); return ok;
}
inline bool SDL_SubmitGPUCommandBufferCheckedWithAPI(SDL_GPUDevice * device,uint64_t command,
        decltype(&SDL_SubmitGPUCommandBuffer) submit) {
    auto * c=SDL_GPURecordingFind(device,command); if (!c) return false;
    if (c->pass) return SDL_SetError("GPU recording: end render pass before submit");
    const bool ok=submit(c->command);
    if (!ok) for (const auto & write:c->writes) {
        const auto it=SDL_GPUTransferTextures.find(write.texture);
        if (it!=SDL_GPUTransferTextures.end() && it->second.device==device)
            it->second.valid[write.sub.y*it->second.levels+write.sub.x]=false;
    }
    SDL_GPURecordings.erase(command); return ok;
}
inline bool SDL_SubmitGPUCommandBufferChecked(SDL_GPUDevice * device,uint64_t command) {
    return SDL_SubmitGPUCommandBufferCheckedWithAPI(device,command,SDL_SubmitGPUCommandBuffer);
}
inline bool SDL_GPURecordingDiscard(SDL_GPUDevice * device,uint64_t command) {
    if (!SDL_GPUTransferDevice(device)) return false;
    auto it=SDL_GPURecordings.find(command);
    if (it==SDL_GPURecordings.end()) return true; // Explicit submit/cancel already consumed it.
    if (it->second.device!=device) return SDL_SetError("GPU recording: foreign device");
    if (it->second.pass && !SDL_EndGPURenderPassChecked(device,it->second.pass)) return false;
    return SDL_CancelGPUCommandBufferChecked(device,command);
}
inline bool SDL_BindGPUGraphicsPipelineChecked(SDL_GPUDevice * device,uint64_t pass,uint64_t pipeline) {
    auto * p=SDL_GPURecordingPassFind(device,pass); if (!p) return false;
    auto * pipelineInfo=SDL_GPUTransferFind(SDL_GPUOwnedGraphicsPipelines,device,pipeline);
    auto * target=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,p->target);
    if (!pipelineInfo || !target) return false;
    if (pipelineInfo->colors.size()!=1 || uint32_t(pipelineInfo->colors[0].format)!=target->format ||
        pipelineInfo->info.target_info.has_depth_stencil_target ||
        pipelineInfo->info.multisample_state.sample_count!=SDL_GPU_SAMPLECOUNT_1 ||
        pipelineInfo->vertexResources.num_storage_buffers || pipelineInfo->vertexResources.num_storage_textures ||
        pipelineInfo->fragmentResources.num_storage_buffers || pipelineInfo->fragmentResources.num_storage_textures)
        return SDL_SetError("GPU recording: matching single color/sample 1 pipeline without depth/storage required");
    SDL_BindGPUGraphicsPipeline(p->pass,pipelineInfo->pipeline); p->pipeline=pipeline;
    return true;
}
inline bool SDL_SetGPUViewportChecked(SDL_GPUDevice * device,uint64_t pass,const SDL_GPUViewport & v) {
    auto * p=SDL_GPURecordingPassFind(device,pass); if (!p) return false;
    if (!std::isfinite(v.x) || !std::isfinite(v.y) || !std::isfinite(v.w) || !std::isfinite(v.h) ||
        !std::isfinite(v.min_depth) || !std::isfinite(v.max_depth) || v.x<0 || v.y<0 || v.w<=0 || v.h<=0 ||
        v.x>p->width || v.y>p->height || v.w>p->width-v.x || v.h>p->height-v.y ||
        v.min_depth<0 || v.max_depth>1 || v.min_depth>v.max_depth)
        return SDL_SetError("GPU recording: viewport must fit target and depth must be ordered in 0..1");
    SDL_SetGPUViewport(p->pass,&v); return true;
}
inline bool SDL_SetGPUScissorChecked(SDL_GPUDevice * device,uint64_t pass,das::uint4 s) {
    auto * p=SDL_GPURecordingPassFind(device,pass); if (!p) return false;
    if (!s.z || !s.w || s.x>p->width || s.y>p->height || s.z>p->width-s.x || s.w>p->height-s.y)
        return SDL_SetError("GPU recording: nonempty scissor must fit target");
    const SDL_Rect rect{int(s.x),int(s.y),int(s.z),int(s.w)}; SDL_SetGPUScissor(p->pass,&rect); return true;
}
inline bool SDL_SetGPUBlendConstantsChecked(SDL_GPUDevice * device,uint64_t pass,const SDL_FColor & color) {
    auto * p=SDL_GPURecordingPassFind(device,pass); if (!p) return false;
    if (!SDL_GPURecordingColor(color)) return SDL_SetError("GPU recording: normalized blend color required");
    SDL_SetGPUBlendConstants(p->pass,color); return true;
}
inline bool SDL_BindGPUVertexBuffersChecked(SDL_GPUDevice * device,uint64_t pass,uint32_t first,
        const das::TArray<uint64_t> & buffers,const das::TArray<uint32_t> & offsets) {
    auto * p=SDL_GPURecordingPassFind(device,pass); if (!p) return false;
    if (first>=16 || !buffers.size || buffers.size>16-first || offsets.size!=buffers.size || !buffers.data || !offsets.data)
        return SDL_SetError("GPU recording: nonempty matching vertex arrays fitting 16 slots required");
    const auto * ids=reinterpret_cast<const uint64_t *>(buffers.data);
    const auto * positions=reinterpret_cast<const uint32_t *>(offsets.data);
    std::array<SDL_GPUBufferBinding,16> bindings{};
    for (size_t i=0;i<buffers.size;++i) {
        auto * b=SDL_GPUTransferFind(SDL_GPUDataBuffers,device,ids[i]); if (!b) return false;
        if (!(b->usage&SDL_GPU_BUFFERUSAGE_VERTEX) || !b->valid || positions[i]%4 || positions[i]>=b->size)
            return SDL_SetError("GPU recording: valid VERTEX buffer and aligned in-range offset required");
        bindings[i]={b->buffer,positions[i]};
    }
    SDL_BindGPUVertexBuffers(p->pass,first,bindings.data(),uint32_t(buffers.size));
    for (size_t i=0;i<buffers.size;++i) { p->vertices[first+i]=ids[i]; p->offsets[first+i]=positions[i]; }
    return true;
}
inline bool SDL_BindGPUIndexBufferChecked(SDL_GPUDevice * device,uint64_t pass,uint64_t index) {
    auto * p=SDL_GPURecordingPassFind(device,pass); if (!p) return false;
    auto * b=SDL_GPUTransferFind(SDL_GPUCheckedIndexBuffers,device,index); if (!b) return false;
    const SDL_GPUBufferBinding binding{b->buffer,0}; SDL_BindGPUIndexBuffer(p->pass,&binding,b->element);
    p->index=index; return true;
}
inline bool SDL_BindGPUSamplersChecked(SDL_GPUDevice * device,uint64_t pass,SDL_GPUShaderStage stage,
        const das::TArray<uint64_t> & textures,const das::TArray<uint64_t> & samplers) {
    auto * p=SDL_GPURecordingPassFind(device,pass); if (!p) return false;
    if (uint32_t(stage)>1 || !textures.size || textures.size>16 || textures.size!=samplers.size || !textures.data || !samplers.data)
        return SDL_SetError("GPU recording: valid stage and 1..16 matching texture/sampler pairs required");
    SDL_GPURecordingPass::Sampled next;
    const auto * t=reinterpret_cast<const uint64_t *>(textures.data), * s=reinterpret_cast<const uint64_t *>(samplers.data);
    next.count=size_t(textures.size);
    std::copy_n(t,next.count,next.textures.data()); std::copy_n(s,next.count,next.samplers.data());
    std::array<SDL_GPUTextureSamplerBinding,16> bindings{};
    if (!SDL_GPUValidateSampledTextures(device,next.textures.data(),next.samplers.data(),next.count,p->target,bindings.data())) return false;
    if (stage==SDL_GPU_SHADERSTAGE_VERTEX) SDL_BindGPUVertexSamplers(p->pass,0,bindings.data(),uint32_t(textures.size));
    else SDL_BindGPUFragmentSamplers(p->pass,0,bindings.data(),uint32_t(textures.size));
    p->sampled[stage]=std::move(next); return true;
}
inline bool SDL_PushGPUUniformBytesChecked(SDL_GPUDevice * device,uint64_t command,SDL_GPUShaderStage stage,
        uint32_t slot,const das::TArray<uint8_t> & bytes) {
    auto * c=SDL_GPURecordingFind(device,command); if (!c) return false;
    if (uint32_t(stage)>1 || slot>=4 || !bytes.size || bytes.size>16384 || bytes.size%16 || !bytes.data)
        return SDL_SetError("GPU recording: valid stage/slot and 16-aligned uniform bytes in 16..16384 required");
    if (stage==SDL_GPU_SHADERSTAGE_VERTEX) SDL_PushGPUVertexUniformData(c->command,slot,bytes.data,uint32_t(bytes.size));
    else SDL_PushGPUFragmentUniformData(c->command,slot,bytes.data,uint32_t(bytes.size));
    c->uniforms[stage][slot]=true; return true;
}
inline bool SDL_PushGPUUniformVectorsChecked(SDL_GPUDevice * device,uint64_t command,SDL_GPUShaderStage stage,
        uint32_t slot,const das::TArray<das::float4> & values) {
    static_assert(sizeof(das::float4)==16);
    if (values.size>1024) return SDL_SetError("GPU recording: at most 1024 float4 values");
    das::TArray<uint8_t> bytes{}; bytes.data=values.data; bytes.size=values.size*16;
    return SDL_PushGPUUniformBytesChecked(device,command,stage,slot,bytes);
}
inline bool SDL_GPURecordingDrawCheck(SDL_GPUDevice * device,SDL_GPURecordingPass & p,uint32_t count,
        uint32_t instances,uint32_t first,int32_t base,bool indexed) {
    auto * c=SDL_GPURecordingFind(device,p.command);
    auto * pipeline=SDL_GPUTransferFind(SDL_GPUOwnedGraphicsPipelines,device,p.pipeline);
    auto * target=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,p.target);
    if (!c || !pipeline || !target) return false;
    if (!target->valid[p.sub.y*target->levels+p.sub.x] || !count || !instances || uint64_t(count)*instances>1048576)
        return SDL_SetError("GPU recording: valid target and 1..1048576 vertex invocations required");
    const SDL_GPUShaderCreateInfo * shaders[]={&pipeline->vertexResources,&pipeline->fragmentResources};
    for (size_t stage=0;stage<2;++stage) {
        if (shaders[stage]->num_samplers!=p.sampled[stage].count ||
            !SDL_GPUValidateSampledTextures(device,p.sampled[stage].textures.data(),p.sampled[stage].samplers.data(),p.sampled[stage].count,p.target,nullptr))
            return SDL_SetError("GPU recording: live sampler bindings must match shader counts");
        for (size_t slot=0;slot<shaders[stage]->num_uniform_buffers;++slot)
            if (!c->uniforms[stage][slot]) return SDL_SetError("GPU recording: declared uniform slot has not been pushed");
    }
    uint64_t vertices=uint64_t(first)+count;
    if (indexed) {
        auto * b=SDL_GPUTransferFind(SDL_GPUCheckedIndexBuffers,device,p.index); if (!b) return false;
        if (first>b->indices.size() || count>b->indices.size()-first)
            return SDL_SetError("GPU recording: index range exceeds buffer");
        vertices=0;
        for (uint32_t i=0;i<count;++i) {
            const int64_t vertex=int64_t(b->indices[first+i])+base;
            if (vertex<0 || vertex>UINT32_MAX) return SDL_SetError("GPU recording: index plus base vertex out of range");
            vertices=std::max(vertices,uint64_t(vertex)+1);
        }
    }
    bool perVertex=false;
    for (size_t i=0;i<pipeline->buffers.size();++i) {
        auto * b=SDL_GPUTransferFind(SDL_GPUDataBuffers,device,p.vertices[i]); if (!b) return false;
        const auto & layout=pipeline->buffers[i]; const bool instanced=layout.input_rate==SDL_GPU_VERTEXINPUTRATE_INSTANCE;
        perVertex=perVertex || !instanced;
        const uint64_t required=uint64_t(layout.pitch)*(instanced ? instances : vertices);
        if (!b->valid || p.offsets[i]>b->size || required>b->size-p.offsets[i])
            return SDL_SetError("GPU recording: complete vertex/instance strides required");
    }
    if (indexed && !perVertex) return SDL_SetError("GPU recording: indexed draw requires a per-vertex buffer");
    return true;
}
inline bool SDL_DrawGPUPrimitivesChecked(SDL_GPUDevice * device,uint64_t pass,uint32_t vertices,uint32_t instances,uint32_t first) {
    auto * p=SDL_GPURecordingPassFind(device,pass); if (!p || !SDL_GPURecordingDrawCheck(device,*p,vertices,instances,first,0,false)) return false;
    SDL_DrawGPUPrimitives(p->pass,vertices,instances,first,0); return true;
}
inline bool SDL_DrawGPUIndexedPrimitivesChecked(SDL_GPUDevice * device,uint64_t pass,uint32_t indices,uint32_t instances,uint32_t first,int32_t base) {
    auto * p=SDL_GPURecordingPassFind(device,pass); if (!p || !SDL_GPURecordingDrawCheck(device,*p,indices,instances,first,base,true)) return false;
    SDL_DrawGPUIndexedPrimitives(p->pass,indices,instances,first,base,0); return true;
}
inline void SDL_ReleaseGPURecordingsForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPURecordings.begin();it!=SDL_GPURecordings.end();) {
        if (it->second.device!=device) { ++it; continue; }
        const auto id=it->first; ++it; SDL_GPURecordingDiscard(device,id);
    }
}
// End/cancel recordings before releasing any native resources used by them.
inline const bool SDL_GPURecordingCleanupRegistered=[] {
    SDL_GPUDeviceCleanups.insert(SDL_GPUDeviceCleanups.begin(),SDL_ReleaseGPURecordingsForDevice); return true;
}();
