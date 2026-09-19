#pragma once
#include <SDL3/SDL.h>
#include <cstdint>
#include <cstring>
#include <memory>
#include <string>
#include <unordered_map>
#include <limits>
#include <vector>
#include <algorithm>

using SDL_GPUDeviceCleanup = void (*)(SDL_GPUDevice *);
inline std::vector<SDL_GPUDeviceCleanup> SDL_GPUDeviceCleanups;
inline bool SDL_RegisterGPUDeviceCleanup(SDL_GPUDeviceCleanup cleanup) {
    if (std::find(SDL_GPUDeviceCleanups.begin(), SDL_GPUDeviceCleanups.end(), cleanup) == SDL_GPUDeviceCleanups.end())
        SDL_GPUDeviceCleanups.push_back(cleanup);
    return true;
}

// Main-thread-only registry. IDs never repeat within the process, including
// after device destruction. No native graphics-pipeline pointer reaches script.
struct SDL_GPUPipelineEntry {
    SDL_GPUDevice * device;
    SDL_GPUGraphicsPipeline * pipeline;
    SDL_GPUTextureFormat format;
};
inline std::unordered_map<uint64_t, SDL_GPUPipelineEntry> SDL_GPUPipelines;
inline uint64_t SDL_GPUNextPipeline = 1;
#ifdef DASSDL3_TESTING
inline int SDL_TestGPULiveShaders = 0;
inline bool SDL_TestGPUFailPipeline = false;
#endif

inline SDL_GPUPipelineEntry * SDL_FindGPUPipeline(SDL_GPUDevice * device, uint64_t id) {
    const auto it = SDL_GPUPipelines.find(id);
    if (it == SDL_GPUPipelines.end() || it->second.device != device) {
        SDL_SetError("GPU pipeline: stale, invalid or foreign-device handle"); return nullptr;
    }
    return &it->second;
}
inline bool SDL_ReleaseGPUVertexIDPipeline(SDL_GPUDevice * device, uint64_t id) {
    if (!SDL_IsMainThread()) return SDL_SetError("GPU pipeline: main thread required");
    const auto * entry = SDL_FindGPUPipeline(device, id);
    if (!entry) return false;
    SDL_ReleaseGPUGraphicsPipeline(device, entry->pipeline);
    SDL_GPUPipelines.erase(id);
    return true;
}
inline void SDL_ReleaseGPUPipelinesForDevice(SDL_GPUDevice * device) {
    for (auto it = SDL_GPUPipelines.begin(); it != SDL_GPUPipelines.end();) {
        if (it->second.device == device) {
            SDL_ReleaseGPUGraphicsPipeline(device, it->second.pipeline);
            it = SDL_GPUPipelines.erase(it);
        } else ++it;
    }
}
struct SDL_GPUShaderOwner {
    SDL_GPUDevice * device;
    SDL_GPUShader * shader = nullptr;
    ~SDL_GPUShaderOwner() {
        if (shader) {
            const std::string error = SDL_GetError();
            SDL_ReleaseGPUShader(device, shader);
#ifdef DASSDL3_TESTING
            --SDL_TestGPULiveShaders;
#endif
            SDL_SetError("%s", error.c_str());
        }
    }
};
inline SDL_GPUShader * SDL_LoadGPUZeroResourceShader(SDL_GPUDevice * device, const char * path,
                                                    uint32_t format, SDL_GPUShaderStage stage) {
    if (!path || !*path) { SDL_SetError("GPU shader: empty path"); return nullptr; }
    // Bound allocation before reading; SDL_LoadFile would allocate for any file size.
    auto * stream = SDL_IOFromFile(path, "rb");
    if (!stream) return nullptr;
    std::unique_ptr<SDL_IOStream, decltype(&SDL_CloseIO)> io(stream, SDL_CloseIO);
    const Sint64 length = SDL_GetIOSize(stream);
    if (length < 4 || length > 16 * 1024 * 1024) {
        SDL_SetError("GPU shader: size must be 4..16777216 bytes"); return nullptr;
    }
    std::unique_ptr<Uint8[]> code(new Uint8[size_t(length)]);
    if (SDL_ReadIO(stream, code.get(), size_t(length)) != size_t(length)) {
        SDL_SetError("GPU shader: incomplete read"); return nullptr;
    }
    const Uint8 spirvMagic[] = {3, 2, 35, 7};
    if ((format == SDL_GPU_SHADERFORMAT_SPIRV &&
         (length < 20 || length % 4 || std::memcmp(code.get(), spirvMagic, 4))) ||
        (format == SDL_GPU_SHADERFORMAT_DXIL && (length < 32 || std::memcmp(code.get(), "DXBC", 4)))) {
        SDL_SetError("GPU shader: invalid format header/size"); return nullptr;
    }
    // Trusted offline-validated assets only. Header checks are NOT shader reflection.
    SDL_GPUShaderCreateInfo info{};
    info.code = code.get(); info.code_size = size_t(length); info.entrypoint = "main";
    info.format = format; info.stage = stage;
    auto * shader = SDL_CreateGPUShader(device, &info);
#ifdef DASSDL3_TESTING
    if (shader) ++SDL_TestGPULiveShaders;
#endif
    return shader;
}
inline uint64_t SDL_CreateGPUVertexIDPipelineForFormat(SDL_GPUDevice * device, SDL_GPUTextureFormat target,
                                    const char * vertex, const char * fragment, uint32_t format) {
    if (!SDL_IsMainThread() || !device) { SDL_SetError("GPU pipeline: main thread and device required"); return 0; }
    if ((format != SDL_GPU_SHADERFORMAT_SPIRV && format != SDL_GPU_SHADERFORMAT_DXIL) ||
        !(SDL_GetGPUShaderFormats(device) & format)) {
        SDL_SetError("GPU pipeline: unsupported shader format (SPIR-V/DXIL required)"); return 0;
    }
    if (SDL_GPUNextPipeline == std::numeric_limits<uint64_t>::max()) {
        SDL_SetError("GPU pipeline: handle space exhausted"); return 0;
    }
    SDL_GPUShaderOwner vs{device}, fs{device};
    vs.shader = SDL_LoadGPUZeroResourceShader(device, vertex, format, SDL_GPU_SHADERSTAGE_VERTEX);
    if (!vs.shader) return 0;
    fs.shader = SDL_LoadGPUZeroResourceShader(device, fragment, format, SDL_GPU_SHADERSTAGE_FRAGMENT);
    if (!fs.shader) return 0;
#ifdef DASSDL3_TESTING
    if (SDL_TestGPUFailPipeline) { SDL_SetError("injected pipeline failure"); return 0; }
#endif
    SDL_GPUColorTargetDescription color{}; color.format = target;
    SDL_GPUGraphicsPipelineCreateInfo info{};
    info.vertex_shader = vs.shader; info.fragment_shader = fs.shader;
    info.primitive_type = SDL_GPU_PRIMITIVETYPE_TRIANGLELIST;
    info.rasterizer_state.fill_mode = SDL_GPU_FILLMODE_FILL;
    info.rasterizer_state.cull_mode = SDL_GPU_CULLMODE_NONE;
    info.rasterizer_state.enable_depth_clip = true;
    info.multisample_state.sample_count = SDL_GPU_SAMPLECOUNT_1;
    info.target_info.num_color_targets = 1; info.target_info.color_target_descriptions = &color;
    auto * pipeline = SDL_CreateGPUGraphicsPipeline(device, &info);
    if (!pipeline) return 0;
    const uint64_t id = SDL_GPUNextPipeline++;
    try { SDL_GPUPipelines.emplace(id, SDL_GPUPipelineEntry{device, pipeline, target}); }
    catch (...) { SDL_ReleaseGPUGraphicsPipeline(device, pipeline); throw; }
    return id;
}
