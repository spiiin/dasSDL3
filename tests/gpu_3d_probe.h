#pragma once
#include "sdl3_gpu_3d.h"
#include "gpu_triangle_probe.h"
#include "gpu_probe.h"
namespace sdl3_test {
inline int gpu_3d_meshes() { return int(SDL_GPU3DMeshes.size()); }
inline int gpu_3d_depths() { int count=0; for (const auto & m:SDL_GPU3DMeshes) if (m.second.depth) ++count; return count; }
inline bool gpu_3d_guards() {
    if (!SDL_GPU3DSizes(6,6,6) || SDL_GPU3DSizes(0,0,0) || SDL_GPU3DSizes(6,5,6) ||
        SDL_GPU3DSizes(UINT32_MAX,UINT32_MAX,3) || SDL_GPU3DSizes(6,6,UINT32_MAX)) return false;
    SDL_GPU3DMatrix matrix{}; matrix.c[1][2]=std::numeric_limits<float>::infinity();
    if (SDL_GPU3DMatrixValid(matrix)) return false;
    matrix.c[1][2]=std::numeric_limits<float>::quiet_NaN(); if (SDL_GPU3DMatrixValid(matrix)) return false;
    // A target preparation failure after swapchain acquisition must submit, never cancel.
    GPUFake::scenario=0; GPUFake::trace.clear(); uint32_t w=9,h=9;
    const int result=SDL_GPUFrameWithTarget<GPUFake>(GPUFake::handle<SDL_GPUDevice>(),GPUFake::handle<SDL_Window>(),
        {0,0,0,1},w,h,[](SDL_GPURenderPass *,SDL_GPUCommandBuffer *) { GPUFake::trace+='R'; },
        [](SDL_GPUCommandBuffer *,const SDL_GPUColorTargetInfo &,uint32_t,uint32_t)->SDL_GPURenderPass * {
            SDL_SetError("depth-prepare-failure"); GPUFake::trace+='D'; return nullptr;
        });
    return result==-1 && !w && !h && GPUFake::trace=="AWDS" && std::string(SDL_GetError()).find("depth-prepare-failure")!=std::string::npos;
}
inline uint64_t gpu_3d_offscreen(SDL_GPUDevice * device,const das::TArray<das::float4> & positions,
        const das::TArray<das::float4> & colors,const das::TArray<uint32_t> & indices,
        const char * vs,const char * fs,uint32_t format) {
    return SDL_CreateGPU3DForFormat(device,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,positions,colors,indices,vs,fs,format);
}
inline bool gpu_3d_foreign(SDL_GPUDevice * device,uint64_t id) {
    static char token; auto * other=reinterpret_cast<SDL_GPUDevice *>(&token);
    return !SDL_FindGPU3D(other,id) && !SDL_ReleaseGPU3DMesh(other,id) &&
        !SDL_FindGPUMesh(device,id) && !SDL_FindGPUPipeline(device,id) && SDL_FindGPU3D(device,id);
}
inline bool gpu_3d_depth_contracts(SDL_GPUDevice * device,uint64_t id) {
    auto * m=SDL_FindGPU3D(device,id); if (!m || !SDL_EnsureGPU3DDepth(*m,64,64)) return false;
    auto * first=m->depth;
    if (!SDL_EnsureGPU3DDepth(*m,64,64) || first!=m->depth) return SDL_SetError("depth cache not reused");
    SDL_TestGPU3DFailDepth=true; const bool failed=!SDL_EnsureGPU3DDepth(*m,96,48); SDL_TestGPU3DFailDepth=false;
    if (!failed || m->depth!=first || m->width!=64 || m->height!=64) return SDL_SetError("depth allocation failure lost old target");
    if (SDL_EnsureGPU3DDepth(*m,0,64) || SDL_EnsureGPU3DDepth(*m,UINT32_MAX,64) || m->depth!=first) return false;
    return SDL_EnsureGPU3DDepth(*m,96,48) && m->depth!=first && m->width==96 && m->height==48;
}
inline bool gpu_3d_depth_matches(SDL_GPUDevice * device,SDL_Window * window,uint64_t id) {
    auto * m=SDL_FindGPU3D(device,id); int w=0,h=0;
    return m && SDL_GetWindowSizeInPixels(window,&w,&h) && m->depth && m->width==uint32_t(w) && m->height==uint32_t(h);
}
inline bool gpu_3d_pixels(SDL_GPUDevice * device,uint64_t id,das::float4 a,das::float4 b,das::float4 c,das::float4 d) {
    auto * m=SDL_FindGPU3D(device,id); if (!m || m->count!=6 || m->colorFormat!=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) return false;
    const auto matrix=SDL_GPU3DColumns(a,b,c,d); if (!SDL_GPU3DMatrixValid(matrix)) return false;
    GPUReadback r{device};
    SDL_GPUTextureCreateInfo ti{}; ti.type=SDL_GPU_TEXTURETYPE_2D; ti.format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    ti.usage=SDL_GPU_TEXTUREUSAGE_COLOR_TARGET; ti.width=ti.height=64; ti.layer_count_or_depth=ti.num_levels=1; ti.sample_count=SDL_GPU_SAMPLECOUNT_1;
    r.texture=SDL_CreateGPUTexture(device,&ti); if (!r.texture) return false;
    SDL_GPUTransferBufferCreateInfo transfer{}; transfer.usage=SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD; transfer.size=64*64*4;
    r.transfer=SDL_CreateGPUTransferBuffer(device,&transfer); if (!r.transfer) return false;
    r.command=SDL_AcquireGPUCommandBuffer(device); if (!r.command) return false;
    SDL_GPUColorTargetInfo target{}; target.texture=r.texture; target.clear_color={0,0,0,1}; target.load_op=SDL_GPU_LOADOP_CLEAR; target.store_op=SDL_GPU_STOREOP_STORE;
    auto * pass=SDL_BeginGPU3DPass(r.command,target,*m,64,64); if (!pass) return false;
    SDL_RecordGPU3D(pass,r.command,*m,matrix); SDL_EndGPURenderPass(pass);
    auto * copy=SDL_BeginGPUCopyPass(r.command); if (!copy) return false;
    SDL_GPUTextureRegion source{}; source.texture=r.texture; source.w=source.h=64; source.d=1;
    SDL_GPUTextureTransferInfo dest{}; dest.transfer_buffer=r.transfer; dest.pixels_per_row=dest.rows_per_layer=64;
    SDL_DownloadFromGPUTexture(copy,&source,&dest); SDL_EndGPUCopyPass(copy);
    r.fence=SDL_SubmitGPUCommandBufferAndAcquireFence(r.command); r.command=nullptr; r.submitted=true;
    if (!r.fence || !SDL_WaitForGPUFences(device,true,&r.fence,1)) return false;
    auto * bytes=static_cast<const Uint8 *>(SDL_MapGPUTransferBuffer(device,r.transfer,false)); if (!bytes) return false;
    std::array<Uint8,64*64*4> pixels{}; std::memcpy(pixels.data(),bytes,pixels.size()); SDL_UnmapGPUTransferBuffer(device,r.transfer);
    // Independent CPU projection + barycentric depth selection. Both triangle orders use this same reference.
    const double input[6][4]={{-.8,-.7,.25,1},{.8,-.7,.25,1},{0,.8,.25,1},
        {-.6,-.6,.75,1},{.8,-.6,.75,1},{.1,.7,.75,1}};
    double projected[6][3]{};
    for (int v=0;v<6;++v) {
        double clip[4]{};
        for (int row=0;row<4;++row) for (int col=0;col<4;++col) clip[row]+=matrix.c[col][row]*input[v][col];
        if (clip[3]<=0) return SDL_SetError("3D fixture: reference geometry behind camera");
        projected[v][0]=(clip[0]/clip[3]+1)*32; projected[v][1]=(1-clip[1]/clip[3])*32; projected[v][2]=clip[2]/clip[3];
    }
    int checked=0,colored=0;
    for (int y=0;y<64;++y) for (int x=0;x<64;++x) {
        double depth=1; int hit=-1; bool edge=false;
        for (int t=0;t<2;++t) {
            const auto * p=projected[t*3]; const auto * q=projected[t*3+1]; const auto * s=projected[t*3+2];
            const double den=(q[1]-s[1])*(p[0]-s[0])+(s[0]-q[0])*(p[1]-s[1]);
            if (std::abs(den)<1e-8) return SDL_SetError("3D fixture: degenerate reference triangle");
            const double u=((q[1]-s[1])*(x+.5-s[0])+(s[0]-q[0])*(y+.5-s[1]))/den;
            const double v=((s[1]-p[1])*(x+.5-s[0])+(p[0]-s[0])*(y+.5-s[1]))/den;
            const double w=1-u-v;
            if (u>-.02 && v>-.02 && w>-.02 && (std::abs(u)<.02 || std::abs(v)<.02 || std::abs(w)<.02)) edge=true;
            const double z=u*p[2]+v*q[2]+w*s[2];
            if (u>=0 && v>=0 && w>=0 && z>=0 && z<depth) { depth=z; hit=t; }
        }
        if (edge) continue;
        const int expected[4]={hit==0?255:0,hit==1?255:0,0,255};
        for (int channel=0;channel<4;++channel) {
            const int actual=pixels[(y*64+x)*4+channel];
            if (std::abs(actual-expected[channel])>1)
                return SDL_SetError("3D pixel x=%d y=%d channel=%d got=%d expected=%d",x,y,channel,actual,expected[channel]);
        }
        ++checked; if (hit>=0) ++colored;
    }
    return (checked>3000 && colored>80) || SDL_SetError("3D fixture: insufficient pixel coverage");
}
}
