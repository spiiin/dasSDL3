#pragma once
#include "sdl3_gpu_native.h"
#include <cstring>
#include <vector>
#include <algorithm>
#include <memory>

// Only synchronous argument conversion. Native pointers retain SDL ownership.
inline SDL_GPUDevice * SDL_CreateGPUDeviceDefault(uint32_t formats,bool debug,const char * driver) {
    return SDL_CreateGPUDevice(formats,debug,driver && *driver ? driver : nullptr);
}
inline SDL_GPUShader * SDL_CreateGPUShaderBytes(SDL_GPUDevice * device,
    const SDL_GPUShaderCreateInfo & info,const das::TArray<uint8_t> & bytes,const char * entrypoint) {
    if (!device || !sdl3_native_gpu::array_valid(bytes) || !bytes.size || !entrypoint || !*entrypoint) {
        SDL_SetError("GPU shader: device, nonempty bytecode and entrypoint required"); return nullptr;
    }
    if (info.format==SDL_GPU_SHADERFORMAT_SPIRV && (bytes.size<20 || bytes.size%4)) {
        SDL_SetError("GPU shader: SPIR-V byte count must be word aligned and include its header"); return nullptr;
    }
    // SDL Metal reads MSL as a C string, including for exactly word-sized input.
    std::vector<uint32_t> aligned((size_t(bytes.size)+3)/4+(info.format==SDL_GPU_SHADERFORMAT_MSL));
    std::memcpy(aligned.data(),bytes.data,size_t(bytes.size));
    auto native=info; native.code=reinterpret_cast<const uint8_t *>(aligned.data());
    native.code_size=size_t(bytes.size); native.entrypoint=entrypoint;
    return SDL_CreateGPUShader(device,&native);
}
inline SDL_GPUComputePipeline * SDL_CreateGPUComputePipelineBytes(SDL_GPUDevice * device,
    const SDL_GPUComputePipelineCreateInfo & info,const das::TArray<uint8_t> & bytes,const char * entrypoint) {
    if (!device || !sdl3_native_gpu::array_valid(bytes) || !bytes.size || !entrypoint || !*entrypoint) {
        SDL_SetError("GPU compute: device, nonempty bytecode and entrypoint required"); return nullptr;
    }
    if (info.format==SDL_GPU_SHADERFORMAT_SPIRV && (bytes.size<20 || bytes.size%4)) {
        SDL_SetError("GPU compute: SPIR-V byte count must be word aligned and include its header"); return nullptr;
    }
    std::vector<uint32_t> aligned((size_t(bytes.size)+3)/4+(info.format==SDL_GPU_SHADERFORMAT_MSL));
    std::memcpy(aligned.data(),bytes.data,size_t(bytes.size));
    auto native=info; native.code=reinterpret_cast<const uint8_t *>(aligned.data());
    native.code_size=size_t(bytes.size); native.entrypoint=entrypoint;
    return SDL_CreateGPUComputePipeline(device,&native);
}
inline SDL_GPUShader * SDL_LoadGPUShaderFile(SDL_GPUDevice * device,
    const SDL_GPUShaderCreateInfo & info,const char * path,const char * entrypoint) {
    size_t size=0; std::unique_ptr<void,decltype(&SDL_free)> bytes(SDL_LoadFile(path,&size),SDL_free);
    if (!bytes) return nullptr;
    das::TArray<uint8_t> view; view.data=static_cast<char *>(bytes.get()); view.size=size;
    return SDL_CreateGPUShaderBytes(device,info,view,entrypoint);
}
inline SDL_GPUComputePipeline * SDL_LoadGPUComputePipelineFile(SDL_GPUDevice * device,
    const SDL_GPUComputePipelineCreateInfo & info,const char * path,const char * entrypoint) {
    size_t size=0; std::unique_ptr<void,decltype(&SDL_free)> bytes(SDL_LoadFile(path,&size),SDL_free);
    if (!bytes) return nullptr;
    das::TArray<uint8_t> view; view.data=static_cast<char *>(bytes.get()); view.size=size;
    return SDL_CreateGPUComputePipelineBytes(device,info,view,entrypoint);
}
inline SDL_GPUGraphicsPipeline * SDL_CreateGPUGraphicsPipelineArrays(SDL_GPUDevice * device,
    const SDL_GPUGraphicsPipelineCreateInfo & info,
    const das::TArray<SDL_GPUVertexBufferDescription> & buffers,
    const das::TArray<SDL_GPUVertexAttribute> & attributes,
    const das::TArray<SDL_GPUColorTargetDescription> & colors) {
    if (!device || !info.vertex_shader || !info.fragment_shader ||
        !sdl3_native_gpu::array_valid(buffers) || !sdl3_native_gpu::array_valid(attributes) ||
        !sdl3_native_gpu::array_valid(colors)) { SDL_SetError("GPU pipeline: valid device, shaders and arrays required"); return nullptr; }
    if (buffers.size>16 || attributes.size>16 || colors.size>8) {
        SDL_SetError("GPU pipeline: SDL limits are 16 vertex buffers/attributes and 8 color targets"); return nullptr;
    }
    std::vector<SDL_GPUVertexBufferDescription> sorted;
    if(buffers.size) sorted.assign(sdl3_native_gpu::data(buffers),sdl3_native_gpu::data(buffers)+buffers.size);
    std::sort(sorted.begin(),sorted.end(),[](const auto & a,const auto & b){return a.slot<b.slot;});
    for(size_t i=0;i<sorted.size();++i) if(sorted[i].slot!=i) {
        SDL_SetError("GPU pipeline: pinned backend requires unique dense vertex slots"); return nullptr;
    }
    auto native=info;
    native.vertex_input_state={sorted.empty()?nullptr:sorted.data(),uint32_t(sorted.size()),sdl3_native_gpu::data(attributes),uint32_t(attributes.size)};
    native.target_info.color_target_descriptions=sdl3_native_gpu::data(colors);
    native.target_info.num_color_targets=uint32_t(colors.size);
    return SDL_CreateGPUGraphicsPipeline(device,&native);
}

// capacity is the size used to create this native transfer buffer. SDL has no
// size query: provenance, usage and fence completion remain caller preconditions.
// No mapped pointer/view escapes, and no script callback runs while mapped.
inline bool SDL_WriteGPUTransferBufferBytes(SDL_GPUDevice * device,SDL_GPUTransferBuffer * buffer,
    uint32_t capacity,uint32_t offset,const das::TArray<uint8_t> & bytes,bool cycle) {
    if(!device || !buffer || !sdl3_native_gpu::array_valid(bytes) || offset>capacity || bytes.size>capacity-offset)
        return SDL_SetError("GPU transfer write: invalid handle, array or declared capacity/range");
    if(!bytes.size)return true;
    void * mapped=SDL_MapGPUTransferBuffer(device,buffer,cycle); if(!mapped)return false;
    std::memcpy(static_cast<uint8_t *>(mapped)+offset,bytes.data,size_t(bytes.size));
    SDL_UnmapGPUTransferBuffer(device,buffer);return true;
}
inline bool SDL_ReadGPUTransferBufferBytes(SDL_GPUDevice * device,SDL_GPUTransferBuffer * buffer,
    uint32_t capacity,uint32_t offset,das::TArray<uint8_t> & bytes) {
    if(!device || !buffer || !sdl3_native_gpu::array_valid(bytes) || offset>capacity || bytes.size>capacity-offset)
        return SDL_SetError("GPU transfer read: invalid handle, array or declared capacity/range");
    if(!bytes.size)return true;
    void * mapped=SDL_MapGPUTransferBuffer(device,buffer,false); if(!mapped)return false;
    std::memcpy(bytes.data,static_cast<uint8_t *>(mapped)+offset,size_t(bytes.size));
    SDL_UnmapGPUTransferBuffer(device,buffer);return true;
}

inline SDL_GPUBuffer * SDL_CreateGPUBufferRef(SDL_GPUDevice * device,const SDL_GPUBufferCreateInfo & info) { return SDL_CreateGPUBuffer(device,&info); }

inline SDL_GPUTexture * SDL_CreateGPUTextureRef(SDL_GPUDevice * device,const SDL_GPUTextureCreateInfo & info) { return SDL_CreateGPUTexture(device,&info); }

inline SDL_GPUTransferBuffer * SDL_CreateGPUTransferBufferRef(SDL_GPUDevice * device,const SDL_GPUTransferBufferCreateInfo & info) { return SDL_CreateGPUTransferBuffer(device,&info); }

inline SDL_GPUSampler * SDL_CreateGPUSamplerRef(SDL_GPUDevice * device,const SDL_GPUSamplerCreateInfo & info) { return SDL_CreateGPUSampler(device,&info); }

inline void SDL_SetGPUViewportRef(SDL_GPURenderPass * handle,const SDL_GPUViewport & info) { SDL_SetGPUViewport(handle,&info); }

inline void SDL_SetGPUScissorRef(SDL_GPURenderPass * handle,const SDL_Rect & info) { SDL_SetGPUScissor(handle,&info); }

inline void SDL_BlitGPUTextureRef(SDL_GPUCommandBuffer * handle,const SDL_GPUBlitInfo & info) { SDL_BlitGPUTexture(handle,&info); }

inline void SDL_BindGPUIndexBufferRef(SDL_GPURenderPass * pass,const SDL_GPUBufferBinding & binding,SDL_GPUIndexElementSize size) { SDL_BindGPUIndexBuffer(pass,&binding,size); }

inline void SDL_UploadToGPUBufferRef(SDL_GPUCopyPass * pass,const SDL_GPUTransferBufferLocation & source,const SDL_GPUBufferRegion & destination,bool cycle) { SDL_UploadToGPUBuffer(pass,&source,&destination,cycle); }

inline void SDL_UploadToGPUTextureRef(SDL_GPUCopyPass * pass,const SDL_GPUTextureTransferInfo & source,const SDL_GPUTextureRegion & destination,bool cycle) { SDL_UploadToGPUTexture(pass,&source,&destination,cycle); }

inline void SDL_DownloadFromGPUBufferRef(SDL_GPUCopyPass * pass,const SDL_GPUBufferRegion & source,const SDL_GPUTransferBufferLocation & destination) { SDL_DownloadFromGPUBuffer(pass,&source,&destination); }

inline void SDL_DownloadFromGPUTextureRef(SDL_GPUCopyPass * pass,const SDL_GPUTextureRegion & source,const SDL_GPUTextureTransferInfo & destination) { SDL_DownloadFromGPUTexture(pass,&source,&destination); }

inline void SDL_CopyGPUBufferToBufferRef(SDL_GPUCopyPass * pass,const SDL_GPUBufferLocation & source,const SDL_GPUBufferLocation & destination,uint32_t size,bool cycle) { SDL_CopyGPUBufferToBuffer(pass,&source,&destination,size,cycle); }

inline void SDL_CopyGPUTextureToTextureRef(SDL_GPUCopyPass * pass,const SDL_GPUTextureLocation & source,const SDL_GPUTextureLocation & destination,uint32_t w,uint32_t h,uint32_t d,bool cycle) { SDL_CopyGPUTextureToTexture(pass,&source,&destination,w,h,d,cycle); }

inline SDL_GPURenderPass * SDL_BeginGPURenderPassDepthArray(SDL_GPUCommandBuffer * command,const das::TArray<SDL_GPUColorTargetInfo> & colors,const SDL_GPUDepthStencilTargetInfo & depth) { return SDL_BeginGPURenderPassArray(command,colors,&depth); }

// Float payloads use their native 32-bit representation; no script serialization.
inline bool SDL_WriteGPUTransferBufferFloats(SDL_GPUDevice * device, SDL_GPUTransferBuffer * buffer,
    uint32_t capacity, uint32_t offset, const das::TArray<float> & values, bool cycle) {
    if (!sdl3_native_gpu::array_valid(values) || values.size > UINT32_MAX / sizeof(float))
        return SDL_SetError("GPU float upload: invalid array or byte count overflow");
    das::TArray<uint8_t> bytes;
    bytes.data = values.data;
    bytes.size = values.size * sizeof(float);
    return SDL_WriteGPUTransferBufferBytes(device, buffer, capacity, offset, bytes, cycle);
}
inline bool SDL_PushGPUVertexUniformFloats(SDL_GPUCommandBuffer * command, uint32_t slot,
    const das::TArray<float> & values) {
    if (!command || !sdl3_native_gpu::array_valid(values) || values.size > UINT32_MAX / sizeof(float))
        return SDL_SetError("GPU float uniforms: invalid array or byte count overflow");
    das::TArray<uint8_t> bytes;
    bytes.data = values.data;
    bytes.size = values.size * sizeof(float);
    return SDL_PushGPUVertexUniformDataArray(command, slot, bytes);
}

inline bool SDL_PushGPUFragmentUniformFloats(SDL_GPUCommandBuffer * command, uint32_t slot,
    const das::TArray<float> & values) {
    if (!command || !sdl3_native_gpu::array_valid(values) || values.size > UINT32_MAX / sizeof(float))
        return SDL_SetError("GPU float uniforms: invalid array or byte count overflow");
    das::TArray<uint8_t> bytes;
    bytes.data = values.data;
    bytes.size = values.size * sizeof(float);
    return SDL_PushGPUFragmentUniformDataArray(command, slot, bytes);
}

inline bool SDL_PushGPUComputeUniformFloats(SDL_GPUCommandBuffer * command, uint32_t slot,
    const das::TArray<float> & values) {
    if (!command || !sdl3_native_gpu::array_valid(values) || values.size > UINT32_MAX / sizeof(float))
        return SDL_SetError("GPU float uniforms: invalid array or byte count overflow");
    das::TArray<uint8_t> bytes;
    bytes.data = values.data;
    bytes.size = values.size * sizeof(float);
    return SDL_PushGPUComputeUniformDataArray(command, slot, bytes);
}
