#pragma once
#include "sdl3_gpu_mesh.h"

// Fixed color-vertex/column-matrix ABI, independent of the textured 2D mesh registry.
struct SDL_GPU3DEntry {
    SDL_GPUDevice * device = nullptr;
    SDL_GPUGraphicsPipeline * pipeline = nullptr;
    SDL_GPUBuffer * vertices = nullptr;
    SDL_GPUBuffer * indices = nullptr;
    SDL_GPUTexture * depth = nullptr;
    SDL_GPUTextureFormat colorFormat = SDL_GPU_TEXTUREFORMAT_INVALID;
    SDL_GPUTextureFormat depthFormat = SDL_GPU_TEXTUREFORMAT_INVALID;
    uint32_t count = 0, width = 0, height = 0;
};
inline std::unordered_map<uint64_t,SDL_GPU3DEntry> SDL_GPU3DMeshes;
inline void SDL_FreeGPU3D(SDL_GPU3DEntry & m) {
    if (m.depth) SDL_ReleaseGPUTexture(m.device,m.depth);
    if (m.pipeline) SDL_ReleaseGPUGraphicsPipeline(m.device,m.pipeline);
    if (m.vertices) SDL_ReleaseGPUBuffer(m.device,m.vertices);
    if (m.indices) SDL_ReleaseGPUBuffer(m.device,m.indices);
    m.depth=nullptr; m.pipeline=nullptr; m.vertices=nullptr; m.indices=nullptr;
}
inline void SDL_ReleaseGPU3DForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPU3DMeshes.begin(); it!=SDL_GPU3DMeshes.end();) {
        if (it->second.device==device) { SDL_FreeGPU3D(it->second); it=SDL_GPU3DMeshes.erase(it); }
        else ++it;
    }
}
inline const bool SDL_GPU3DCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPU3DForDevice);
inline SDL_GPU3DEntry * SDL_FindGPU3D(SDL_GPUDevice * device,uint64_t id) {
    auto it=SDL_GPU3DMeshes.find(id);
    if (it==SDL_GPU3DMeshes.end() || it->second.device!=device) {
        SDL_SetError("GPU 3D: stale, invalid or foreign-device ID"); return nullptr;
    }
    return &it->second;
}
inline bool SDL_ReleaseGPU3DMesh(SDL_GPUDevice * device,uint64_t id) {
    if (!SDL_IsMainThread()) return SDL_SetError("GPU 3D: main thread required");
    auto * m=SDL_FindGPU3D(device,id); if (!m) return false;
    SDL_FreeGPU3D(*m); SDL_GPU3DMeshes.erase(id); return true;
}
struct SDL_GPU3DVertex { float position[4]; float color[4]; };
static_assert(sizeof(SDL_GPU3DVertex)==32 && offsetof(SDL_GPU3DVertex,color)==16,"3D vertex ABI");
struct alignas(16) SDL_GPU3DMatrix { float c[4][4]; };
static_assert(sizeof(SDL_GPU3DMatrix)==64 && alignof(SDL_GPU3DMatrix)==16,"std140 four vec4 columns");
inline SDL_GPU3DMatrix SDL_GPU3DColumns(das::float4 a,das::float4 b,das::float4 c,das::float4 d) {
    SDL_GPU3DMatrix m; std::memcpy(m.c[0],&a,16); std::memcpy(m.c[1],&b,16);
    std::memcpy(m.c[2],&c,16); std::memcpy(m.c[3],&d,16); return m;
}
inline bool SDL_GPU3DMatrixValid(const SDL_GPU3DMatrix & m) {
    for (const auto & c:m.c) for (float v:c) if (!std::isfinite(v)) return SDL_SetError("GPU 3D: finite matrix required");
    return true;
}
inline SDL_GPUTextureFormat SDL_GPU3DDepthFormat(SDL_GPUDevice * device) {
    for (auto format:{SDL_GPU_TEXTUREFORMAT_D32_FLOAT,SDL_GPU_TEXTUREFORMAT_D24_UNORM,SDL_GPU_TEXTUREFORMAT_D16_UNORM})
        if (SDL_GPUTextureSupportsFormat(device,format,SDL_GPU_TEXTURETYPE_2D,SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) return format;
    SDL_SetError("GPU 3D: no supported depth format"); return SDL_GPU_TEXTUREFORMAT_INVALID;
}
inline bool SDL_GPU3DSizes(uint32_t positions,uint32_t colors,uint32_t indices) {
    return (positions && positions<=524288 && colors==positions && SDL_GPUIndexCount(indices)) ||
        SDL_SetError("GPU 3D: nonempty matching positions/colors, <=16 MiB vertices and <=16 MiB triangle indices required");
}
struct SDL_GPU3DBuild {
    SDL_GPU3DEntry mesh;
    SDL_GPUTransferBuffer * transfer=nullptr;
    SDL_GPUCommandBuffer * command=nullptr;
    ~SDL_GPU3DBuild() {
        const std::string error=SDL_GetError();
        if (command) SDL_CancelGPUCommandBuffer(command);
        if (transfer) SDL_ReleaseGPUTransferBuffer(mesh.device,transfer);
        SDL_FreeGPU3D(mesh); SDL_SetError("%s",error.c_str());
    }
};
inline uint64_t SDL_CreateGPU3DForFormat(SDL_GPUDevice * device,SDL_GPUTextureFormat colorFormat,
        const das::TArray<das::float4> & positions,const das::TArray<das::float4> & colors,
        const das::TArray<uint32_t> & indices,const char * vertex,const char * fragment,uint32_t format) {
    if (!SDL_IsMainThread() || !device) { SDL_SetError("GPU 3D: main thread and device required"); return 0; }
    if (!SDL_GPU3DSizes(positions.size,colors.size,indices.size)) return 0;
    if (!positions.data || !colors.data || !indices.data) { SDL_SetError("GPU 3D: missing array storage"); return 0; }
    for (uint32_t i=0;i<indices.size;++i) {
        uint32_t index; std::memcpy(&index,indices.data+size_t(i)*4,4);
        if (index>=positions.size) { SDL_SetError("GPU 3D: index outside positions"); return 0; }
    }
    std::vector<SDL_GPU3DVertex> packed(positions.size);
    for (uint32_t i=0;i<positions.size;++i) {
        auto & v=packed[i]; std::memcpy(v.position,positions.data+size_t(i)*16,16); std::memcpy(v.color,colors.data+size_t(i)*16,16);
        for (float x:v.position) if (!std::isfinite(x)) { SDL_SetError("GPU 3D: finite positions required"); return 0; }
        if (v.position[3]!=1) { SDL_SetError("GPU 3D: position.w must be 1"); return 0; }
        for (float x:v.color) if (!std::isfinite(x) || x<0 || x>1) { SDL_SetError("GPU 3D: colors must be finite in 0..1"); return 0; }
    }
    if ((format!=SDL_GPU_SHADERFORMAT_SPIRV && format!=SDL_GPU_SHADERFORMAT_DXIL) || !(SDL_GetGPUShaderFormats(device)&format)) {
        SDL_SetError("GPU 3D: unsupported shader format"); return 0;
    }
    if (SDL_GPUNextPipeline==std::numeric_limits<uint64_t>::max()) { SDL_SetError("GPU 3D: ID space exhausted"); return 0; }
    SDL_GPU3DBuild build; auto & m=build.mesh; m.device=device; m.colorFormat=colorFormat; m.count=indices.size;
    m.depthFormat=SDL_GPU3DDepthFormat(device); if (m.depthFormat==SDL_GPU_TEXTUREFORMAT_INVALID) return 0;
    SDL_GPUShaderOwner vs{device},fs{device};
    vs.shader=SDL_LoadGPUMeshShader(device,vertex,format,SDL_GPU_SHADERSTAGE_VERTEX,true,0); if (!vs.shader) return 0;
    fs.shader=SDL_LoadGPUMeshShader(device,fragment,format,SDL_GPU_SHADERSTAGE_FRAGMENT,false,0); if (!fs.shader) return 0;
    SDL_GPUVertexBufferDescription buffer{}; buffer.pitch=32; buffer.input_rate=SDL_GPU_VERTEXINPUTRATE_VERTEX;
    SDL_GPUVertexAttribute attributes[2]{};
    attributes[0].format=SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4;
    attributes[1].location=1; attributes[1].format=SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4; attributes[1].offset=16;
    SDL_GPUColorTargetDescription target{}; target.format=colorFormat;
    SDL_GPUGraphicsPipelineCreateInfo pi{}; pi.vertex_shader=vs.shader; pi.fragment_shader=fs.shader;
    pi.primitive_type=SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
    pi.vertex_input_state.vertex_buffer_descriptions=&buffer; pi.vertex_input_state.num_vertex_buffers=1;
    pi.vertex_input_state.vertex_attributes=attributes; pi.vertex_input_state.num_vertex_attributes=2;
    pi.rasterizer_state.fill_mode=SDL_GPU_FILLMODE_FILL; pi.rasterizer_state.cull_mode=SDL_GPU_CULLMODE_NONE;
    pi.rasterizer_state.enable_depth_clip=true; pi.multisample_state.sample_count=SDL_GPU_SAMPLECOUNT_1;
    pi.depth_stencil_state.enable_depth_test=true; pi.depth_stencil_state.enable_depth_write=true;
    pi.depth_stencil_state.compare_op=SDL_GPU_COMPAREOP_LESS;
    pi.target_info.color_target_descriptions=&target; pi.target_info.num_color_targets=1;
    pi.target_info.has_depth_stencil_target=true; pi.target_info.depth_stencil_format=m.depthFormat;
    m.pipeline=SDL_CreateGPUGraphicsPipeline(device,&pi); if (!m.pipeline) return 0;
    const uint32_t vertexBytes=positions.size*32, indexBytes=indices.size*4;
    SDL_GPUBufferCreateInfo bi{}; bi.usage=SDL_GPU_BUFFERUSAGE_VERTEX; bi.size=vertexBytes;
    m.vertices=SDL_CreateGPUBuffer(device,&bi); if (!m.vertices) return 0;
    bi.usage=SDL_GPU_BUFFERUSAGE_INDEX; bi.size=indexBytes;
    m.indices=SDL_CreateGPUBuffer(device,&bi); if (!m.indices) return 0;
    SDL_GPUTransferBufferCreateInfo ti{}; ti.usage=SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD; ti.size=vertexBytes+indexBytes;
    build.transfer=SDL_CreateGPUTransferBuffer(device,&ti); if (!build.transfer) return 0;
    auto * bytes=static_cast<Uint8 *>(SDL_MapGPUTransferBuffer(device,build.transfer,false)); if (!bytes) return 0;
    std::memcpy(bytes,packed.data(),vertexBytes); std::memcpy(bytes+vertexBytes,indices.data,indexBytes);
    SDL_UnmapGPUTransferBuffer(device,build.transfer);
    build.command=SDL_AcquireGPUCommandBuffer(device); if (!build.command) return 0;
    auto * copy=SDL_BeginGPUCopyPass(build.command); if (!copy) return 0;
    SDL_GPUTransferBufferLocation source{}; source.transfer_buffer=build.transfer;
    SDL_GPUBufferRegion dest{}; dest.buffer=m.vertices; dest.size=vertexBytes; SDL_UploadToGPUBuffer(copy,&source,&dest,false);
    source.offset=vertexBytes; dest.buffer=m.indices; dest.size=indexBytes; SDL_UploadToGPUBuffer(copy,&source,&dest,false);
    SDL_EndGPUCopyPass(copy); auto * command=build.command; build.command=nullptr;
    if (!SDL_SubmitGPUCommandBuffer(command)) return 0;
    const uint64_t id=SDL_GPUNextPipeline++; SDL_GPU3DMeshes.emplace(id,m);
    m={}; m.device=device; return id;
}
inline uint64_t SDL_CreateGPU3DMesh(SDL_GPUDevice * device,SDL_Window * window,
        const das::TArray<das::float4> & positions,const das::TArray<das::float4> & colors,
        const das::TArray<uint32_t> & indices,const char * vertex,const char * fragment,uint32_t format) {
    if (!SDL_IsMainThread() || !SDL_GPUWindowClaimedBy(device,window)) { SDL_SetError("GPU 3D: main thread and claimed window required"); return 0; }
    return SDL_CreateGPU3DForFormat(device,SDL_GetGPUSwapchainTextureFormat(device,window),positions,colors,indices,vertex,fragment,format);
}
#ifdef DASSDL3_TESTING
inline bool SDL_TestGPU3DFailDepth=false;
#endif
inline bool SDL_EnsureGPU3DDepth(SDL_GPU3DEntry & m,uint32_t width,uint32_t height) {
    if (!width || !height || width>8192 || height>8192 || uint64_t(width)*height>16777216)
        return SDL_SetError("GPU 3D: depth target dimensions exceed budget");
    if (m.depth && m.width==width && m.height==height) return true;
#ifdef DASSDL3_TESTING
    if (SDL_TestGPU3DFailDepth) return SDL_SetError("injected depth allocation failure");
#endif
    SDL_GPUTextureCreateInfo ti{}; ti.type=SDL_GPU_TEXTURETYPE_2D; ti.format=m.depthFormat;
    ti.usage=SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET; ti.width=width; ti.height=height;
    ti.layer_count_or_depth=ti.num_levels=1; ti.sample_count=SDL_GPU_SAMPLECOUNT_1;
    auto * next=SDL_CreateGPUTexture(m.device,&ti); if (!next) return false;
    if (m.depth) SDL_ReleaseGPUTexture(m.device,m.depth);
    m.depth=next; m.width=width; m.height=height; return true;
}
inline SDL_GPURenderPass * SDL_BeginGPU3DPass(SDL_GPUCommandBuffer * command,const SDL_GPUColorTargetInfo & target,
        SDL_GPU3DEntry & m,uint32_t width,uint32_t height) {
    if (!SDL_EnsureGPU3DDepth(m,width,height)) return nullptr;
    SDL_GPUDepthStencilTargetInfo depth{}; depth.texture=m.depth; depth.clear_depth=1;
    depth.load_op=SDL_GPU_LOADOP_CLEAR; depth.store_op=SDL_GPU_STOREOP_DONT_CARE;
    depth.stencil_load_op=SDL_GPU_LOADOP_DONT_CARE; depth.stencil_store_op=SDL_GPU_STOREOP_DONT_CARE;
    depth.cycle=true;
    return SDL_BeginGPURenderPass(command,&target,1,&depth);
}
inline void SDL_RecordGPU3D(SDL_GPURenderPass * pass,SDL_GPUCommandBuffer * command,const SDL_GPU3DEntry & m,const SDL_GPU3DMatrix & matrix) {
    SDL_PushGPUVertexUniformData(command,0,&matrix,sizeof(matrix));
    SDL_BindGPUGraphicsPipeline(pass,m.pipeline);
    SDL_GPUBufferBinding buffer{}; buffer.buffer=m.vertices; SDL_BindGPUVertexBuffers(pass,0,&buffer,1);
    buffer.buffer=m.indices; SDL_BindGPUIndexBuffer(pass,&buffer,SDL_GPU_INDEXELEMENTSIZE_32BIT);
    SDL_DrawGPUIndexedPrimitives(pass,m.count,1,0,0,0);
}
inline int SDL_DrawGPU3DMesh(SDL_GPUDevice * device,SDL_Window * window,uint64_t id,das::float4 a,das::float4 b,das::float4 c,das::float4 d) {
    if (!SDL_IsMainThread()) { SDL_SetError("GPU 3D: main thread required"); return -1; }
    const auto matrix=SDL_GPU3DColumns(a,b,c,d); if (!SDL_GPU3DMatrixValid(matrix)) return -1;
    auto * m=SDL_FindGPU3D(device,id); if (!m) return -1;
    if (!SDL_GPUWindowClaimedBy(device,window)) { SDL_SetError("GPU 3D: unclaimed window"); return -1; }
    if (m->colorFormat!=SDL_GetGPUSwapchainTextureFormat(device,window)) { SDL_SetError("GPU 3D: target format mismatch"); return -1; }
    uint32_t w=0,h=0;
    return SDL_GPUFrameWithTarget<SDL_GPUClearAPI>(device,window,{0,0,0,1},w,h,
        [m,&matrix](SDL_GPURenderPass * pass,SDL_GPUCommandBuffer * command) { SDL_RecordGPU3D(pass,command,*m,matrix); },
        [m](SDL_GPUCommandBuffer * command,const SDL_GPUColorTargetInfo & target,uint32_t width,uint32_t height) {
            return SDL_BeginGPU3DPass(command,target,*m,width,height);
        });
}
inline float SDL_GPU3DWindowAspect(SDL_Window * window) {
    if (!SDL_IsMainThread() || !window) { SDL_SetError("GPU aspect: main thread and window required"); return 0; }
    int w=0,h=0; if (!SDL_GetWindowSizeInPixels(window,&w,&h)) return 0;
    return w>0 && h>0 ? float(w)/float(h) : 1.0f;
}
