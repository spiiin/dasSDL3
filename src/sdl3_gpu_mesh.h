#pragma once
#include "sdl3_gpu.h"
#include "daScript/daScript.h"

// Bounded immutable 2D textured mesh, not a general shader/layout builder.
// Packed vertex = float4(NDC x, NDC y, normalized u, normalized v).
struct SDL_GPUMeshEntry {
    SDL_GPUDevice * device = nullptr;
    SDL_GPUGraphicsPipeline * pipeline = nullptr;
    SDL_GPUBuffer * vertices = nullptr;
    SDL_GPUBuffer * indices = nullptr;
    SDL_GPUTexture * texture = nullptr;
    SDL_GPUSampler * sampler = nullptr;
    SDL_GPUTextureFormat format = SDL_GPU_TEXTUREFORMAT_INVALID;
    uint32_t count = 0;
    bool transform = false;
};
inline std::unordered_map<uint64_t, SDL_GPUMeshEntry> SDL_GPUMeshes;
inline void SDL_FreeGPUMesh(SDL_GPUMeshEntry & m) {
    if (m.pipeline) SDL_ReleaseGPUGraphicsPipeline(m.device, m.pipeline);
    if (m.sampler) SDL_ReleaseGPUSampler(m.device, m.sampler);
    if (m.texture) SDL_ReleaseGPUTexture(m.device, m.texture);
    if (m.vertices) SDL_ReleaseGPUBuffer(m.device, m.vertices);
    if (m.indices) SDL_ReleaseGPUBuffer(m.device, m.indices);
    m.pipeline = nullptr; m.sampler = nullptr; m.texture = nullptr; m.vertices = nullptr;
    m.indices = nullptr;
}
inline void SDL_ReleaseGPUMeshesForDevice(SDL_GPUDevice * device) {
    for (auto it = SDL_GPUMeshes.begin(); it != SDL_GPUMeshes.end();) {
        if (it->second.device == device) { SDL_FreeGPUMesh(it->second); it = SDL_GPUMeshes.erase(it); }
        else ++it;
    }
}
inline const bool SDL_GPUMeshCleanupRegistered = SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPUMeshesForDevice);
inline SDL_GPUMeshEntry * SDL_FindGPUMesh(SDL_GPUDevice * device, uint64_t id) {
    const auto it = SDL_GPUMeshes.find(id);
    if (it == SDL_GPUMeshes.end() || it->second.device != device) {
        SDL_SetError("GPU mesh: stale, invalid or foreign-device handle"); return nullptr;
    }
    return &it->second;
}
inline bool SDL_ReleaseGPUTexturedMesh(SDL_GPUDevice * device, uint64_t id) {
    if (!SDL_IsMainThread()) return SDL_SetError("GPU mesh: main thread required");
    auto * entry = SDL_FindGPUMesh(device, id);
    if (!entry) return false;
    SDL_FreeGPUMesh(*entry); SDL_GPUMeshes.erase(id); return true;
}
inline bool SDL_GPUMeshSizes(uint32_t vertices, uint32_t pixels, uint32_t width, uint32_t height, bool indexed = false) {
    // Check sizes before multiplication, pointer access or GPU work. 16 MiB per input.
    if (!vertices || (!indexed && vertices % 3) || vertices > 1048576 || !width || !height ||
        width > 8192 || height > 8192 || uint64_t(width) * height * 4 > 16777216 ||
        uint64_t(width) * height * 4 != pixels)
        return SDL_SetError("GPU mesh: invalid triangle count or packed RGBA8 dimensions/byte budget");
    return true;
}
inline bool SDL_GPUIndexCount(uint32_t count) {
    return (count && count % 3 == 0 && count <= 4194304) ||
        SDL_SetError("GPU mesh: index count must be nonzero, divisible by 3 and at most 4194304");
}
struct SDL_GPUMeshBuild {
    SDL_GPUMeshEntry mesh;
    SDL_GPUTransferBuffer * transfer = nullptr;
    SDL_GPUCommandBuffer * command = nullptr;
    ~SDL_GPUMeshBuild() {
        const std::string error = SDL_GetError();
        if (command) SDL_CancelGPUCommandBuffer(command); // Upload never acquires a swapchain.
        if (transfer) SDL_ReleaseGPUTransferBuffer(mesh.device, transfer);
        SDL_FreeGPUMesh(mesh);
        SDL_SetError("%s", error.c_str());
    }
};
// Same bounded trusted-asset contract as triangle; fragment has exactly one sampler.
inline SDL_GPUShader * SDL_LoadGPUMeshShader(SDL_GPUDevice * device, const char * path,
                                            uint32_t format, SDL_GPUShaderStage stage, bool transform = false, uint32_t fragmentSamplers = 1) {
    if (!path || !*path) { SDL_SetError("GPU mesh shader: empty path"); return nullptr; }
    auto * stream = SDL_IOFromFile(path, "rb");
    if (!stream) return nullptr;
    std::unique_ptr<SDL_IOStream, decltype(&SDL_CloseIO)> io(stream, SDL_CloseIO);
    const Sint64 length = SDL_GetIOSize(stream);
    if (length < 4 || length > 16777216) { SDL_SetError("GPU mesh shader: invalid size"); return nullptr; }
    std::unique_ptr<Uint8[]> code(new Uint8[size_t(length)]);
    if (SDL_ReadIO(stream, code.get(), size_t(length)) != size_t(length)) { SDL_SetError("GPU mesh shader: incomplete read"); return nullptr; }
    const Uint8 magic[] = {3,2,35,7};
    if ((format == SDL_GPU_SHADERFORMAT_SPIRV && (length < 20 || length % 4 || std::memcmp(code.get(), magic, 4))) ||
        (format == SDL_GPU_SHADERFORMAT_DXIL && (length < 32 || std::memcmp(code.get(), "DXBC", 4)))) {
        SDL_SetError("GPU mesh shader: invalid format header/size"); return nullptr;
    }
    SDL_GPUShaderCreateInfo info{};
    info.code = code.get(); info.code_size = size_t(length); info.entrypoint = "main";
    info.format = format; info.stage = stage; info.num_samplers = stage == SDL_GPU_SHADERSTAGE_FRAGMENT ? fragmentSamplers : 0;
    info.num_uniform_buffers = transform && stage == SDL_GPU_SHADERSTAGE_VERTEX ? 1 : 0;
    auto * shader = SDL_CreateGPUShader(device, &info);
#ifdef DASSDL3_TESTING
    if (shader) ++SDL_TestGPULiveShaders;
#endif
    return shader;
}
inline uint64_t SDL_CreateGPUTexturedMeshForFormat(SDL_GPUDevice * device, SDL_GPUTextureFormat target,
        const das::TArray<das::float4> & vertices, const das::TArray<uint8_t> & pixels, uint32_t width, uint32_t height,
        const char * vertex, const char * fragment, uint32_t format, const das::TArray<uint32_t> * indices = nullptr, bool transform = false) {
    if (!SDL_IsMainThread() || !device) { SDL_SetError("GPU mesh: main thread and device required"); return 0; }
    if (!SDL_GPUMeshSizes(vertices.size, pixels.size, width, height, indices != nullptr)) return 0;
    if (indices) {
        if (!SDL_GPUIndexCount(indices->size)) return 0;
        if (!indices->data) { SDL_SetError("GPU mesh: missing index storage"); return 0; }
        for (uint32_t i = 0; i < indices->size; ++i) {
            uint32_t index; std::memcpy(&index, indices->data + size_t(i) * sizeof(index), sizeof(index));
            if (index >= vertices.size) { SDL_SetError("GPU mesh: index outside vertex array"); return 0; }
        }
    }
    if (!vertices.data || !pixels.data) { SDL_SetError("GPU mesh: missing array storage"); return 0; }
    static_assert(sizeof(das::float4) == 16, "packed float4 vertex ABI");
    for (uint32_t i = 0; i < vertices.size; ++i) {
        float v[4]; std::memcpy(v, vertices.data + size_t(i) * 16, 16);
        if (!std::isfinite(v[0]) || !std::isfinite(v[1]) || !std::isfinite(v[2]) || !std::isfinite(v[3]) ||
            v[2] < 0 || v[2] > 1 || v[3] < 0 || v[3] > 1) {
            SDL_SetError("GPU mesh: nonfinite position or UV outside 0..1"); return 0;
        }
    }
    if ((format != SDL_GPU_SHADERFORMAT_SPIRV && format != SDL_GPU_SHADERFORMAT_DXIL) ||
        !(SDL_GetGPUShaderFormats(device) & format)) { SDL_SetError("GPU mesh: unsupported shader format"); return 0; }
    if (SDL_GPUNextPipeline == std::numeric_limits<uint64_t>::max()) { SDL_SetError("GPU mesh: handle space exhausted"); return 0; }
    SDL_GPUMeshBuild build; auto & m = build.mesh;
    m.device = device; m.format = target; m.count = indices ? indices->size : vertices.size;
    m.transform = transform;
    SDL_GPUShaderOwner vs{device}, fs{device};
    vs.shader = SDL_LoadGPUMeshShader(device, vertex, format, SDL_GPU_SHADERSTAGE_VERTEX, transform);
    if (!vs.shader) return 0;
    fs.shader = SDL_LoadGPUMeshShader(device, fragment, format, SDL_GPU_SHADERSTAGE_FRAGMENT);
    if (!fs.shader) return 0;
    SDL_GPUVertexBufferDescription buffer{}; buffer.slot = 0; buffer.pitch = 16; buffer.input_rate = SDL_GPU_VERTEXINPUTRATE_VERTEX;
    SDL_GPUVertexAttribute attrs[2]{};
    attrs[0].location = 0; attrs[0].buffer_slot = 0; attrs[0].format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2; attrs[0].offset = 0;
    attrs[1].location = 1; attrs[1].buffer_slot = 0; attrs[1].format = SDL_GPU_VERTEXELEMENTFORMAT_FLOAT2; attrs[1].offset = 8;
    SDL_GPUColorTargetDescription color{}; color.format = target;
    SDL_GPUGraphicsPipelineCreateInfo pi{};
    pi.vertex_shader = vs.shader; pi.fragment_shader = fs.shader; pi.primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
    pi.vertex_input_state.vertex_buffer_descriptions = &buffer; pi.vertex_input_state.num_vertex_buffers = 1;
    pi.vertex_input_state.vertex_attributes = attrs; pi.vertex_input_state.num_vertex_attributes = 2;
    pi.rasterizer_state.fill_mode = SDL_GPU_FILLMODE_FILL; pi.rasterizer_state.cull_mode = SDL_GPU_CULLMODE_NONE;
    pi.rasterizer_state.enable_depth_clip = true; pi.multisample_state.sample_count = SDL_GPU_SAMPLECOUNT_1;
    pi.target_info.color_target_descriptions = &color; pi.target_info.num_color_targets = 1;
    m.pipeline = SDL_CreateGPUGraphicsPipeline(device, &pi); if (!m.pipeline) return 0;
    const uint32_t vertexBytes = vertices.size * 16;
    SDL_GPUBufferCreateInfo bi{}; bi.usage = SDL_GPU_BUFFERUSAGE_VERTEX; bi.size = vertexBytes;
    m.vertices = SDL_CreateGPUBuffer(device, &bi); if (!m.vertices) return 0;
    const uint32_t indexBytes = indices ? indices->size * uint32_t(sizeof(uint32_t)) : 0;
    if (indices) {
        bi.usage = SDL_GPU_BUFFERUSAGE_INDEX; bi.size = indexBytes;
        m.indices = SDL_CreateGPUBuffer(device, &bi); if (!m.indices) return 0;
    }
    SDL_GPUTextureCreateInfo ti{};
    ti.type = SDL_GPU_TEXTURETYPE_2D; ti.format = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM; ti.usage = SDL_GPU_TEXTUREUSAGE_SAMPLER;
    ti.width = width; ti.height = height; ti.layer_count_or_depth = ti.num_levels = 1; ti.sample_count = SDL_GPU_SAMPLECOUNT_1;
    m.texture = SDL_CreateGPUTexture(device, &ti); if (!m.texture) return 0;
    SDL_GPUSamplerCreateInfo si{};
    si.min_filter = si.mag_filter = SDL_GPU_FILTER_NEAREST; si.mipmap_mode = SDL_GPU_SAMPLERMIPMAPMODE_NEAREST;
    si.address_mode_u = si.address_mode_v = si.address_mode_w = SDL_GPU_SAMPLERADDRESSMODE_CLAMP_TO_EDGE;
    m.sampler = SDL_CreateGPUSampler(device, &si); if (!m.sampler) return 0;
    // Vertex and texture bytes share staging storage; align texture offset for D3D12.
    const uint32_t textureOffset = (vertexBytes + indexBytes + 511u) & ~511u;
    SDL_GPUTransferBufferCreateInfo transfer{}; transfer.usage = SDL_GPU_TRANSFERBUFFERUSAGE_UPLOAD; transfer.size = textureOffset + pixels.size;
    build.transfer = SDL_CreateGPUTransferBuffer(device, &transfer); if (!build.transfer) return 0;
    auto * mapped = static_cast<Uint8 *>(SDL_MapGPUTransferBuffer(device, build.transfer, false)); if (!mapped) return 0;
    std::memcpy(mapped, vertices.data, vertexBytes); std::memcpy(mapped + textureOffset, pixels.data, pixels.size);
    if (indices) std::memcpy(mapped + vertexBytes, indices->data, indexBytes);
    SDL_UnmapGPUTransferBuffer(device, build.transfer);
    build.command = SDL_AcquireGPUCommandBuffer(device); if (!build.command) return 0;
    auto * copy = SDL_BeginGPUCopyPass(build.command); if (!copy) return 0;
    SDL_GPUTransferBufferLocation source{}; source.transfer_buffer = build.transfer;
    SDL_GPUBufferRegion dest{}; dest.buffer = m.vertices; dest.size = vertexBytes;
    SDL_UploadToGPUBuffer(copy, &source, &dest, false);
    if (indices) {
        source.offset = vertexBytes; dest.buffer = m.indices; dest.size = indexBytes;
        SDL_UploadToGPUBuffer(copy, &source, &dest, false);
    }
    SDL_GPUTextureTransferInfo texSource{}; texSource.transfer_buffer = build.transfer; texSource.offset = textureOffset;
    texSource.pixels_per_row = width; texSource.rows_per_layer = height;
    SDL_GPUTextureRegion texDest{}; texDest.texture = m.texture; texDest.w = width; texDest.h = height; texDest.d = 1;
    SDL_UploadToGPUTexture(copy, &texSource, &texDest, false);
    SDL_EndGPUCopyPass(copy);
    auto * command = build.command; build.command = nullptr; // Submit always consumes.
    if (!SDL_SubmitGPUCommandBuffer(command)) return 0;
    const uint64_t id = SDL_GPUNextPipeline++; // Shared ID namespace prevents cross-kind aliasing.
    SDL_GPUMeshes.emplace(id, m); // build owns resources if insertion throws.
    m = {}; // Registry now owns every resource; staging buffer can be released after submit.
    m.device = device;
    return id;
}
inline uint64_t SDL_CreateGPUTexturedMesh(SDL_GPUDevice * device, SDL_Window * window,
        const das::TArray<das::float4> & vertices, const das::TArray<uint8_t> & pixels, uint32_t width, uint32_t height,
        const char * vertex, const char * fragment, uint32_t format) {
    if (!SDL_IsMainThread() || !SDL_GPUWindowClaimedBy(device, window)) { SDL_SetError("GPU mesh: main thread and claimed window required"); return 0; }
    return SDL_CreateGPUTexturedMeshForFormat(device, SDL_GetGPUSwapchainTextureFormat(device, window), vertices, pixels, width, height, vertex, fragment, format);
}
inline uint64_t SDL_CreateGPUIndexedTexturedMesh(SDL_GPUDevice * device, SDL_Window * window,
        const das::TArray<das::float4> & vertices, const das::TArray<uint32_t> & indices,
        const das::TArray<uint8_t> & pixels, uint32_t width, uint32_t height,
        const char * vertex, const char * fragment, uint32_t format) {
    if (!SDL_IsMainThread() || !SDL_GPUWindowClaimedBy(device, window)) { SDL_SetError("GPU mesh: main thread and claimed window required"); return 0; }
    return SDL_CreateGPUTexturedMeshForFormat(device, SDL_GetGPUSwapchainTextureFormat(device, window), vertices, pixels, width, height, vertex, fragment, format, &indices);
}
inline void SDL_RecordGPUMesh(SDL_GPURenderPass * pass, const SDL_GPUMeshEntry & m) {
    SDL_BindGPUGraphicsPipeline(pass, m.pipeline);
    SDL_GPUBufferBinding vertex{}; vertex.buffer = m.vertices;
    SDL_BindGPUVertexBuffers(pass, 0, &vertex, 1);
    SDL_GPUTextureSamplerBinding sample{}; sample.texture = m.texture; sample.sampler = m.sampler;
    SDL_BindGPUFragmentSamplers(pass, 0, &sample, 1);
    if (m.indices) {
        SDL_GPUBufferBinding index{}; index.buffer = m.indices;
        SDL_BindGPUIndexBuffer(pass, &index, SDL_GPU_INDEXELEMENTSIZE_32BIT);
        SDL_DrawGPUIndexedPrimitives(pass, m.count, 1, 0, 0, 0);
    } else SDL_DrawGPUPrimitives(pass, m.count, 1, 0, 0);
}
inline int SDL_DrawGPUTexturedMesh(SDL_GPUDevice * device, SDL_Window * window, uint64_t id) {
    if (!SDL_IsMainThread()) { SDL_SetError("GPU mesh: main thread required"); return -1; }
    const auto * m = SDL_FindGPUMesh(device, id); if (!m) return -1;
    if (m->transform) { SDL_SetError("GPU mesh: transform uniforms required"); return -1; }
    if (!SDL_GPUWindowClaimedBy(device, window)) { SDL_SetError("GPU mesh: unclaimed window"); return -1; }
    if (m->format != SDL_GetGPUSwapchainTextureFormat(device, window)) { SDL_SetError("GPU mesh: incompatible target format"); return -1; }
    uint32_t w = 0, h = 0;
    return SDL_GPUFrame<SDL_GPUClearAPI>(device, window, {0,0,0,1}, w, h,
        [m](SDL_GPURenderPass * pass, SDL_GPUCommandBuffer *) { SDL_RecordGPUMesh(pass, *m); });
}

struct alignas(16) SDL_GPUTransform2D { float x[4]; float y[4]; };
static_assert(sizeof(SDL_GPUTransform2D) == 32 && offsetof(SDL_GPUTransform2D, y) == 16, "std140 two vec4 rows");
inline bool SDL_GPUTransformValid(const SDL_GPUTransform2D & t) {
    for (float v : t.x) if (!std::isfinite(v)) return SDL_SetError("GPU transform: finite rows required");
    for (float v : t.y) if (!std::isfinite(v)) return SDL_SetError("GPU transform: finite rows required");
    if (t.x[2] != 0 || t.y[2] != 0) return SDL_SetError("GPU transform: row z must be zero for 2D");
    return true;
}
inline SDL_GPUTransform2D SDL_GPUTransformRows(const das::float4 & x, const das::float4 & y) {
    SDL_GPUTransform2D t; std::memcpy(t.x, &x, 16); std::memcpy(t.y, &y, 16); return t;
}
inline void SDL_PushGPUTransform(SDL_GPUCommandBuffer * command, const SDL_GPUTransform2D & t) {
    SDL_PushGPUVertexUniformData(command, 0, &t, sizeof(t));
}
inline uint64_t SDL_CreateGPUTransformMesh(SDL_GPUDevice * device, SDL_Window * window,
        const das::TArray<das::float4> & vertices, const das::TArray<uint32_t> & indices,
        const das::TArray<uint8_t> & pixels, uint32_t width, uint32_t height,
        const char * vertex, const char * fragment, uint32_t format) {
    if (!SDL_IsMainThread() || !SDL_GPUWindowClaimedBy(device, window)) { SDL_SetError("GPU mesh: main thread and claimed window required"); return 0; }
    return SDL_CreateGPUTexturedMeshForFormat(device, SDL_GetGPUSwapchainTextureFormat(device, window), vertices, pixels, width, height, vertex, fragment, format, &indices, true);
}
inline int SDL_DrawGPUTransformMesh(SDL_GPUDevice * device, SDL_Window * window, uint64_t id, das::float4 x, das::float4 y) {
    if (!SDL_IsMainThread()) { SDL_SetError("GPU transform: main thread required"); return -1; }
    const auto t = SDL_GPUTransformRows(x,y);
    if (!SDL_GPUTransformValid(t)) return -1;
    const auto * m = SDL_FindGPUMesh(device,id); if (!m) return -1;
    if (!m->transform) { SDL_SetError("GPU mesh: transform shader ABI required"); return -1; }
    if (!SDL_GPUWindowClaimedBy(device,window)) { SDL_SetError("GPU mesh: unclaimed window"); return -1; }
    if (m->format != SDL_GetGPUSwapchainTextureFormat(device,window)) { SDL_SetError("GPU mesh: incompatible target format"); return -1; }
    uint32_t w=0,h=0;
    return SDL_GPUFrame<SDL_GPUClearAPI>(device,window,{0,0,0,1},w,h,
        [m,&t](SDL_GPURenderPass * pass, SDL_GPUCommandBuffer * command) {
            SDL_PushGPUTransform(command,t); SDL_RecordGPUMesh(pass,*m);
        });
}
