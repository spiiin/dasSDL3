#pragma once
#include "sdl3_gpu.h"
#include "daScript/daScript.h"
#include <array>
namespace sdl3_test {
struct GPUReadback {
    SDL_GPUDevice * device;
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
        SDL_SetError("%s", error.c_str());
    }
};
// Borrows a pipeline; readback resources are owned by the fixture.
inline bool gpu_triangle_native_pixels(SDL_GPUDevice * device,SDL_GPUGraphicsPipeline * pipeline,uint32_t mask=15,bool square=false) {
    GPUReadback r{device}; if (!pipeline) return false;
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
    SDL_BindGPUGraphicsPipeline(pass,pipeline);
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
        float expected[] = {inside ? red : 0, inside ? green : 0, inside ? blue : 0, 1};
        for (int c=0;c<4;++c) {
            if (square && c<3) expected[c]*=expected[c];
            if (!(mask & (1u<<c))) expected[c]=c==3 ? 1.0f : 0.0f;
        }
        for (int channel = 0; channel < 4; ++channel) {
            if (std::abs(int(pixel[channel]) - int(std::lround(expected[channel] * 255))) > 3)
                return SDL_SetError("GPU triangle pixel mismatch x=%d y=%d channel=%d got=%d expected=%d", x,y,channel,int(pixel[channel]),int(std::lround(expected[channel]*255)));
        }
        ++checked;
    }
    return checked > 3000 || SDL_SetError("GPU triangle: insufficient reference pixels");
}
inline bool gpu_bindings_pixels_reference(const das::TArray<uint8_t> & bytes,bool linear,bool split) {
    if (bytes.size!=64*64*4) return false;
    const float tex[4][3]={{1,0,0},{0,1,0},{0,0,1},{1,1,1}};
    const float tint[]={128.0f/255,.5f,128.0f/255};
    for (int y=0;y<64;++y) for (int x=0;x<64;++x) {
        const bool inside=x>=18 && x<54 && y>=18 && y<54;
        float expected[4]={0,0,0,1};
        if (inside) {
            const float u=(x+.5f-18)/36, v=(y+.5f-18)/36;
            if (linear) {
                const float fx=std::clamp(2*u-.5f,0.0f,1.0f),fy=std::clamp(2*v-.5f,0.0f,1.0f);
                for (int c=0;c<3;++c) expected[c]=((1-fy)*((1-fx)*tex[0][c]+fx*tex[1][c])+fy*((1-fx)*tex[2][c]+fx*tex[3][c]))*tint[c];
            } else {
                const int index=(v>=.5f ? 2 : 0)+(u>=.5f ? 1 : 0);
                for (int c=0;c<3;++c) expected[c]=tex[index][c]*tint[c];
            }
        }
        if (split && x>=32) expected[0]*=.5f;
        for (int c=0;c<4;++c) {
            const int actual=uint8_t(bytes.data[(y*64+x)*4+c]),ref=int(std::lround(expected[c]*255));
            if (std::abs(actual-ref)>2) return SDL_SetError("bindings pixel x=%d y=%d c=%d actual=%d expected=%d",x,y,c,actual,ref);
        }
    }
    return true;
}
}
