#pragma once
#include "sdl3_gpu_transfer.h"
#include <memory>

inline constexpr uint32_t SDL_GPUShaderByteLimit=16u*1024u*1024u;
struct SDL_GPUOwnedShader {
    SDL_GPUDevice * device;
    SDL_GPUShader * shader;
    SDL_GPUShaderCreateInfo info; // Only exposed value fields; all pointers null.
    std::string entrypoint;
};
inline std::unordered_map<uint64_t,SDL_GPUOwnedShader> SDL_GPUOwnedShaders;
inline bool SDL_GPUValidateShaderInfo(const SDL_GPUShaderCreateInfo & info,const char * entrypoint) {
    if (info.format!=SDL_GPU_SHADERFORMAT_SPIRV && info.format!=SDL_GPU_SHADERFORMAT_DXIL &&
        info.format!=SDL_GPU_SHADERFORMAT_MSL && info.format!=SDL_GPU_SHADERFORMAT_METALLIB)
        return SDL_SetError("GPU shader: exactly one SPIR-V, DXIL, MSL or Metallib format required");
    if (info.stage!=SDL_GPU_SHADERSTAGE_VERTEX && info.stage!=SDL_GPU_SHADERSTAGE_FRAGMENT)
        return SDL_SetError("GPU shader: vertex or fragment stage required");
    // Pinned SDL_sysgpu.h MAX_*_PER_STAGE, not reflection of supplied bytecode.
    if (info.num_samplers>16 || info.num_storage_textures>8 || info.num_storage_buffers>8 || info.num_uniform_buffers>4)
        return SDL_SetError("GPU shader: resource limits are 16 samplers, 8 storage textures/buffers, 4 uniforms");
    if (info.props) return SDL_SetError("GPU shader: extension properties not supported by checked API");
    if (!entrypoint || !*entrypoint) return SDL_SetError("GPU shader: missing entry point");
    for (uint32_t i=0;;++i) {
        const unsigned char c=entrypoint[i]; if (!c) break;
        if (i>=127 || !((c>='a' && c<='z') || (c>='A' && c<='Z') || c=='_' || (i && c>='0' && c<='9')))
            return SDL_SetError("GPU shader: entry point must be an ASCII identifier of 1..127 characters");
    }
    return true;
}
inline bool SDL_GPUValidateShaderBytes(const uint8_t * bytes,uint64_t size,uint32_t format) {
    if (!bytes || size<4 || size>SDL_GPUShaderByteLimit) return SDL_SetError("GPU shader: bytecode size must be 4..16777216");
    const uint8_t spirv[]={3,2,35,7};
    if ((format==SDL_GPU_SHADERFORMAT_SPIRV && (size<20 || size%4 || std::memcmp(bytes,spirv,4))) ||
        (format==SDL_GPU_SHADERFORMAT_DXIL && (size<32 || std::memcmp(bytes,"DXBC",4))) ||
        (format==SDL_GPU_SHADERFORMAT_METALLIB && (size<16 || std::memcmp(bytes,"MTLB",4))))
        return SDL_SetError("GPU shader: invalid bytecode header/size");
    if (format==SDL_GPU_SHADERFORMAT_MSL) {
        auto zero=static_cast<const uint8_t *>(std::memchr(bytes,0,size_t(size)));
        if (zero && zero!=bytes+size-1) return SDL_SetError("GPU shader: embedded NUL in MSL source");
    }
    return true;
}
inline SDL_GPUShaderCreateInfo SDL_GPUShaderValueInfo(const SDL_GPUShaderCreateInfo & in) {
    SDL_GPUShaderCreateInfo out{};
    out.format=in.format; out.stage=in.stage; out.num_samplers=in.num_samplers;
    out.num_storage_textures=in.num_storage_textures; out.num_storage_buffers=in.num_storage_buffers;
    out.num_uniform_buffers=in.num_uniform_buffers; return out;
}
inline bool SDL_GPUCheckedShaderDevice(SDL_GPUDevice * device,const SDL_GPUShaderCreateInfo & info,const char * entrypoint) {
    if (!SDL_GPUTransferDevice(device) || !SDL_GPUTransferIDAvailable() || !SDL_GPUValidateShaderInfo(info,entrypoint)) return false;
    return (SDL_GetGPUShaderFormats(device)&info.format)!=0 || SDL_SetError("GPU shader: format not enabled on device");
}
// Internal: caller validated metadata/device and provides an aligned native copy.
inline uint64_t SDL_GPUCreateOwnedShader(SDL_GPUDevice * device,const uint32_t * code,uint32_t size,
        const SDL_GPUShaderCreateInfo & info,const char * entrypoint) {
    if (!SDL_GPUValidateShaderBytes(reinterpret_cast<const uint8_t *>(code),size,info.format)) return 0;
    auto values=SDL_GPUShaderValueInfo(info);
    std::string name(entrypoint);
    auto native=values; native.code=reinterpret_cast<const uint8_t *>(code); native.code_size=size; native.entrypoint=name.c_str();
    auto release=[device](SDL_GPUShader * shader) { SDL_ReleaseGPUShader(device,shader); };
    std::unique_ptr<SDL_GPUShader,decltype(release)> shader(SDL_CreateGPUShader(device,&native),release);
    if (!shader) return 0;
    const auto id=SDL_GPUNextResourceID++;
    SDL_GPUOwnedShaders.emplace(id,SDL_GPUOwnedShader{device,shader.get(),values,std::move(name)});
    shader.release(); return id;
}
inline uint64_t SDL_CreateGPUCheckedShader(SDL_GPUDevice * device,const das::TArray<uint8_t> & bytes,
        const SDL_GPUShaderCreateInfo & info,const char * entrypoint) {
    if (!SDL_GPUCheckedShaderDevice(device,info,entrypoint) ||
        !SDL_GPUValidateShaderBytes(reinterpret_cast<const uint8_t *>(bytes.data),bytes.size,info.format)) return 0;
    // Metal consumes a C string. A zero-initialized spare word guarantees a
    // terminator even when the caller's source size is a multiple of four.
    std::vector<uint32_t> code((bytes.size+3)/4+(info.format==SDL_GPU_SHADERFORMAT_MSL)); std::memcpy(code.data(),bytes.data,bytes.size);
    return SDL_GPUCreateOwnedShader(device,code.data(),uint32_t(bytes.size),info,entrypoint);
}
inline uint64_t SDL_LoadGPUCheckedShader(SDL_GPUDevice * device,const char * path,
        const SDL_GPUShaderCreateInfo & info,const char * entrypoint) {
    if (!SDL_GPUCheckedShaderDevice(device,info,entrypoint)) return 0;
    if (!path || !*path) { SDL_SetError("GPU shader: missing path"); return 0; }
    std::unique_ptr<SDL_IOStream,decltype(&SDL_CloseIO)> stream(SDL_IOFromFile(path,"rb"),SDL_CloseIO);
    if (!stream) return 0;
    const auto length=SDL_GetIOSize(stream.get());
    if (length<4 || length>SDL_GPUShaderByteLimit) { SDL_SetError("GPU shader: file size must be 4..16777216"); return 0; }
    std::vector<uint32_t> code((size_t(length)+3)/4+(info.format==SDL_GPU_SHADERFORMAT_MSL));
    if (SDL_ReadIO(stream.get(),code.data(),size_t(length))!=size_t(length)) {
        SDL_SetError("GPU shader: incomplete read"); return 0;
    }
    // Close before calling the driver so cleanup cannot overwrite its error.
    auto * consumed=stream.release(); if (!SDL_CloseIO(consumed)) return 0;
    return SDL_GPUCreateOwnedShader(device,code.data(),uint32_t(length),info,entrypoint);
}
inline bool SDL_ReleaseGPUCheckedShader(SDL_GPUDevice * device,uint64_t id) {
    auto * entry=SDL_GPUTransferFind(SDL_GPUOwnedShaders,device,id); if (!entry) return false;
    SDL_ReleaseGPUShader(device,entry->shader); SDL_GPUOwnedShaders.erase(id); return true;
}
inline bool SDL_GetGPUCheckedShaderInfo(SDL_GPUDevice * device,uint64_t id,SDL_GPUShaderCreateInfo & out) {
    out={}; const auto * entry=SDL_GPUTransferFind(SDL_GPUOwnedShaders,device,id); if (!entry) return false;
    out=entry->info; return true;
}
inline char * SDL_GetGPUCheckedShaderEntryPoint(SDL_GPUDevice * device,uint64_t id,das::Context * context,das::LineInfoArg * at) {
    const auto * entry=SDL_GPUTransferFind(SDL_GPUOwnedShaders,device,id); if (!entry) return nullptr;
    return context->allocateString(entry->entrypoint.c_str(),uint32_t(entry->entrypoint.size()),at);
}
inline void SDL_ReleaseGPUCheckedShadersForDevice(SDL_GPUDevice * device) {
    for (auto it=SDL_GPUOwnedShaders.begin();it!=SDL_GPUOwnedShaders.end();) {
        if (it->second.device!=device) { ++it; continue; }
        SDL_ReleaseGPUShader(device,it->second.shader); it=SDL_GPUOwnedShaders.erase(it);
    }
}
inline const bool SDL_GPUCheckedShaderCleanupRegistered=SDL_RegisterGPUDeviceCleanup(SDL_ReleaseGPUCheckedShadersForDevice);
