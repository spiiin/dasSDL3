#pragma once
#include "sdl3_gpu_index_buffer.h"
#include <thread>
namespace sdl3_test {
inline int gpu_index_buffers() { return int(SDL_GPUCheckedIndexBuffers.size()); }
inline bool gpu_vertex_pixels(const das::TArray<uint8_t> & bytes,bool solid) {
    if (bytes.size!=64*64*4) return false;
    int checked=0;
    for (int y=0;y<64;++y) for (int x=0;x<64;++x) {
        const float px=(x+.5f)/32-1,py=1-(y+.5f)/32;
        const float g=(py+.75f)/1.5f,b=(1-g+px/.75f)*.5f,red=1-g-b;
        const bool inside=red>.05f && g>.05f && b>.05f, outside=red<-.05f || g<-.05f || b<-.05f;
        if (!inside && !outside) continue;
        const float expected[]={inside ? (solid ? 0 : red) : 0,inside ? (solid ? 0 : g) : 0,inside ? (solid ? 1 : b) : 0,1};
        for (int c=0;c<4;++c) if (std::abs(int(uint8_t(bytes.data[(y*64+x)*4+c]))-int(std::lround(expected[c]*255)))>3)
            return SDL_SetError("vertex pixel mismatch x=%d y=%d channel=%d",x,y,c);
        ++checked;
    }
    return checked>3000;
}
inline bool gpu_index_bad_arrays(SDL_GPUDevice * device) {
    uint32_t value=0; das::TArray<uint32_t> indices{};
    if (SDL_CreateGPUCheckedIndexBuffer(device,indices,SDL_GPU_INDEXELEMENTSIZE_16BIT)) return false;
    indices.data=reinterpret_cast<char *>(&value); indices.size=uint64_t(UINT32_MAX)+1;
    if (SDL_CreateGPUCheckedIndexBuffer(device,indices,SDL_GPU_INDEXELEMENTSIZE_16BIT)) return false;
    indices.size=1;
    if (SDL_CreateGPUCheckedIndexBuffer(device,indices,SDL_GPUIndexElementSize(9))) return false;
    value=65535;
    if (SDL_CreateGPUCheckedIndexBuffer(device,indices,SDL_GPU_INDEXELEMENTSIZE_16BIT)) return false;
    value=UINT32_MAX;
    if (SDL_CreateGPUCheckedIndexBuffer(device,indices,SDL_GPU_INDEXELEMENTSIZE_32BIT)) return false;
    value=0;
    bool rejected=false;
    std::thread thread([&] { rejected=SDL_CreateGPUCheckedIndexBuffer(device,indices,SDL_GPU_INDEXELEMENTSIZE_32BIT)==0; });
    thread.join();
    return rejected;
}
}
