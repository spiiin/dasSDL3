#pragma once
#include "sdl3_gpu_mesh.h"
#include "gpu_triangle_probe.h"
namespace sdl3_test {
inline int gpu_meshes() { return int(SDL_GPUMeshes.size()); }
inline bool gpu_mesh_guards() {
    return SDL_GPUMeshSizes(6,16,2,2) && !SDL_GPUMeshSizes(0,16,2,2) &&
        !SDL_GPUMeshSizes(4,16,2,2) && !SDL_GPUMeshSizes(UINT32_MAX,16,2,2) &&
        !SDL_GPUMeshSizes(6,UINT32_MAX,UINT32_MAX,UINT32_MAX) &&
        !SDL_GPUMeshSizes(6,15,2,2) && !SDL_GPUMeshSizes(6,0,0,0) &&
        SDL_GPUMeshSizes(4,16,2,2,true) && !SDL_GPUIndexCount(0) &&
        !SDL_GPUIndexCount(4) && !SDL_GPUIndexCount(UINT32_MAX) && SDL_GPUIndexCount(6);
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
inline uint64_t gpu_indexed_mesh_offscreen(SDL_GPUDevice * device, const das::TArray<das::float4> & vertices,
        const das::TArray<uint32_t> & indices, const das::TArray<uint8_t> & pixels,
        const char * vertex, const char * fragment, uint32_t format) {
    return SDL_CreateGPUTexturedMeshForFormat(device, SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,
        vertices,pixels,2,2,vertex,fragment,format,&indices);
}
inline uint64_t gpu_transform_mesh_offscreen(SDL_GPUDevice * device, const das::TArray<das::float4> & vertices,
        const das::TArray<uint32_t> & indices, const das::TArray<uint8_t> & pixels,
        const char * vertex, const char * fragment, uint32_t format) {
    return SDL_CreateGPUTexturedMeshForFormat(device, SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,
        vertices,pixels,2,2,vertex,fragment,format,&indices,true);
}
inline bool gpu_transform_guards() {
    SDL_GPUTransform2D t{{1,0,0,0},{0,1,0,0}};
    if (!SDL_GPUTransformValid(t)) return false;
    t.x[2]=1; if (SDL_GPUTransformValid(t)) return false; t.x[2]=0;
    for (float v : {std::numeric_limits<float>::infinity(),std::numeric_limits<float>::quiet_NaN()}) {
        t.y[3]=v; if (SDL_GPUTransformValid(t)) return false;
    }
    return true;
}
inline bool gpu_mesh_pixels_impl(SDL_GPUDevice * device, uint64_t id, const SDL_GPUTransform2D * transform = nullptr) {
    const auto * mesh = SDL_FindGPUMesh(device,id); if (!mesh) return false;
    if (mesh->transform != (transform != nullptr)) return SDL_SetError("mesh fixture: uniform ABI mismatch");
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
    if (transform) SDL_PushGPUTransform(r.command,*transform);
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
        bool inside;
        int quadrant;
        if (transform) {
            const auto & t=*transform;
            const double det=double(t.x[0])*t.y[1]-double(t.x[1])*t.y[0];
            if (std::abs(det)<1e-8) return SDL_SetError("mesh fixture: singular reference transform");
            const double px=(x+0.5)/32.0-1-t.x[3], py=1-(y+0.5)/32.0-t.y[3];
            const double lx=(px*t.y[1]-py*t.x[1])/det, ly=(py*t.x[0]-px*t.y[0])/det;
            if (std::abs(std::abs(lx)-0.75)<0.025 || std::abs(std::abs(ly)-0.75)<0.025 ||
                std::abs(lx)<0.025 || std::abs(ly)<0.025) continue;
            inside=std::abs(lx)<0.75 && std::abs(ly)<0.75;
            quadrant=(ly<0 ? 2:0)+(lx>=0 ? 1:0);
        } else {
        if (x == 7 || x == 8 || x == 31 || x == 32 || x == 55 || x == 56 ||
            y == 7 || y == 8 || y == 31 || y == 32 || y == 55 || y == 56) continue;
        inside = x > 8 && x < 55 && y > 8 && y < 55;
        quadrant = (y >= 32 ? 2 : 0) + (x >= 32 ? 1 : 0);
        }
        for (int c = 0; c < 4; ++c) {
            int expected = inside ? colors[quadrant][c] : c == 3 ? 255 : 0;
            int actual = pixels[(y*64+x)*4+c];
            if (std::abs(actual-expected) > 1) return SDL_SetError("GPU mesh pixel x=%d y=%d channel=%d got=%d expected=%d",x,y,c,actual,expected);
        }
        ++checked;
    }
    return checked > 3000 || SDL_SetError("GPU mesh: insufficient checked pixels");
}
inline bool gpu_mesh_pixels(SDL_GPUDevice * device, uint64_t id) { return gpu_mesh_pixels_impl(device,id); }
inline bool gpu_transform_pixels(SDL_GPUDevice * device, uint64_t id, das::float4 x, das::float4 y) {
    const auto t=SDL_GPUTransformRows(x,y);
    return SDL_GPUTransformValid(t) && gpu_mesh_pixels_impl(device,id,&t);
}
}
