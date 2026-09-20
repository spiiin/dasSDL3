#pragma once
#include "sdl3_gpu_image.h"

// Plans own values, never native command buffers or resources. Resolve every ID
// again before acquiring a command. No script invocation during native recording.
enum class SDL_GPUPlanKind { Buffer, Texture, Mips, Blit, Label, Push, Pop };
struct SDL_GPUPlanOp {
    SDL_GPUPlanKind kind;
    uint64_t source=0, destination=0;
    das::uint2 sourceSub{}, destSub{};
    das::uint4 sourceRect{}, destRect{};
    uint32_t filter=0;
    std::string text;
};
struct SDL_GPUCommandPlan {
    SDL_GPUDevice * device;
    std::vector<SDL_GPUPlanOp> ops;
    uint32_t depth=0;
    bool consumed=false;
};
inline std::unordered_map<uint64_t,SDL_GPUCommandPlan> SDL_GPUCommandPlans;
inline SDL_GPUCommandPlan * SDL_GPUPlanOpen(SDL_GPUDevice * device,uint64_t id) {
    auto * plan=SDL_GPUTransferFind(SDL_GPUCommandPlans,device,id);
    if (plan && plan->consumed) { SDL_SetError("GPU plan: already consumed"); return nullptr; }
    return plan;
}
inline uint64_t SDL_CreateGPUCommandPlan(SDL_GPUDevice * device) {
    if (!SDL_GPUTransferDevice(device) || !SDL_GPUTransferIDAvailable()) return 0;
    const auto id=SDL_GPUNextPipeline++;
    SDL_GPUCommandPlans.emplace(id,SDL_GPUCommandPlan{device}); return id;
}
inline bool SDL_ReleaseGPUCommandPlan(SDL_GPUDevice * device,uint64_t id) {
    if (!SDL_GPUTransferFind(SDL_GPUCommandPlans,device,id)) return false;
    SDL_GPUCommandPlans.erase(id); return true;
}
struct SDL_GPUPlanResolved {
    SDL_GPUDataBuffer * sourceBuffer=nullptr, * destBuffer=nullptr;
    SDL_GPUTransferTexture * sourceTexture=nullptr, * destTexture=nullptr;
};
inline bool SDL_GPUPlanResolve(SDL_GPUDevice * device,const SDL_GPUPlanOp & op,SDL_GPUPlanResolved & r) {
    if (op.kind==SDL_GPUPlanKind::Label || op.kind==SDL_GPUPlanKind::Push || op.kind==SDL_GPUPlanKind::Pop) return true;
    if (op.kind==SDL_GPUPlanKind::Buffer) {
        r.sourceBuffer=SDL_GPUTransferFind(SDL_GPUDataBuffers,device,op.source);
        r.destBuffer=SDL_GPUTransferFind(SDL_GPUDataBuffers,device,op.destination);
        if (!r.sourceBuffer || !r.destBuffer) return false;
        if (op.source==op.destination || !r.sourceBuffer->valid || !r.destBuffer->valid)
            return SDL_SetError("GPU plan: distinct valid buffers required");
        return SDL_GPUTransferRange(r.sourceBuffer->size,op.sourceRect.x,op.sourceRect.z) &&
            SDL_GPUTransferRange(r.destBuffer->size,op.destRect.x,op.sourceRect.z);
    }
    r.sourceTexture=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,op.source);
    if (!r.sourceTexture) return false;
    auto & src=*r.sourceTexture;
    if (op.kind==SDL_GPUPlanKind::Mips) {
        if (!SDL_GPUImageFormat(src.format)) return false;
        if (!(src.usage&SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) || src.levels<2)
            return SDL_SetError("GPU plan: mipmaps require a multilevel color target");
        // Conservative: plans cannot repair invalid subresources.
        for (bool valid : src.valid) if (!valid) return SDL_SetError("GPU plan: invalid texture subresource");
        return true;
    }
    r.destTexture=SDL_GPUTransferFind(SDL_GPUTransferTextures,device,op.destination);
    if (!r.destTexture) return false;
    auto & dst=*r.destTexture;
    if (op.source==op.destination || src.format!=dst.format)
        return SDL_SetError("GPU plan: distinct matching textures required");
    SDL_GPUTextureFootprint footprint{};
    if (!SDL_GPUTextureSubregion(src,op.sourceSub,op.sourceRect,footprint) ||
        !SDL_GPUTextureSubregion(dst,op.destSub,op.destRect,footprint)) return false;
    if (!src.valid[op.sourceSub.y*src.levels+op.sourceSub.x] || !dst.valid[op.destSub.y*dst.levels+op.destSub.x])
        return SDL_SetError("GPU plan: invalid texture subresource");
    if (op.kind==SDL_GPUPlanKind::Blit && (!SDL_GPUImageFormat(src.format) ||
        !(dst.usage&SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) || op.filter>SDL_GPU_FILTER_LINEAR))
        return SDL_SetError("GPU plan: blit requires color target and nearest/linear filter");
    return true;
}
inline bool SDL_GPUPlanAppend(SDL_GPUDevice * device,uint64_t id,SDL_GPUPlanOp op) {
    auto * plan=SDL_GPUPlanOpen(device,id); if (!plan) return false;
    if (plan->ops.size()>=4096) return SDL_SetError("GPU plan: at most 4096 operations");
    SDL_GPUPlanResolved resolved{}; if (!SDL_GPUPlanResolve(device,op,resolved)) return false;
    if (op.kind==SDL_GPUPlanKind::Push && plan->depth>=64) return SDL_SetError("GPU plan: at most 64 debug groups");
    if (op.kind==SDL_GPUPlanKind::Pop && !plan->depth) return SDL_SetError("GPU plan: debug group underflow");
    const auto kind=op.kind;
    plan->ops.push_back(std::move(op));
    if (kind==SDL_GPUPlanKind::Push) ++plan->depth;
    if (kind==SDL_GPUPlanKind::Pop) --plan->depth;
    return true;
}
inline bool SDL_GPUPlanCopyBuffer(SDL_GPUDevice * device,uint64_t plan,uint64_t source,uint32_t offset,
        uint64_t destination,uint32_t destOffset,uint32_t size) {
    SDL_GPUPlanOp op{SDL_GPUPlanKind::Buffer}; op.source=source; op.destination=destination;
    op.sourceRect={offset,0,size,0}; op.destRect={destOffset,0,size,0};
    return SDL_GPUPlanAppend(device,plan,std::move(op));
}
inline bool SDL_GPUPlanCopyTexture(SDL_GPUDevice * device,uint64_t plan,uint64_t source,das::uint2 sub,das::uint4 rect,
        uint64_t destination,das::uint2 destSub,das::uint2 origin) {
    SDL_GPUPlanOp op{SDL_GPUPlanKind::Texture}; op.source=source; op.destination=destination;
    op.sourceSub=sub; op.sourceRect=rect; op.destSub=destSub; op.destRect={origin.x,origin.y,rect.z,rect.w};
    return SDL_GPUPlanAppend(device,plan,std::move(op));
}
inline bool SDL_GPUPlanMipmaps(SDL_GPUDevice * device,uint64_t plan,uint64_t texture) {
    SDL_GPUPlanOp op{SDL_GPUPlanKind::Mips}; op.source=texture;
    return SDL_GPUPlanAppend(device,plan,std::move(op));
}
inline bool SDL_GPUPlanBlit(SDL_GPUDevice * device,uint64_t plan,uint64_t source,das::uint2 sub,das::uint4 rect,
        uint64_t destination,das::uint2 destSub,das::uint4 destRect,uint32_t filter) {
    SDL_GPUPlanOp op{SDL_GPUPlanKind::Blit}; op.source=source; op.destination=destination;
    op.sourceSub=sub; op.sourceRect=rect; op.destSub=destSub; op.destRect=destRect; op.filter=filter;
    return SDL_GPUPlanAppend(device,plan,std::move(op));
}
inline bool SDL_GPUPlanText(SDL_GPUDevice * device,uint64_t plan,const char * text,SDL_GPUPlanKind kind) {
    if (!text || SDL_strnlen(text,4097)>4096) return SDL_SetError("GPU plan: text must be at most 4096 bytes");
    SDL_GPUPlanOp op{kind}; op.text=text; return SDL_GPUPlanAppend(device,plan,std::move(op));
}
inline bool SDL_GPUPlanLabel(SDL_GPUDevice * device,uint64_t plan,const char * text) {
    return SDL_GPUPlanText(device,plan,text,SDL_GPUPlanKind::Label);
}
// Pinned SDL 3.2.18 calls D3D12 BeginEvent with unsupported metadata 0.
// The D3D12 debug layer reports CORRUPTED_PARAMETER2 and raises 0x87a.
// Reject before recording; never suppress validation or silently omit a group.
inline int SDL_GPUPlanDebugGroupsSupported(SDL_GPUDevice * device) {
    if (!SDL_GPUTransferDevice(device)) return -1;
    return SDL_strcmp(SDL_GetGPUDeviceDriver(device),"direct3d12")==0 ? 0 : 1;
}
inline bool SDL_GPUPlanPushGroup(SDL_GPUDevice * device,uint64_t plan,const char * text) {
    const int supported=SDL_GPUPlanDebugGroupsSupported(device);
    if (supported<0) return false;
    if (!supported) return SDL_SetError("GPU plan: debug groups unavailable on pinned SDL D3D12; labels are supported");
    return SDL_GPUPlanText(device,plan,text,SDL_GPUPlanKind::Push);
}
inline bool SDL_GPUPlanPopGroup(SDL_GPUDevice * device,uint64_t plan) {
    return SDL_GPUPlanAppend(device,plan,SDL_GPUPlanOp{SDL_GPUPlanKind::Pop});
}
// Injection is native/test-only; no script pointer or callback crosses recording.
struct SDL_GPUPlanAPI {
    decltype(&SDL_AcquireGPUCommandBuffer) acquire=SDL_AcquireGPUCommandBuffer;
    decltype(&SDL_BeginGPUCopyPass) begin=SDL_BeginGPUCopyPass;
    decltype(&SDL_SubmitGPUCommandBuffer) submit=SDL_SubmitGPUCommandBuffer;
    decltype(&SDL_CancelGPUCommandBuffer) cancel=SDL_CancelGPUCommandBuffer;
};
inline bool SDL_SubmitGPUCommandPlanWithAPI(SDL_GPUDevice * device,uint64_t id,const SDL_GPUPlanAPI & api) {
    auto * plan=SDL_GPUPlanOpen(device,id); if (!plan) return false;
    if (plan->depth) return SDL_SetError("GPU plan: unclosed debug groups");
    std::vector<SDL_GPUPlanResolved> resolved(plan->ops.size());
    for (size_t i=0;i<plan->ops.size();++i)
        if (!SDL_GPUPlanResolve(device,plan->ops[i],resolved[i])) return false;
    // All allocations, strings and resource checks precede acquisition.
    plan->consumed=true;
    auto * command=api.acquire(device); if (!command) return false;
    uint32_t depth=0;
    for (size_t i=0;i<plan->ops.size();++i) {
        const auto & op=plan->ops[i]; const auto & r=resolved[i];
        if (op.kind==SDL_GPUPlanKind::Label) { SDL_InsertGPUDebugLabel(command,op.text.c_str()); continue; }
        if (op.kind==SDL_GPUPlanKind::Push) { SDL_PushGPUDebugGroup(command,op.text.c_str()); ++depth; continue; }
        if (op.kind==SDL_GPUPlanKind::Pop) { SDL_PopGPUDebugGroup(command); --depth; continue; }
        if (op.kind==SDL_GPUPlanKind::Mips) { SDL_GenerateMipmapsForGPUTexture(command,r.sourceTexture->texture); continue; }
        if (op.kind==SDL_GPUPlanKind::Blit) {
            SDL_GPUBlitInfo info{};
            info.source=SDL_GPUImageRegion(r.sourceTexture->texture,op.sourceSub,op.sourceRect);
            info.destination=SDL_GPUImageRegion(r.destTexture->texture,op.destSub,op.destRect);
            info.load_op=SDL_GPU_LOADOP_LOAD; info.filter=SDL_GPUFilter(op.filter);
            SDL_BlitGPUTexture(command,&info); continue;
        }
        // Separate passes establish barriers for dependent copies (A->B->C).
        auto * pass=api.begin(command);
        if (!pass) {
            const std::string error=SDL_GetError();
            while (depth) { SDL_PopGPUDebugGroup(command); --depth; }
            api.cancel(command); SDL_SetError("%s",error.c_str()); return false;
        }
        if (op.kind==SDL_GPUPlanKind::Buffer) {
            SDL_GPUBufferLocation src{r.sourceBuffer->buffer,op.sourceRect.x}, dst{r.destBuffer->buffer,op.destRect.x};
            SDL_CopyGPUBufferToBuffer(pass,&src,&dst,op.sourceRect.z,false);
        } else {
            SDL_GPUTextureLocation src{},dst{};
            src.texture=r.sourceTexture->texture; src.mip_level=op.sourceSub.x; src.layer=op.sourceSub.y;
            src.x=op.sourceRect.x; src.y=op.sourceRect.y;
            dst.texture=r.destTexture->texture; dst.mip_level=op.destSub.x; dst.layer=op.destSub.y;
            dst.x=op.destRect.x; dst.y=op.destRect.y;
            const auto rect=SDL_GPUTextureNativeRect(device,r.sourceTexture->blockWidth,op.sourceRect);
            SDL_CopyGPUTextureToTexture(pass,&src,&dst,rect.z,rect.w,1,false);
        }
        SDL_EndGPUCopyPass(pass);
    }
    const bool ok=api.submit(command); // Consumed even if submission fails.
    if (!ok) for (size_t i=0;i<plan->ops.size();++i) {
        const auto & op=plan->ops[i]; const auto & r=resolved[i];
        if (r.destBuffer) r.destBuffer->valid=false;
        if (r.destTexture) r.destTexture->valid[op.destSub.y*r.destTexture->levels+op.destSub.x]=false;
        if (op.kind==SDL_GPUPlanKind::Mips)
            for (uint32_t layer=0;layer<r.sourceTexture->layers;++layer)
                for (uint32_t mip=1;mip<r.sourceTexture->levels;++mip) r.sourceTexture->valid[layer*r.sourceTexture->levels+mip]=false;
    }
    return ok;
}
inline bool SDL_SubmitGPUCommandPlan(SDL_GPUDevice * device,uint64_t id) {
    return SDL_SubmitGPUCommandPlanWithAPI(device,id,SDL_GPUPlanAPI{});
}
inline void SDL_ReleaseGPUCommandPlansForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPUCommandPlans.begin();it!=SDL_GPUCommandPlans.end();)
        if (it->second.device==device) it=SDL_GPUCommandPlans.erase(it); else ++it;
}
inline const bool SDL_GPUCommandPlanCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPUCommandPlansForDevice);
