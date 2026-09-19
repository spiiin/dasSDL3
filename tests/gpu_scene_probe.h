#pragma once
#include "sdl3_gpu_scene.h"
#include "gpu_triangle_probe.h"
#include "gpu_probe.h"
namespace sdl3_test {
inline int gpu_scenes() { return int(SDL_GPUScenes.size()); }
inline uint64_t gpu_scene_offscreen(SDL_GPUDevice * device) {
    return SDL_CreateGPUSceneForFormat(device,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM);
}
inline bool gpu_scene_sizes() {
    return SDL_GPUSceneSizes(0,0,0) && SDL_GPUSceneSizes(1024,4096,1024) &&
        !SDL_GPUSceneSizes(1025,4100,1025) && !SDL_GPUSceneSizes(1,3,1) &&
        !SDL_GPUSceneSizes(1,4,0) && !SDL_GPUSceneSizes(UINT32_MAX,0,UINT32_MAX);
}
inline bool gpu_scene_depth(SDL_GPUDevice * device,SDL_Window * window,uint64_t id) {
    auto * scene=SDL_FindGPUScene(device,id); int w=0,h=0;
    return scene && SDL_GetWindowSizeInPixels(window,&w,&h) && scene->depth && scene->width==uint32_t(w) && scene->height==uint32_t(h);
}
inline bool gpu_scene_depth_failure(SDL_GPUDevice * device,SDL_Window * window,uint64_t id) {
    auto * scene=SDL_FindGPUScene(device,id); if (!scene) return false;
    // Force next draw to resize the depth cache, then exercise the real acquired-frame failure path.
    if (!SDL_EnsureGPU3DDepth(*scene,32,32)) return false;
    auto * previous=scene->depth;
    das::TArray<uint64_t> meshes{}; das::TArray<das::float4> columns{},lights{};
    // TArray's user-provided default constructor does not initialize the Array storage.
    std::memset(static_cast<das::Array *>(&meshes),0,sizeof(das::Array));
    std::memset(static_cast<das::Array *>(&columns),0,sizeof(das::Array));
    std::memset(static_cast<das::Array *>(&lights),0,sizeof(das::Array));
    SDL_GPU3DMatrix camera{}; for (int i=0;i<4;++i) camera.c[i][i]=1;
    SDL_TestGPU3DFailDepth=true;
    int status=0;
    for (int i=0;i<100 && status==0;++i) {
        SDL_PumpEvents();
        status=SDL_GPUSceneFrame<SDL_GPUClearAPI>(device,window,*scene,meshes,columns,lights,camera);
        if (!status) SDL_Delay(10);
    }
    SDL_TestGPU3DFailDepth=false;
    return status==-1 && scene->depth==previous && scene->width==32 &&
        std::string(SDL_GetError()).find("injected depth allocation failure")!=std::string::npos;
}
inline bool gpu_scene_preflight(SDL_GPUDevice * device,uint64_t id,const das::TArray<uint64_t> & meshes,
        const das::TArray<das::float4> & columns,const das::TArray<das::float4> & lights,
        das::float4 a,das::float4 b,das::float4 c,das::float4 d,bool valid) {
    auto * scene=SDL_FindGPUScene(device,id); if (!scene) return false;
    GPUFake::scenario=1; GPUFake::trace.clear();
    int status=SDL_GPUSceneFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),*scene,meshes,columns,lights,SDL_GPU3DColumns(a,b,c,d));
    if (status!=-1 || GPUFake::trace!=(valid?"A":"")) return false;
    if (!valid) return true;
    auto camera=SDL_GPU3DColumns(a,b,c,d);
    auto badCamera=camera; badCamera.c[0][0]=std::numeric_limits<float>::infinity();
    GPUFake::trace.clear();
    if (SDL_GPUSceneFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),*scene,meshes,columns,lights,badCamera)!=-1 || !GPUFake::trace.empty()) return false;
    if (meshes.size) {
        auto incompatible=*scene; incompatible.colorFormat=SDL_GPU_TEXTUREFORMAT_INVALID;
        GPUFake::trace.clear();
        if (SDL_GPUSceneFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),incompatible,meshes,columns,lights,camera)!=-1 || !GPUFake::trace.empty()) return false;
    }
    // A valid list and NULL drawable must skip without touching the depth cache.
    auto * previous=scene->depth; const auto width=scene->width, height=scene->height;
    GPUFake::scenario=3; GPUFake::trace.clear();
    status=SDL_GPUSceneFrame<GPUFake>(device,GPUFake::handle<SDL_Window>(),*scene,meshes,columns,lights,camera);
    return status==0 && GPUFake::trace=="AWC" && scene->depth==previous && scene->width==width && scene->height==height;
}
inline bool gpu_scene_pixels(SDL_GPUDevice * device,uint64_t id,const das::TArray<uint64_t> & meshes,
        const das::TArray<das::float4> & columns,const das::TArray<das::float4> & lights,
        das::float4 a,das::float4 b,das::float4 c,das::float4 d,uint64_t red,uint64_t green) {
    auto * scene=SDL_FindGPUScene(device,id); if (!scene || scene->colorFormat!=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM || meshes.size>2) return false;
    const auto camera=SDL_GPU3DColumns(a,b,c,d);
    std::vector<SDL_GPUSceneDraw> draws;
    if (!SDL_PrepareGPUScene(*scene,meshes,columns,lights,camera,draws)) return false;
    GPUReadback r{device};
    SDL_GPUTextureCreateInfo ti{}; ti.type=SDL_GPU_TEXTURETYPE_2D; ti.format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    ti.usage=SDL_GPU_TEXTUREUSAGE_COLOR_TARGET; ti.width=ti.height=64; ti.layer_count_or_depth=ti.num_levels=1; ti.sample_count=SDL_GPU_SAMPLECOUNT_1;
    r.texture=SDL_CreateGPUTexture(device,&ti); if (!r.texture) return false;
    SDL_GPUTransferBufferCreateInfo transfer{}; transfer.usage=SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD; transfer.size=64*64*4;
    r.transfer=SDL_CreateGPUTransferBuffer(device,&transfer); if (!r.transfer) return false;
    r.command=SDL_AcquireGPUCommandBuffer(device); if (!r.command) return false;
    SDL_GPUColorTargetInfo target{}; target.texture=r.texture; target.clear_color={0,0,0,1}; target.load_op=SDL_GPU_LOADOP_CLEAR; target.store_op=SDL_GPU_STOREOP_STORE;
    auto * pass=SDL_BeginGPU3DPass(r.command,target,*scene,64,64); if (!pass) return false;
    SDL_RecordGPUScene(pass,r.command,draws); SDL_EndGPURenderPass(pass);
    auto * copy=SDL_BeginGPUCopyPass(r.command); if (!copy) return false;
    SDL_GPUTextureRegion source{}; source.texture=r.texture; source.w=source.h=64; source.d=1;
    SDL_GPUTextureTransferInfo dest{}; dest.transfer_buffer=r.transfer; dest.pixels_per_row=dest.rows_per_layer=64;
    SDL_DownloadFromGPUTexture(copy,&source,&dest); SDL_EndGPUCopyPass(copy);
    r.fence=SDL_SubmitGPUCommandBufferAndAcquireFence(r.command); r.command=nullptr; r.submitted=true;
    if (!r.fence || !SDL_WaitForGPUFences(device,true,&r.fence,1)) return false;
    auto * bytes=static_cast<const Uint8 *>(SDL_MapGPUTransferBuffer(device,r.transfer,false)); if (!bytes) return false;
    std::array<Uint8,64*64*4> pixels{}; std::memcpy(pixels.data(),bytes,pixels.size()); SDL_UnmapGPUTransferBuffer(device,r.transfer);
    // Known fixture: one flat triangle per object, different 1x1 red/green textures.
    // CPU transform/depth/light calculation uses input arrays, never prepared GPU uniforms.
    const double vertices[3][4]={{-.8,-.7,0,1},{.8,-.7,0,1},{0,.8,0,1}};
    double projected[2][3][3]{},illumination[2]{}; int channels[2]{};
    for (uint32_t obj=0;obj<meshes.size;++obj) {
        uint64_t mesh; std::memcpy(&mesh,meshes.data+size_t(obj)*8,8);
        if (mesh!=red && mesh!=green) return false;
        channels[obj]=mesh==red?0:1;
        float model[4][4]; std::memcpy(model,columns.data+size_t(obj)*64,64);
        // Fixture models are positive diagonal scale and translation: normal stays +Z.
        for (int row=0;row<3;++row) for (int col=0;col<3;++col)
            if (row==col ? model[col][row]<=0 : model[col][row]!=0) return false;
        float light[4]; std::memcpy(light,lights.data+size_t(obj)*16,16);
        const double len=std::sqrt(double(light[0])*light[0]+double(light[1])*light[1]+double(light[2])*light[2]);
        illumination[obj]=light[3]+(1-light[3])*std::max(0.0,double(light[2])/len);
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
        for (uint32_t obj=0;obj<meshes.size;++obj) {
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
        if (hit>=0) { expected[channels[hit]]=int(std::round(255*illumination[hit])); ++covered; }
        for (int channel=0;channel<4;++channel) {
            const int actual=pixels[(y*64+x)*4+channel];
            if (std::abs(actual-expected[channel])>1) return SDL_SetError("Scene pixel %d,%d channel%d got%d expected%d",x,y,channel,actual,expected[channel]);
        }
        ++checked;
    }
    return (checked>3000 && (meshes.size?covered>80:covered==0)) || SDL_SetError("Scene fixture: insufficient coverage");
}
}
