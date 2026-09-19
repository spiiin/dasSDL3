#pragma once
#include "sdl3_gpu_lit.h"
#include "gpu_triangle_probe.h"
namespace sdl3_test {
inline int gpu_lit_meshes() { return int(SDL_GPULitMeshes.size()); }
inline bool gpu_lit_guards() {
    if (!SDL_GPULitSizes(6,6,6,6,16,2,2) || SDL_GPULitSizes(6,5,6,6,16,2,2) ||
        SDL_GPULitSizes(6,6,5,6,16,2,2) || SDL_GPULitSizes(349526,349526,349526,3,4,1,1) ||
        SDL_GPULitSizes(6,6,6,0,16,2,2) || SDL_GPULitSizes(6,6,6,6,15,2,2)) return false;
    SDL_GPU3DMatrix identity{}; for (int i=0;i<4;++i) identity.c[i][i]=1;
    SDL_GPULitUniforms u{}; SDL_GPULight l{}; das::float4 light{0,0,1,.2f};
    if (!SDL_PrepareGPULit(identity,identity,light,u,l)) return false;
    auto bad=identity; bad.c[0][0]=0; if (SDL_PrepareGPULit(identity,bad,light,u,l)) return false;
    bad=identity; bad.c[0][3]=1; if (SDL_PrepareGPULit(identity,bad,light,u,l)) return false;
    bad=identity; bad.c[0][0]=std::numeric_limits<float>::quiet_NaN(); if (SDL_PrepareGPULit(identity,bad,light,u,l)) return false;
    bad=identity; bad.c[2][1]=std::numeric_limits<float>::infinity(); if (SDL_PrepareGPULit(bad,identity,light,u,l)) return false;
    return !SDL_PrepareGPULit(identity,identity,das::float4{0,0,0,.2f},u,l) &&
        !SDL_PrepareGPULit(identity,identity,das::float4{0,0,1,1.1f},u,l) &&
        !SDL_PrepareGPULit(identity,identity,das::float4{0,0,1,std::numeric_limits<float>::quiet_NaN()},u,l);
}
inline uint64_t gpu_lit_offscreen(SDL_GPUDevice * device,const das::TArray<das::float4> & positions,
        const das::TArray<das::float4> & normals,const das::TArray<das::float2> & uv,
        const das::TArray<uint8_t> & pixels,uint32_t width,uint32_t height,const das::TArray<uint32_t> & indices,
        const char * vs,const char * fs,uint32_t format) {
    return SDL_CreateGPULitForFormat(device,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,positions,normals,uv,pixels,width,height,indices,vs,fs,format);
}
inline bool gpu_lit_depth(SDL_GPUDevice * device,SDL_Window * window,uint64_t id) {
    auto * m=SDL_FindGPULit(device,id); int w=0,h=0;
    return m && SDL_GetWindowSizeInPixels(window,&w,&h) && m->depth && m->width==uint32_t(w) && m->height==uint32_t(h);
}
inline bool gpu_lit_pixels(SDL_GPUDevice * device,uint64_t id,das::float4 a,das::float4 b,das::float4 c,das::float4 d,
        das::float4 ma,das::float4 mb,das::float4 mc,das::float4 md,das::float4 light) {
    auto * m=SDL_FindGPULit(device,id); if (!m || m->count!=6 || m->colorFormat!=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) return false;
    const auto matrix=SDL_GPU3DColumns(a,b,c,d); if (!SDL_GPU3DMatrixValid(matrix)) return false;
    const auto model=SDL_GPU3DColumns(ma,mb,mc,md);
    SDL_GPULitUniforms uniforms{}; SDL_GPULight lighting{};
    if (!SDL_PrepareGPULit(matrix,model,light,uniforms,lighting)) return false;
    GPUReadback r{device};
    SDL_GPUTextureCreateInfo ti{}; ti.type=SDL_GPU_TEXTURETYPE_2D; ti.format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    ti.usage=SDL_GPU_TEXTUREUSAGE_COLOR_TARGET; ti.width=ti.height=64; ti.layer_count_or_depth=ti.num_levels=1; ti.sample_count=SDL_GPU_SAMPLECOUNT_1;
    r.texture=SDL_CreateGPUTexture(device,&ti); if (!r.texture) return false;
    SDL_GPUTransferBufferCreateInfo transfer{}; transfer.usage=SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD; transfer.size=64*64*4;
    r.transfer=SDL_CreateGPUTransferBuffer(device,&transfer); if (!r.transfer) return false;
    r.command=SDL_AcquireGPUCommandBuffer(device); if (!r.command) return false;
    SDL_GPUColorTargetInfo target{}; target.texture=r.texture; target.clear_color={0,0,0,1}; target.load_op=SDL_GPU_LOADOP_CLEAR; target.store_op=SDL_GPU_STOREOP_STORE;
    auto * pass=SDL_BeginGPU3DPass(r.command,target,*m,64,64); if (!pass) return false;
    SDL_RecordGPULit(pass,r.command,*m,uniforms,lighting); SDL_EndGPURenderPass(pass);
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
    double projected[6][3]{},reciprocalW[6]{};
    // Independent inverse by Gauss-Jordan elimination, not the production cofactor routine.
    double inverse[3][6]{};
    for (int row=0;row<3;++row) { for (int col=0;col<3;++col) inverse[row][col]=model.c[col][row]; inverse[row][row+3]=1; }
    for (int col=0;col<3;++col) {
        int pivot=col; for (int row=col+1;row<3;++row) if (std::abs(inverse[row][col])>std::abs(inverse[pivot][col])) pivot=row;
        if (std::abs(inverse[pivot][col])<1e-12) return false;
        for (int j=0;j<6;++j) std::swap(inverse[col][j],inverse[pivot][j]);
        const double value=inverse[col][col]; for (double & v:inverse[col]) v/=value;
        for (int row=0;row<3;++row) if (row!=col) { const double f=inverse[row][col]; for (int j=0;j<6;++j) inverse[row][j]-=f*inverse[col][j]; }
    }
    float sourceLight[4]; std::memcpy(sourceLight,&light,16);
    const double lightLength=std::sqrt(double(sourceLight[0])*sourceLight[0]+double(sourceLight[1])*sourceLight[1]+double(sourceLight[2])*sourceLight[2]);
    double illumination[2];
    const double normals[2][3]={{1,0,1},{0,1,1}};
    for (int t=0;t<2;++t) {
        double n[3]{}; for (int row=0;row<3;++row) for (int col=0;col<3;++col) n[row]+=inverse[col][row+3]*normals[t][col];
        double length=std::sqrt(n[0]*n[0]+n[1]*n[1]+n[2]*n[2]);
        const double cosine=(n[0]*sourceLight[0]+n[1]*sourceLight[1]+n[2]*sourceLight[2])/(length*lightLength);
        illumination[t]=sourceLight[3]+(1-sourceLight[3])*std::max(0.0,std::min(1.0,cosine));
    }
    const int texture[4][4]={{240,60,30,255},{30,220,80,210},{50,80,240,170},{220,190,40,130}};
    for (int v=0;v<6;++v) {
        double clip[4]{};
        for (int row=0;row<4;++row) for (int col=0;col<4;++col) clip[row]+=matrix.c[col][row]*input[v][col];
        if (clip[3]<=0) return SDL_SetError("3D fixture: reference geometry behind camera");
        reciprocalW[v]=1/clip[3];
        projected[v][0]=(clip[0]/clip[3]+1)*32; projected[v][1]=(1-clip[1]/clip[3])*32; projected[v][2]=clip[2]/clip[3];
    }
    int checked=0,colored=0;
    for (int y=0;y<64;++y) for (int x=0;x<64;++x) {
        double depth=1,texU=0,texV=0; int hit=-1; bool edge=false;
        for (int t=0;t<2;++t) {
            const auto * p=projected[t*3]; const auto * q=projected[t*3+1]; const auto * s=projected[t*3+2];
            const double den=(q[1]-s[1])*(p[0]-s[0])+(s[0]-q[0])*(p[1]-s[1]);
            if (std::abs(den)<1e-8) return SDL_SetError("3D fixture: degenerate reference triangle");
            const double u=((q[1]-s[1])*(x+.5-s[0])+(s[0]-q[0])*(y+.5-s[1]))/den;
            const double v=((s[1]-p[1])*(x+.5-s[0])+(p[0]-s[0])*(y+.5-s[1]))/den;
            const double w=1-u-v;
            if (u>-.02 && v>-.02 && w>-.02 && (std::abs(u)<.02 || std::abs(v)<.02 || std::abs(w)<.02)) edge=true;
            const double z=u*p[2]+v*q[2]+w*s[2];
            if (u>=0 && v>=0 && w>=0 && z>=0 && z<depth) { depth=z; hit=t;
                const double pu=u*reciprocalW[t*3],pv=v*reciprocalW[t*3+1],pw=w*reciprocalW[t*3+2];
                texU=(pv+.5*pw)/(pu+pv+pw); texV=(pu+pv)/(pu+pv+pw); }
        }
        if (edge) continue;
        if (hit>=0 && (std::abs(texU-.5)<.02 || std::abs(texV-.5)<.02)) continue;
        int expected[4]={0,0,0,255};
        if (hit>=0) {
            const int texel=(texV>=.5?2:0)+(texU>=.5?1:0);
            for (int channel=0;channel<3;++channel) expected[channel]=int(std::round(texture[texel][channel]*illumination[hit]));
            expected[3]=texture[texel][3];
        }
        for (int channel=0;channel<4;++channel) {
            const int actual=pixels[(y*64+x)*4+channel];
            if (std::abs(actual-expected[channel])>1)
                return SDL_SetError("lit pixel x=%d y=%d channel=%d got=%d expected=%d",x,y,channel,actual,expected[channel]);
        }
        ++checked; if (hit>=0) ++colored;
    }
    return (checked>2800 && colored>80) || SDL_SetError("3D fixture: insufficient pixel coverage");
}
}
