#pragma once
#include "sdl3_gpu_instancing.h"
#include "gpu_triangle_probe.h"
namespace sdl3_test {
inline bool gpu_instances_failed_submit(SDL_GPUDevice * device,uint64_t id,const das::TArray<das::float4> & columns) {
    struct Reset { ~Reset() { SDL_TestGPUInstancesFailSubmit=false; } } reset;
    SDL_TestGPUInstancesFailSubmit=true;
    if (SDL_UpdateGPUInstances(device,id,columns) || std::string(SDL_GetError())!="injected instance upload submit failure") return false;
    auto * mesh=SDL_FindGPULit(device,id); if (!mesh || mesh->instancesReady) return false;
    SDL_GPU3DMatrix camera{}; for (int i=0;i<4;++i) camera.c[i][i]=1;
    GPUFake::scenario=1; GPUFake::trace.clear();
    return SDL_GPUInstancesFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),*mesh,camera,{0,0,1,.2f})==-1 && GPUFake::trace.empty();
}
inline uint64_t gpu_instances_offscreen(SDL_GPUDevice * device,const das::TArray<das::float4> & positions,
        const das::TArray<das::float4> & normals,const das::TArray<das::float2> & uv,
        const das::TArray<uint8_t> & pixels,const das::TArray<uint32_t> & indices,const das::TArray<das::float4> & models,
        const char * vs,const char * fs,uint32_t format) {
    return SDL_CreateGPULitForFormat(device,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,positions,normals,uv,pixels,1,1,indices,vs,fs,format,&models);
}
inline bool gpu_instances_preflight(SDL_GPUDevice * device,uint64_t id) {
    auto * mesh=SDL_FindGPULit(device,id); if (!mesh) return false;
    SDL_GPU3DMatrix camera{}; for (int i=0;i<4;++i) camera.c[i][i]=1;
    GPUFake::scenario=1; GPUFake::trace.clear();
    if (SDL_GPUInstancesFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),*mesh,camera,{0,0,1,.2f})!=-1 || GPUFake::trace!="A") return false;
    camera.c[0][0]=std::numeric_limits<float>::infinity(); GPUFake::trace.clear();
    if (SDL_GPUInstancesFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),*mesh,camera,{0,0,1,.2f})!=-1 || !GPUFake::trace.empty()) return false;
    camera.c[0][0]=1;
    if (SDL_GPUInstancesFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),*mesh,camera,{0,0,0,.2f})!=-1 || !GPUFake::trace.empty()) return false;
    auto plain=*mesh; plain.instances=nullptr; plain.instanceCount=0;
    if (SDL_GPUInstancesFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),plain,camera,{0,0,1,.2f})!=-1 || !GPUFake::trace.empty()) return false;
    GPUFake::scenario=3; GPUFake::trace.clear(); auto * depth=mesh->depth;
    return SDL_GPUInstancesFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),*mesh,camera,{0,0,1,.2f})==0 && GPUFake::trace=="AWC" && mesh->depth==depth;
}
inline bool gpu_instances_reference(const std::array<Uint8,64*64*4> & pixels,
        const das::TArray<das::float4> & columns,const SDL_GPU3DMatrix & camera,
        const das::TArray<das::float4> * colors=nullptr,
        const std::array<std::array<int,4>,3> * textures=nullptr) {
    // Three copies of one triangle: independent CPU transform, inverse and depth reference.
    const double vertices[3][4]={{-.8,-.7,0,1},{.8,-.7,0,1},{0,.8,0,1}};
    double projected[3][3][3]{},illumination[3]{};
    for (uint32_t obj=0;obj<3;++obj) {
        float model[4][4]; std::memcpy(model,columns.data+size_t(obj)*64,64);
        double inverse[3][6]{};
        for (int row=0;row<3;++row) { for (int col=0;col<3;++col) inverse[row][col]=model[col][row]; inverse[row][row+3]=1; }
        for (int col=0;col<3;++col) {
            int pivot=col; for (int row=col+1;row<3;++row) if (std::abs(inverse[row][col])>std::abs(inverse[pivot][col])) pivot=row;
            if (std::abs(inverse[pivot][col])<1e-12) return false;
            for (int j=0;j<6;++j) std::swap(inverse[col][j],inverse[pivot][j]);
            const double value=inverse[col][col]; for (double & v:inverse[col]) v/=value;
            for (int row=0;row<3;++row) if (row!=col) { const double f=inverse[row][col]; for (int j=0;j<6;++j) inverse[row][j]-=f*inverse[col][j]; }
        }
        // Fixture normal (1,0,1), white opaque texture and light +Z, ambient .2.
        double n[3]; for (int row=0;row<3;++row) n[row]=inverse[0][row+3]+inverse[2][row+3];
        illumination[obj]=.2+.8*std::max(0.0,n[2]/std::sqrt(n[0]*n[0]+n[1]*n[1]+n[2]*n[2]));
        for (int v=0;v<3;++v) {
            double world[4]{},clip[4]{};
            for (int row=0;row<4;++row) for (int col=0;col<4;++col) world[row]+=model[col][row]*vertices[v][col];
            for (int row=0;row<4;++row) for (int col=0;col<4;++col) clip[row]+=camera.c[col][row]*world[col];
            if (clip[3]<=0) return false;
            projected[obj][v][0]=(clip[0]/clip[3]+1)*32;
            projected[obj][v][1]=(1-clip[1]/clip[3])*32;
            projected[obj][v][2]=clip[2]/clip[3];
        }
    }
    int checked=0,covered=0;
    for (int y=0;y<64;++y) for (int x=0;x<64;++x) {
        double depth=1; int hit=-1; bool edge=false;
        for (uint32_t obj=0;obj<3;++obj) {
            const auto * p=projected[obj][0]; const auto * q=projected[obj][1]; const auto * s=projected[obj][2];
            const double den=(q[1]-s[1])*(p[0]-s[0])+(s[0]-q[0])*(p[1]-s[1]);
            if (std::abs(den)<1e-8) return false;
            const double u=((q[1]-s[1])*(x+.5-s[0])+(s[0]-q[0])*(y+.5-s[1]))/den;
            const double v=((s[1]-p[1])*(x+.5-s[0])+(p[0]-s[0])*(y+.5-s[1]))/den;
            const double w=1-u-v;
            if (u>-.02 && v>-.02 && w>-.02 && (std::abs(u)<.02 || std::abs(v)<.02 || std::abs(w)<.02)) edge=true;
            const double z=u*p[2]+v*q[2]+w*s[2];
            if (u>=0 && v>=0 && w>=0 && z>=0 && z<depth) { depth=z; hit=int(obj); }
        }
        if (edge) continue;
        int expected[4]={0,0,0,255};
        if (hit>=0) {
            float tint[4]={1,1,1,1};
            if (colors) std::memcpy(tint,colors->data+size_t(hit)*16,16);
            const int texel[4]={160,210,96,192}; // Colored fixture: nonwhite RGBA, including nonopaque alpha.
            for (int k=0;k<4;++k) expected[k]=int(std::round((textures?(*textures)[hit][k]:(colors?texel[k]:255))*tint[k]*(k==3?1:illumination[hit])));
            ++covered;
        }
        for (int channel=0;channel<4;++channel) {
            const int actual=pixels[(y*64+x)*4+channel];
            if (std::abs(actual-expected[channel])>1) return SDL_SetError("Instancing pixel %d,%d channel%d got%d expected%d",x,y,channel,actual,expected[channel]);
        }
        ++checked;
    }
    return (checked>3000 && covered>80) || SDL_SetError("Instancing fixture: insufficient coverage");
}
inline bool gpu_instances_submit(GPUReadback & r,SDL_GPULitEntry & mesh,const SDL_GPU3DMatrix & camera) {
    auto * device=r.device;
    const SDL_GPULight lighting{{0,0,1},.2f};
    SDL_GPUTextureCreateInfo ti{}; ti.type=SDL_GPU_TEXTURETYPE_2D; ti.format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    ti.usage=SDL_GPU_TEXTUREUSAGE_COLOR_TARGET; ti.width=ti.height=64; ti.layer_count_or_depth=ti.num_levels=1; ti.sample_count=SDL_GPU_SAMPLECOUNT_1;
    r.texture=SDL_CreateGPUTexture(device,&ti); if (!r.texture) return false;
    SDL_GPUTransferBufferCreateInfo transfer{}; transfer.usage=SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD; transfer.size=64*64*4;
    r.transfer=SDL_CreateGPUTransferBuffer(device,&transfer); if (!r.transfer) return false;
    r.command=SDL_AcquireGPUCommandBuffer(device); if (!r.command) return false;
    SDL_GPUColorTargetInfo target{}; target.texture=r.texture; target.clear_color={0,0,0,1}; target.load_op=SDL_GPU_LOADOP_CLEAR; target.store_op=SDL_GPU_STOREOP_STORE;
    auto * pass=SDL_BeginGPU3DPass(r.command,target,mesh,64,64); if (!pass) return false;
    SDL_RecordGPUInstances(pass,r.command,mesh,camera,lighting); SDL_EndGPURenderPass(pass);
    auto * copy=SDL_BeginGPUCopyPass(r.command); if (!copy) return false;
    SDL_GPUTextureRegion source{}; source.texture=r.texture; source.w=source.h=64; source.d=1;
    SDL_GPUTextureTransferInfo dest{}; dest.transfer_buffer=r.transfer; dest.pixels_per_row=dest.rows_per_layer=64;
    SDL_DownloadFromGPUTexture(copy,&source,&dest); SDL_EndGPUCopyPass(copy);
    r.fence=SDL_SubmitGPUCommandBufferAndAcquireFence(r.command); r.command=nullptr; r.submitted=true;
    return r.fence!=nullptr;
}
inline bool gpu_instances_check(GPUReadback & r,const das::TArray<das::float4> & columns,const SDL_GPU3DMatrix & camera,
        const das::TArray<das::float4> * colors=nullptr,
        const std::array<std::array<int,4>,3> * textures=nullptr) {
    if (!r.fence || !SDL_WaitForGPUFences(r.device,true,&r.fence,1)) return false;
    auto * bytes=static_cast<const Uint8 *>(SDL_MapGPUTransferBuffer(r.device,r.transfer,false)); if (!bytes) return false;
    std::array<Uint8,64*64*4> pixels{}; std::memcpy(pixels.data(),bytes,pixels.size()); SDL_UnmapGPUTransferBuffer(r.device,r.transfer);
    return gpu_instances_reference(pixels,columns,camera,colors,textures);
}
inline bool gpu_instances_pixels(SDL_GPUDevice * device,uint64_t id,const das::TArray<das::float4> & columns,
        das::float4 a,das::float4 b,das::float4 c,das::float4 d) {
    auto * mesh=SDL_FindGPULit(device,id);
    if (!mesh || mesh->colorFormat!=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM || mesh->instanceCount!=3 || columns.size!=12) return false;
    const auto camera=SDL_GPU3DColumns(a,b,c,d);
    GPUReadback r{device};
    return gpu_instances_submit(r,*mesh,camera) && gpu_instances_check(r,columns,camera);
}
inline bool gpu_instances_pending(SDL_GPUDevice * device,uint64_t id,const das::TArray<das::float4> & first,
        const das::TArray<das::float4> & second) {
    auto * mesh=SDL_FindGPULit(device,id);
    if (!mesh || mesh->colorFormat!=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM || mesh->instanceCount!=3 || first.size!=12 || second.size!=12) return false;
    SDL_GPU3DMatrix camera{}; for (int i=0;i<4;++i) camera.c[i][i]=1;
    std::vector<std::unique_ptr<GPUReadback>> pending;
    for (int frame=0;frame<12;++frame) {
        const auto & columns=frame%2?second:first;
        if (!SDL_UpdateGPUInstances(device,id,columns)) return false;
        auto readback=std::make_unique<GPUReadback>(); readback->device=device;
        if (!gpu_instances_submit(*readback,*mesh,camera)) return false;
        pending.push_back(std::move(readback));
    }
    // No fence/idle waits above: both transfer and destination reuse cross submissions.
    for (int frame=0;frame<12;++frame)
        if (!gpu_instances_check(*pending[frame],frame%2?second:first,camera)) return false;
    return true;
}
}
