#pragma once
#include "sdl3_gpu_3d.h"

struct alignas(16) SDL_GPULitUniforms { SDL_GPU3DMatrix mvp; float normal[3][4]; };
struct alignas(16) SDL_GPULight { float direction[3],ambient; };
static_assert(sizeof(SDL_GPULitUniforms)==112 && offsetof(SDL_GPULitUniforms,normal)==64 && sizeof(SDL_GPULight)==16,"lit std140 ABI");
inline bool SDL_PrepareGPULit(const SDL_GPU3DMatrix & mvp,const SDL_GPU3DMatrix & model,
        das::float4 light,SDL_GPULitUniforms & uniforms,SDL_GPULight & lighting) {
    if (!SDL_GPU3DMatrixValid(mvp) || !SDL_GPU3DMatrixValid(model)) return false;
    if (model.c[0][3]!=0 || model.c[1][3]!=0 || model.c[2][3]!=0 || model.c[3][3]!=1)
        return SDL_SetError("GPU lit: affine model required");
    double scale=0;
    for (int c=0;c<3;++c) for (int r=0;r<3;++r) scale=std::max(scale,std::abs(double(model.c[c][r])));
    if (!scale) return SDL_SetError("GPU lit: singular model");
    double a[3][3],cofactor[3][3];
    for (int r=0;r<3;++r) for (int c=0;c<3;++c) a[r][c]=model.c[c][r]/scale;
    for (int r=0;r<3;++r) for (int c=0;c<3;++c)
        cofactor[r][c]=a[(r+1)%3][(c+1)%3]*a[(r+2)%3][(c+2)%3]-a[(r+1)%3][(c+2)%3]*a[(r+2)%3][(c+1)%3];
    const double det=a[0][0]*cofactor[0][0]+a[0][1]*cofactor[0][1]+a[0][2]*cofactor[0][2];
    if (std::abs(det)<1e-8) return SDL_SetError("GPU lit: singular or ill-conditioned model");
    // Normalize by one positive common scale: equivalent normal directions, bounded shader values.
    double largest=0;
    for (auto & row:cofactor) for (double x:row) largest=std::max(largest,std::abs(x));
    uniforms={}; uniforms.mvp=mvp;
    for (int c=0;c<3;++c) for (int r=0;r<3;++r) uniforms.normal[c][r]=float(cofactor[r][c]/largest*(det<0?-1:1));
    std::memcpy(&lighting,&light,16);
    double length=0;
    for (float x:lighting.direction) { if (!std::isfinite(x)) return SDL_SetError("GPU lit: finite light required"); length+=double(x)*x; }
    if (length<1e-12 || !std::isfinite(lighting.ambient) || lighting.ambient<0 || lighting.ambient>1)
        return SDL_SetError("GPU lit: nonzero light direction and ambient in 0..1 required");
    for (float & x:lighting.direction) x=float(x/std::sqrt(length));
    return true;
}

inline bool SDL_PrepareGPUInstances(const das::TArray<das::float4> & models,std::vector<SDL_GPULitUniforms> & instances) {
    if (!models.data || !models.size || models.size>16384 || models.size%4) {
        SDL_SetError("GPU instancing: 1..4096 models, four columns each required"); return false;
    }
    instances.resize(models.size/4);
    for (size_t i=0;i<instances.size();++i) {
        SDL_GPU3DMatrix model; std::memcpy(&model,models.data+i*64,64);
        SDL_GPULight light{};
        if (!SDL_PrepareGPULit(model,model,{0,0,1,0},instances[i],light)) return false;
    }
    return true;
}

// Color ABI extends the existing model/normal record without changing its layout.
struct alignas(16) SDL_GPUColoredInstance { SDL_GPULitUniforms transform; float color[4]; };
static_assert(sizeof(SDL_GPUColoredInstance)==128 && offsetof(SDL_GPUColoredInstance,color)==112,"colored instance ABI");
inline bool SDL_PackGPUInstances(const das::TArray<das::float4> & models,
        const das::TArray<das::float4> * colors,std::vector<uint8_t> & bytes) {
    if (colors && (!colors->data || models.size%4 || colors->size!=models.size/4))
        return SDL_SetError("GPU instance colors: one RGBA per model required");
    std::vector<SDL_GPULitUniforms> transforms;
    if (!SDL_PrepareGPUInstances(models,transforms)) return false;
    const size_t stride=colors?128:112;
    bytes.resize(transforms.size()*stride);
    for (size_t i=0;i<transforms.size();++i) {
        std::memcpy(bytes.data()+i*stride,&transforms[i],112);
        if (colors) {
            float color[4]; std::memcpy(color,colors->data+i*16,16);
            for (float x:color) if (!std::isfinite(x) || x<0 || x>1)
                return SDL_SetError("GPU instance colors: finite RGBA in 0..1 required");
            std::memcpy(bytes.data()+i*stride+112,color,16);
        }
    }
    return true;
}

// Independent shader ABI; reuse the depth attachment and frame lifecycle helpers.
struct SDL_GPULitEntry : SDL_GPU3DEntry {
    SDL_GPUTexture * texture=nullptr;
    SDL_GPUSampler * sampler=nullptr;
    SDL_GPUBuffer * instances=nullptr;
    uint32_t instanceCount=0;
    SDL_GPUTransferBuffer * instanceUpload=nullptr;
    bool instancesReady=true;
    bool instanceColors=false;
};
inline std::unordered_map<uint64_t,SDL_GPULitEntry> SDL_GPULitMeshes;
inline void SDL_FreeGPULit(SDL_GPULitEntry & m) {
    if (m.instanceUpload) SDL_ReleaseGPUTransferBuffer(m.device,m.instanceUpload);
    m.instanceUpload=nullptr;
    if (m.instances) SDL_ReleaseGPUBuffer(m.device,m.instances);
    m.instances=nullptr; m.instanceCount=0;
    if (m.texture) SDL_ReleaseGPUTexture(m.device,m.texture);
    if (m.sampler) SDL_ReleaseGPUSampler(m.device,m.sampler);
    m.texture=nullptr; m.sampler=nullptr; SDL_FreeGPU3D(m);
}
inline void SDL_ReleaseGPULitForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPULitMeshes.begin();it!=SDL_GPULitMeshes.end();) {
        if (it->second.device==device) { SDL_FreeGPULit(it->second); it=SDL_GPULitMeshes.erase(it); }
        else ++it;
    }
}
inline const bool SDL_GPULitCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPULitForDevice);
inline SDL_GPULitEntry * SDL_FindGPULit(SDL_GPUDevice * device,uint64_t id) {
    auto it=SDL_GPULitMeshes.find(id);
    if (it==SDL_GPULitMeshes.end() || it->second.device!=device) {
        SDL_SetError("GPU lit: stale, invalid or foreign-device ID"); return nullptr;
    }
    return &it->second;
}
inline bool SDL_ReleaseGPULitMesh(SDL_GPUDevice * device,uint64_t id) {
    if (!SDL_IsMainThread()) return SDL_SetError("GPU lit: main thread required");
    auto * m=SDL_FindGPULit(device,id); if (!m) return false;
    SDL_FreeGPULit(*m); SDL_GPULitMeshes.erase(id); return true;
}
struct SDL_GPULitVertex { float position[4],normal[4],uv[2],padding[2]; };
static_assert(sizeof(SDL_GPULitVertex)==48 && offsetof(SDL_GPULitVertex,normal)==16 && offsetof(SDL_GPULitVertex,uv)==32,"lit vertex ABI");
inline bool SDL_GPULitSizes(uint32_t positions,uint32_t normals,uint32_t uv,uint32_t indices,uint32_t pixels,uint32_t width,uint32_t height) {
    return (positions<=349525 && positions==normals && positions==uv && SDL_GPUIndexCount(indices) &&
        SDL_GPUMeshSizes(positions,pixels,width,height,true)) || SDL_SetError("GPU lit: matching nonempty arrays and 16 MiB budgets required");
}
struct SDL_GPULitBuild {
    SDL_GPULitEntry mesh;
    SDL_GPUTransferBuffer * transfer=nullptr;
    SDL_GPUCommandBuffer * command=nullptr;
    ~SDL_GPULitBuild() {
        const std::string error=SDL_GetError();
        if (command) SDL_CancelGPUCommandBuffer(command);
        if (transfer) SDL_ReleaseGPUTransferBuffer(mesh.device,transfer);
        SDL_FreeGPULit(mesh); SDL_SetError("%s",error.c_str());
    }
};
inline bool SDL_PackGPULitGeometry(const das::TArray<das::float4> & positions,
        const das::TArray<das::float4> & normals,const das::TArray<das::float2> & uv,
        const das::TArray<uint32_t> & indices,std::vector<SDL_GPULitVertex> & packed) {
    if (!positions.size || positions.size>349525 || positions.size!=normals.size || positions.size!=uv.size || !SDL_GPUIndexCount(indices.size))
        return SDL_SetError("GPU geometry: matching nonempty arrays and 16 MiB budgets required");
    if (!positions.data || !normals.data || !uv.data || !indices.data) return SDL_SetError("GPU geometry: missing array storage");
    for (uint32_t i=0;i<indices.size;++i) {
        uint32_t index; std::memcpy(&index,indices.data+size_t(i)*4,4);
        if (index>=positions.size) { SDL_SetError("GPU 3D: index outside positions"); return false; }
    }
    packed.resize(positions.size);
    for (uint32_t i=0;i<positions.size;++i) {
        auto & v=packed[i]; std::memcpy(v.position,positions.data+size_t(i)*16,16); std::memcpy(v.normal,normals.data+size_t(i)*16,16); std::memcpy(v.uv,uv.data+size_t(i)*8,8);
        for (float x:v.position) if (!std::isfinite(x)) { SDL_SetError("GPU 3D: finite positions required"); return false; }
        if (v.position[3]!=1) { SDL_SetError("GPU 3D: position.w must be 1"); return false; }
        double length=0;
        for (float x:v.normal) { if (!std::isfinite(x)) { SDL_SetError("GPU lit: finite normal required"); return false; } }
        for (int j=0;j<3;++j) length+=double(v.normal[j])*v.normal[j];
        if (v.normal[3]!=0 || length<1e-12) { SDL_SetError("GPU lit: nonzero normal, w=0 required"); return false; }
        for (int j=0;j<3;++j) v.normal[j]=float(v.normal[j]/std::sqrt(length));
        for (float x:v.uv) if (!std::isfinite(x) || x<0 || x>1) { SDL_SetError("GPU lit: UV outside 0..1"); return false; }
    }
    return true;
}
inline SDL_GPUGraphicsPipeline * SDL_CreateGPULitPipeline(SDL_GPUDevice * device,SDL_GPUTextureFormat colorFormat,
        SDL_GPUTextureFormat depthFormat,const char * vertex,const char * fragment,uint32_t format,bool models,bool colors) {
    SDL_GPUShaderOwner vs{device},fs{device};
    vs.shader=SDL_LoadGPUMeshShader(device,vertex,format,SDL_GPU_SHADERSTAGE_VERTEX,true,0); if (!vs.shader) return 0;
    fs.shader=SDL_LoadGPUMeshShader(device,fragment,format,SDL_GPU_SHADERSTAGE_FRAGMENT,false,1,1); if (!fs.shader) return 0;
    SDL_GPUVertexBufferDescription buffers[2]{};
    buffers[0].pitch=48; buffers[0].input_rate=SDL_GPU_VERTEXINPUTRATE_VERTEX;
    buffers[1].slot=1; buffers[1].pitch=colors?128:112; buffers[1].input_rate=SDL_GPU_VERTEXINPUTRATE_INSTANCE;
    // SDL reserves instance_step_rate: it must remain zero, even for instance-rate input.
    SDL_GPUVertexAttribute attributes[11]{};
    for (uint32_t i=0;i<(colors?8u:7u);++i) {
        attributes[i+3].location=i+3; attributes[i+3].buffer_slot=1;
        attributes[i+3].format=SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4; attributes[i+3].offset=i*16;
    }
    attributes[0].format=SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4;
    attributes[1].location=1; attributes[1].format=SDL_GPU_VERTEXELEMENTFORMAT_FLOAT4; attributes[1].offset=16;
    attributes[2].location=2; attributes[2].format=SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2; attributes[2].offset=32;
    SDL_GPUColorTargetDescription target{}; target.format=colorFormat;
    SDL_GPUGraphicsPipelineCreateInfo pi{}; pi.vertex_shader=vs.shader; pi.fragment_shader=fs.shader;
    pi.primitive_type=SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
    pi.vertex_input_state.vertex_buffer_descriptions=buffers; pi.vertex_input_state.num_vertex_buffers=models?2:1;
    pi.vertex_input_state.vertex_attributes=attributes; pi.vertex_input_state.num_vertex_attributes=models?(colors?11:10):3;
    pi.rasterizer_state.fill_mode=SDL_GPU_FILLMODE_FILL; pi.rasterizer_state.cull_mode=SDL_GPU_CULLMODE_NONE;
    pi.rasterizer_state.enable_depth_clip=true; pi.multisample_state.sample_count=SDL_GPU_SAMPLECOUNT_1;
    pi.depth_stencil_state.enable_depth_test=true; pi.depth_stencil_state.enable_depth_write=true;
    pi.depth_stencil_state.compare_op=SDL_GPU_COMPAREOP_LESS;
    pi.target_info.color_target_descriptions=&target; pi.target_info.num_color_targets=1;
    pi.target_info.has_depth_stencil_target=true; pi.target_info.depth_stencil_format=depthFormat;
    return SDL_CreateGPUGraphicsPipeline(device,&pi);
}
inline uint64_t SDL_CreateGPULitForFormat(SDL_GPUDevice * device,SDL_GPUTextureFormat colorFormat,
        const das::TArray<das::float4> & positions,const das::TArray<das::float4> & normals,const das::TArray<das::float2> & uv,
        const das::TArray<uint8_t> & pixels,uint32_t width,uint32_t height,
        const das::TArray<uint32_t> & indices,const char * vertex,const char * fragment,uint32_t format,
        const das::TArray<das::float4> * models=nullptr,const das::TArray<das::float4> * colors=nullptr) {
    if (!SDL_IsMainThread() || !device) { SDL_SetError("GPU 3D: main thread and device required"); return 0; }
    if (!SDL_GPULitSizes(positions.size,normals.size,uv.size,indices.size,pixels.size,width,height)) return 0;
    if (!positions.data || !normals.data || !uv.data || !pixels.data || !indices.data) { SDL_SetError("GPU 3D: missing array storage"); return 0; }
    std::vector<uint8_t> instances;
    if (colors && !models) { SDL_SetError("GPU instance colors: models required"); return 0; }
    if (models && !SDL_PackGPUInstances(*models,colors,instances)) return 0;
    std::vector<SDL_GPULitVertex> packed;
    if (!SDL_PackGPULitGeometry(positions,normals,uv,indices,packed)) return 0;
    if ((format!=SDL_GPU_SHADERFORMAT_SPIRV && format!=SDL_GPU_SHADERFORMAT_DXIL) || !(SDL_GetGPUShaderFormats(device)&format)) {
        SDL_SetError("GPU 3D: unsupported shader format"); return 0;
    }
    if (SDL_GPUNextPipeline==std::numeric_limits<uint64_t>::max()) { SDL_SetError("GPU 3D: ID space exhausted"); return 0; }
    SDL_GPULitBuild build; auto & m=build.mesh; m.device=device; m.colorFormat=colorFormat; m.count=indices.size;
    m.depthFormat=SDL_GPU3DDepthFormat(device); if (m.depthFormat==SDL_GPU_TEXTUREFORMAT_INVALID) return 0;
    m.pipeline=SDL_CreateGPULitPipeline(device,colorFormat,m.depthFormat,vertex,fragment,format,models!=nullptr,colors!=nullptr);
    if (!m.pipeline) return 0;
    const uint32_t vertexBytes=positions.size*48, indexBytes=indices.size*4, instanceBytes=uint32_t(instances.size());
    SDL_GPUBufferCreateInfo bi{}; bi.usage=SDL_GPU_BUFFERUSAGE_VERTEX; bi.size=vertexBytes;
    m.vertices=SDL_CreateGPUBuffer(device,&bi); if (!m.vertices) return 0;
    bi.usage=SDL_GPU_BUFFERUSAGE_INDEX; bi.size=indexBytes;
    m.indices=SDL_CreateGPUBuffer(device,&bi); if (!m.indices) return 0;
    if (models) {
        bi.usage=SDL_GPU_BUFFERUSAGE_VERTEX; bi.size=instanceBytes;
        m.instances=SDL_CreateGPUBuffer(device,&bi); if (!m.instances) return 0;
        m.instanceCount=models->size/4;
        m.instanceColors=colors!=nullptr;
    }
    SDL_GPUTextureCreateInfo texture{}; texture.type=SDL_GPU_TEXTURETYPE_2D; texture.format=SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    texture.usage=SDL_GPU_TEXTUREUSAGE_SAMPLER; texture.width=width; texture.height=height;
    texture.layer_count_or_depth=texture.num_levels=1; texture.sample_count=SDL_GPU_SAMPLECOUNT_1;
    m.texture=SDL_CreateGPUTexture(device,&texture); if (!m.texture) return 0;
    SDL_GPUSamplerCreateInfo sampler{}; sampler.min_filter=sampler.mag_filter=SDL_GPU_FILTER_NEAREST;
    sampler.mipmap_mode=SDL_GPU_SAMPLERMIPMAPMODE_NEAREST;
    sampler.address_mode_u=sampler.address_mode_v=sampler.address_mode_w=SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
    m.sampler=SDL_CreateGPUSampler(device,&sampler); if (!m.sampler) return 0;
    const uint32_t textureOffset=(vertexBytes+indexBytes+instanceBytes+511u)&~511u;
    SDL_GPUTransferBufferCreateInfo ti{}; ti.usage=SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD; ti.size=textureOffset+pixels.size;
    build.transfer=SDL_CreateGPUTransferBuffer(device,&ti); if (!build.transfer) return 0;
    auto * bytes=static_cast<Uint8 *>(SDL_MapGPUTransferBuffer(device,build.transfer,false)); if (!bytes) return 0;
    std::memcpy(bytes,packed.data(),vertexBytes); std::memcpy(bytes+vertexBytes,indices.data,indexBytes);
    if (instanceBytes) std::memcpy(bytes+vertexBytes+indexBytes,instances.data(),instanceBytes);
    std::memcpy(bytes+textureOffset,pixels.data,pixels.size);
    SDL_UnmapGPUTransferBuffer(device,build.transfer);
    build.command=SDL_AcquireGPUCommandBuffer(device); if (!build.command) return 0;
    auto * copy=SDL_BeginGPUCopyPass(build.command); if (!copy) return 0;
    SDL_GPUTransferBufferLocation source{}; source.transfer_buffer=build.transfer;
    SDL_GPUBufferRegion dest{}; dest.buffer=m.vertices; dest.size=vertexBytes; SDL_UploadToGPUBuffer(copy,&source,&dest,false);
    source.offset=vertexBytes; dest.buffer=m.indices; dest.size=indexBytes; SDL_UploadToGPUBuffer(copy,&source,&dest,false);
    if (instanceBytes) {
        source.offset=vertexBytes+indexBytes; dest.buffer=m.instances; dest.size=instanceBytes;
        SDL_UploadToGPUBuffer(copy,&source,&dest,false);
    }
    SDL_GPUTextureTransferInfo texSource{}; texSource.transfer_buffer=build.transfer; texSource.offset=textureOffset;
    texSource.pixels_per_row=width; texSource.rows_per_layer=height;
    SDL_GPUTextureRegion texDest{}; texDest.texture=m.texture; texDest.w=width; texDest.h=height; texDest.d=1;
    SDL_UploadToGPUTexture(copy,&texSource,&texDest,false);
    SDL_EndGPUCopyPass(copy); auto * command=build.command; build.command=nullptr;
    if (!SDL_SubmitGPUCommandBuffer(command)) return 0;
    const uint64_t id=SDL_GPUNextPipeline++; SDL_GPULitMeshes.emplace(id,m);
    m={}; m.device=device; return id;
}
inline uint64_t SDL_CreateGPULitMesh(SDL_GPUDevice * device,SDL_Window * window,
        const das::TArray<das::float4> & positions,const das::TArray<das::float4> & normals,const das::TArray<das::float2> & uv,
        const das::TArray<uint8_t> & pixels,uint32_t width,uint32_t height,
        const das::TArray<uint32_t> & indices,const char * vertex,const char * fragment,uint32_t format) {
    if (!SDL_IsMainThread() || !SDL_GPUWindowClaimedBy(device,window)) { SDL_SetError("GPU 3D: main thread and claimed window required"); return 0; }
    return SDL_CreateGPULitForFormat(device,SDL_GetGPUSwapchainTextureFormat(device,window),positions,normals,uv,pixels,width,height,indices,vertex,fragment,format);
}

inline void SDL_RecordGPULit(SDL_GPURenderPass * pass,SDL_GPUCommandBuffer * command,const SDL_GPULitEntry & m,
        const SDL_GPULitUniforms & uniforms,const SDL_GPULight & light) {
    SDL_PushGPUVertexUniformData(command,0,&uniforms,sizeof(uniforms));
    SDL_PushGPUFragmentUniformData(command,0,&light,sizeof(light));
    SDL_BindGPUGraphicsPipeline(pass,m.pipeline);
    SDL_GPUBufferBinding buffer{}; buffer.buffer=m.vertices; SDL_BindGPUVertexBuffers(pass,0,&buffer,1);
    buffer.buffer=m.indices; SDL_BindGPUIndexBuffer(pass,&buffer,SDL_GPU_INDEXELEMENTSIZE_32BIT);
    SDL_GPUTextureSamplerBinding sample{}; sample.texture=m.texture; sample.sampler=m.sampler;
    SDL_BindGPUFragmentSamplers(pass,0,&sample,1);
    SDL_DrawGPUIndexedPrimitives(pass,m.count,1,0,0,0);
}
inline int SDL_DrawGPULitMesh(SDL_GPUDevice * device,SDL_Window * window,uint64_t id,
        das::float4 a,das::float4 b,das::float4 c,das::float4 d,
        das::float4 ma,das::float4 mb,das::float4 mc,das::float4 md,das::float4 light) {
    if (!SDL_IsMainThread()) { SDL_SetError("GPU lit: main thread required"); return -1; }
    SDL_GPULitUniforms uniforms{}; SDL_GPULight lighting{};
    if (!SDL_PrepareGPULit(SDL_GPU3DColumns(a,b,c,d),SDL_GPU3DColumns(ma,mb,mc,md),light,uniforms,lighting)) return -1;
    auto * m=SDL_FindGPULit(device,id); if (!m) return -1;
    if (m->instances) { SDL_SetError("GPU lit: instanced mesh requires instanced draw"); return -1; }
    if (!SDL_GPUWindowClaimedBy(device,window)) { SDL_SetError("GPU lit: unclaimed window"); return -1; }
    if (m->colorFormat!=SDL_GetGPUSwapchainTextureFormat(device,window)) { SDL_SetError("GPU lit: target format mismatch"); return -1; }
    uint32_t w=0,h=0;
    return SDL_GPUFrameWithTarget<SDL_GPUClearAPI>(device,window,{0,0,0,1},w,h,
        [m,&uniforms,&lighting](SDL_GPURenderPass * pass,SDL_GPUCommandBuffer * command) { SDL_RecordGPULit(pass,command,*m,uniforms,lighting); },
        [m](SDL_GPUCommandBuffer * command,const SDL_GPUColorTargetInfo & target,uint32_t width,uint32_t height) {
            return SDL_BeginGPU3DPass(command,target,*m,width,height);
        });
}
