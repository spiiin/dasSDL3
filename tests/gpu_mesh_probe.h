#pragma once
#include "sdl3_gpu_mesh.h"
#include "gpu_triangle_probe.h"
namespace sdl3_test {
inline int gpu_meshes() { return int(SDL_GPUMeshes.size()); }
inline bool gpu_mesh_guards() {
    return SDL_GPUMeshSizes(6,16,2,2) && !SDL_GPUMeshSizes(0,16,2,2) &&
        !SDL_GPUMeshSizes(4,16,2,2) && !SDL_GPUMeshSizes(UINT32_MAX,16,2,2) &&
        !SDL_GPUMeshSizes(6,UINT32_MAX,UINT32_MAX,UINT32_MAX) &&
        !SDL_GPUMeshSizes(6,15,2,2) && !SDL_GPUMeshSizes(6,0,0,0);
}
inline bool gpu_mesh_foreign(SDL_GPUDevice * device, uint64_t id) {
    static char token;
    auto * other = reinterpret_cast<SDL_GPUDevice *>(&token);
    return !SDL_FindGPUMesh(other,id) && !SDL_ReleaseGPUTexturedMesh(other,id) &&
        !SDL_FindGPUPipeline(device,id) && SDL_FindGPUMesh(device,id);
}
inline uint64_t gpu_mesh_offscreen(SDL_GPUDevice * device, const das::TArray<das::float4> & vertices,
        const das::TArray<uint8_t> & pixels, const char * vertex, const char * fragment, uint32_t format) {
    return SDL_CreateGPUTexturedMeshForFormat(device, SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,
        vertices,pixels,2,2,vertex,fragment,format);
}
inline bool gpu_mesh_pixels(SDL_GPUDevice * device, uint64_t id) {
    const auto * mesh = SDL_FindGPUMesh(device,id); if (!mesh) return false;
    if (mesh->format != SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) return SDL_SetError("mesh fixture: target mismatch");
    GPUReadback r{device};
    SDL_GPUTextureCreateInfo texture{};
    texture.type = SDL_GPU_TEXTURETYPE_2D; texture.format = SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM;
    texture.usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET; texture.width = texture.height = 64;
    texture.layer_count_or_depth = texture.num_levels = 1; texture.sample_count = SDL_GPU_SAMPLECOUNT_1;
    r.texture = SDL_CreateGPUTexture(device,&texture); if (!r.texture) return false;
    SDL_GPUTransferBufferCreateInfo transfer{}; transfer.usage = SDL_GPU_TRANSFERBUFFERUSAGE_DOWNLOAD; transfer.size = 64*64*4;
    r.transfer = SDL_CreateGPUTransferBuffer(device,&transfer); if (!r.transfer) return false;
    r.command = SDL_AcquireGPUCommandBuffer(device); if (!r.command) return false;
    SDL_GPUColorTargetInfo target{}; target.texture = r.texture; target.clear_color = {0,0,0,1};
    target.load_op = SDL_GPU_LOADOP_CLEAR; target.store_op = SDL_GPU_STOREOP_STORE;
    auto * pass = SDL_BeginGPURenderPass(r.command,&target,1,nullptr); if (!pass) return false;
    SDL_RecordGPUMesh(pass,*mesh); SDL_EndGPURenderPass(pass);
    auto * copy = SDL_BeginGPUCopyPass(r.command); if (!copy) return false;
    SDL_GPUTextureRegion source{}; source.texture = r.texture; source.w = source.h = 64; source.d = 1;
    SDL_GPUTextureTransferInfo dest{}; dest.transfer_buffer = r.transfer; dest.pixels_per_row = dest.rows_per_layer = 64;
    SDL_DownloadFromGPUTexture(copy,&source,&dest); SDL_EndGPUCopyPass(copy);
    r.fence = SDL_SubmitGPUCommandBufferAndAcquireFence(r.command); r.command = nullptr; r.submitted = true;
    if (!r.fence || !SDL_WaitForGPUFences(device,true,&r.fence,1)) return false;
    auto * data = static_cast<const Uint8 *>(SDL_MapGPUTransferBuffer(device,r.transfer,false)); if (!data) return false;
    std::array<Uint8,64*64*4> pixels{}; std::memcpy(pixels.data(),data,pixels.size()); SDL_UnmapGPUTransferBuffer(device,r.transfer);
    int checked = 0;
    const int colors[4][4] = {{255,0,0,255},{0,255,0,255},{0,0,255,255},{255,255,0,255}};
    for (int y = 0; y < 64; ++y) for (int x = 0; x < 64; ++x) {
        // Quad NDC +-0.75 -> exact pixel boundaries 8..56. Skip boundary neighbors.
        if (x == 7 || x == 8 || x == 31 || x == 32 || x == 55 || x == 56 ||
            y == 7 || y == 8 || y == 31 || y == 32 || y == 55 || y == 56) continue;
        const bool inside = x > 8 && x < 55 && y > 8 && y < 55;
        const int quadrant = (y >= 32 ? 2 : 0) + (x >= 32 ? 1 : 0);
        for (int c = 0; c < 4; ++c) {
            int expected = inside ? colors[quadrant][c] : c == 3 ? 255 : 0;
            int actual = pixels[(y*64+x)*4+c];
            if (std::abs(actual-expected) > 1) return SDL_SetError("GPU mesh pixel x=%d y=%d channel=%d got=%d expected=%d",x,y,c,actual,expected);
        }
        ++checked;
    }
    return checked > 3000 || SDL_SetError("GPU mesh: insufficient checked pixels");
}
}
