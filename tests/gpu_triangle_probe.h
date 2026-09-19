#pragma once
#include "sdl3_gpu.h"
#include <array>
#include <cstdlib>
namespace sdl3_test {
inline int gpu_pipelines() { return int(SDL_GPUPipelines.size()); }
inline int gpu_shaders() { return SDL_TestGPULiveShaders; }
inline bool gpu_foreign_pipeline(SDL_GPUDevice * device, uint64_t id) {
    // Synthetic foreign identity: registry must reject before any SDL device access.
    static char token;
    auto * other = reinterpret_cast<SDL_GPUDevice *>(&token);
    uint32_t w = 9, h = 9;
    const bool rejected = SDL_DrawGPUVertexIDTriangle(other, nullptr, id, w, h) == -1 && !w && !h &&
        !SDL_ReleaseGPUVertexIDPipeline(other, id);
    return rejected && SDL_FindGPUPipeline(device, id);
}
inline bool gpu_pipeline_failure(SDL_GPUDevice * device, SDL_Window * window,
                                  const char * vertex, const char * fragment, uint32_t format) {
    SDL_TestGPUFailPipeline = true;
    uint64_t id = 0;
    try { id = SDL_CreateGPUVertexIDPipeline(device, window, vertex, fragment, format); }
    catch (...) { SDL_TestGPUFailPipeline = false; throw; }
    SDL_TestGPUFailPipeline = false;
    const bool expected = !id && std::string(SDL_GetError()) == "injected pipeline failure" && !SDL_TestGPULiveShaders;
    if (id) SDL_ReleaseGPUVertexIDPipeline(device, id);
    return expected;
}
struct GPUReadback {
    SDL_GPUDevice * device;
    uint64_t pipeline = 0;
    SDL_GPUTexture * texture = nullptr;
    SDL_GPUTransferBuffer * transfer = nullptr;
    SDL_GPUCommandBuffer * command = nullptr;
    SDL_GPUFence * fence = nullptr;
    bool submitted = false;
    ~GPUReadback() {
        const std::string error = SDL_GetError();
        if (command) SDL_CancelGPUCommandBuffer(command); // This fixture never acquires swapchain.
        if (submitted) SDL_WaitForGPUIdle(device);
        if (fence) SDL_ReleaseGPUFence(device, fence);
        if (transfer) SDL_ReleaseGPUTransferBuffer(device, transfer);
        if (texture) SDL_ReleaseGPUTexture(device, texture);
        if (pipeline) SDL_ReleaseGPUVertexIDPipeline(device, pipeline);
        SDL_SetError("%s", error.c_str());
    }
};
inline bool gpu_triangle_pixels(SDL_GPUDevice * device, const char * vertex, const char * fragment, uint32_t format) {
    GPUReadback r{device};
    r.pipeline = SDL_CreateGPUVertexIDPipelineForFormat(device, SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM, vertex, fragment, format);
    if (!r.pipeline) return false;
    SDL_GPUTextureCreateInfo texture{};
    texture.type = SDL_GPU_TEXTURETYPE_2D; texture.format = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    texture.usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET; texture.width = texture.height = 64;
    texture.layer_count_or_depth = texture.num_levels = 1; texture.sample_count = SDL_GPU_SAMPLECOUNT_1;
    r.texture = SDL_CreateGPUTexture(device, &texture);
    if (!r.texture) return false;
    SDL_GPUTransferBufferCreateInfo transfer{};
    transfer.usage = SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD; transfer.size = 64 * 64 * 4;
    r.transfer = SDL_CreateGPUTransferBuffer(device, &transfer);
    if (!r.transfer) return false;
    r.command = SDL_AcquireGPUCommandBuffer(device);
    if (!r.command) return false;
    SDL_GPUColorTargetInfo target{}; target.texture = r.texture;
    target.clear_color = {0,0,0,1}; target.load_op = SDL_GPU_LOADOP_CLEAR; target.store_op = SDL_GPU_STOREOP_STORE;
    auto * pass = SDL_BeginGPURenderPass(r.command, &target, 1, nullptr);
    if (!pass) return false;
    SDL_BindGPUGraphicsPipeline(pass, SDL_GPUPipelines.at(r.pipeline).pipeline);
    SDL_DrawGPUPrimitives(pass, 3, 1, 0, 0);
    SDL_EndGPURenderPass(pass);
    auto * copy = SDL_BeginGPUCopyPass(r.command);
    if (!copy) return false;
    SDL_GPUTextureRegion source{}; source.texture = r.texture; source.w = source.h = 64; source.d = 1;
    SDL_GPUTextureTransferInfo destination{}; destination.transfer_buffer = r.transfer;
    destination.pixels_per_row = destination.rows_per_layer = 64;
    SDL_DownloadFromGPUTexture(copy, &source, &destination);
    SDL_EndGPUCopyPass(copy);
    r.fence = SDL_SubmitGPUCommandBufferAndAcquireFence(r.command);
    r.command = nullptr; r.submitted = true;
    if (!r.fence || !SDL_WaitForGPUFences(device, true, &r.fence, 1)) return false;
    auto * data = static_cast<const Uint8 *>(SDL_MapGPUTransferBuffer(device, r.transfer, false));
    if (!data) return false;
    std::array<Uint8, 64 * 64 * 4> pixels{};
    std::memcpy(pixels.data(), data, pixels.size());
    SDL_UnmapGPUTransferBuffer(device, r.transfer);
    // Pixel centers against CPU barycentric reference; exclude a 2-pixel edge band.
    int checked = 0;
    for (int y = 0; y < 64; ++y) for (int x = 0; x < 64; ++x) {
        const float px = (x + 0.5f) / 32.0f - 1.0f;
        const float py = 1.0f - (y + 0.5f) / 32.0f;
        const float green = (py + 0.75f) / 1.5f;
        const float blue = ((1.0f - green) + px / 0.75f) * 0.5f;
        const float red = 1.0f - green - blue;
        const bool inside = red > 0.05f && green > 0.05f && blue > 0.05f;
        const bool outside = red < -0.05f || green < -0.05f || blue < -0.05f;
        if (!inside && !outside) continue;
        const auto * pixel = pixels.data() + (y * 64 + x) * 4;
        const float expected[] = {inside ? red : 0, inside ? green : 0, inside ? blue : 0, 1};
        for (int channel = 0; channel < 4; ++channel) {
            if (std::abs(int(pixel[channel]) - int(std::lround(expected[channel] * 255))) > 3)
                return SDL_SetError("GPU triangle pixel mismatch x=%d y=%d channel=%d got=%d expected=%d", x,y,channel,int(pixel[channel]),int(std::lround(expected[channel]*255)));
        }
        ++checked;
    }
    return checked > 3000 || SDL_SetError("GPU triangle: insufficient reference pixels");
}
}
