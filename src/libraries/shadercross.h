#pragma once
#include "daScript/daScript.h"
#include "daScript/simulate/bind_enum.h"
#include <SDL3_shadercross/SDL_shadercross.h>
#include "generated/shadercross_casts.inc"
#include <memory>
static_assert(SDL_SHADERCROSS_MAJOR_VERSION==3 && SDL_SHADERCROSS_MINOR_VERSION==0 && SDL_SHADERCROSS_MICRO_VERSION==0);
namespace dassdl3_cross {
using Owned=std::unique_ptr<void,decltype(&SDL_free)>;
inline bool copy(void* data,size_t size,das::TArray<uint8_t>& out,das::Context* ctx,das::LineInfoArg* at) {
    Owned owner(data,SDL_free);
    if (!data) return false; // Preserve the compiler error before any SDL cleanup.
    if (size>INT_MAX) return SDL_SetError("Shader output exceeds INT_MAX");
    das::builtin_array_resize(out,uint32_t(size),1,ctx,at);
    if(size) std::memcpy(out.data,data,size);
    return true;
}
inline bool spirv(const das::TArray<uint8_t>& bytes,SDL_ShaderCross_SPIRV_Info& info,const char* entry,SDL_ShaderCross_ShaderStage stage,SDL_PropertiesID props) {
    if(!entry || !entry[0] || stage<SDL_SHADERCROSS_SHADERSTAGE_VERTEX || stage>SDL_SHADERCROSS_SHADERSTAGE_COMPUTE)
        return SDL_SetError("Invalid shader entrypoint or stage");
    uint32_t magic=0;
    if(bytes.size>=4) std::memcpy(&magic,bytes.data,4);
    if(bytes.size<20 || bytes.size%4 || magic!=0x07230203) return SDL_SetError("Invalid SPIR-V header or byte count");
    info={reinterpret_cast<const Uint8*>(bytes.data),bytes.size,entry,stage,props};return true;
}
inline bool hlsl(const SDL_ShaderCross_HLSL_Info& info) {
    if(info.shader_stage<SDL_SHADERCROSS_SHADERSTAGE_VERTEX || info.shader_stage>SDL_SHADERCROSS_SHADERSTAGE_COMPUTE) return SDL_SetError("Invalid HLSL shader stage");
    if(!info.source || !info.source[0] || !info.entrypoint || !info.entrypoint[0]) return SDL_SetError("HLSL source and entrypoint are required");
    return true;
}
}
inline bool SDL_ShaderCross_CompileSPIRVFromHLSLBytes(const SDL_ShaderCross_HLSL_Info& info,das::TArray<uint8_t>& out,das::Context* ctx,das::LineInfoArg* at) {
    if(!dassdl3_cross::hlsl(info)) return false;
    size_t size=0;void* data=SDL_ShaderCross_CompileSPIRVFromHLSL(&info,&size);
    return dassdl3_cross::copy(data,size,out,ctx,at);
}
inline bool SDL_ShaderCross_CompileDXILFromHLSLBytes(const SDL_ShaderCross_HLSL_Info& info,das::TArray<uint8_t>& out,das::Context* ctx,das::LineInfoArg* at) {
    if(!dassdl3_cross::hlsl(info)) return false;
    size_t size=0;void* data=SDL_ShaderCross_CompileDXILFromHLSL(&info,&size);
    return dassdl3_cross::copy(data,size,out,ctx,at);
}
inline bool SDL_ShaderCross_CompileDXBCFromHLSLBytes(const SDL_ShaderCross_HLSL_Info& info,das::TArray<uint8_t>& out,das::Context* ctx,das::LineInfoArg* at) {
    if(!dassdl3_cross::hlsl(info)) return false;
    size_t size=0;void* data=SDL_ShaderCross_CompileDXBCFromHLSL(&info,&size);
    return dassdl3_cross::copy(data,size,out,ctx,at);
}
inline bool SDL_ShaderCross_CompileDXILFromSPIRVBytes(const das::TArray<uint8_t>& bytes,const char* entry,SDL_ShaderCross_ShaderStage stage,uint32_t props,das::TArray<uint8_t>& out,das::Context* ctx,das::LineInfoArg* at) {
    SDL_ShaderCross_SPIRV_Info info{};
    if(!dassdl3_cross::spirv(bytes,info,entry,stage,props)) return false;
    size_t size=0;void* data=SDL_ShaderCross_CompileDXILFromSPIRV(&info,&size);
    return dassdl3_cross::copy(data,size,out,ctx,at);
}
inline bool SDL_ShaderCross_CompileDXBCFromSPIRVBytes(const das::TArray<uint8_t>& bytes,const char* entry,SDL_ShaderCross_ShaderStage stage,uint32_t props,das::TArray<uint8_t>& out,das::Context* ctx,das::LineInfoArg* at) {
    SDL_ShaderCross_SPIRV_Info info{};
    if(!dassdl3_cross::spirv(bytes,info,entry,stage,props)) return false;
    size_t size=0;void* data=SDL_ShaderCross_CompileDXBCFromSPIRV(&info,&size);
    return dassdl3_cross::copy(data,size,out,ctx,at);
}
inline char* SDL_ShaderCross_TranspileMSLFromSPIRVCopy(const das::TArray<uint8_t>& bytes,const char* entry,SDL_ShaderCross_ShaderStage stage,uint32_t props,das::Context* ctx,das::LineInfoArg* at) {
    SDL_ShaderCross_SPIRV_Info info{};
    if(!dassdl3_cross::spirv(bytes,info,entry,stage,props)) return nullptr;
    dassdl3_cross::Owned data(SDL_ShaderCross_TranspileMSLFromSPIRV(&info),SDL_free);
    return data ? ctx->allocateString(static_cast<const char*>(data.get()),at) : nullptr;
}
inline char* SDL_ShaderCross_TranspileHLSLFromSPIRVCopy(const das::TArray<uint8_t>& bytes,const char* entry,SDL_ShaderCross_ShaderStage stage,uint32_t props,das::Context* ctx,das::LineInfoArg* at) {
    SDL_ShaderCross_SPIRV_Info info{};
    if(!dassdl3_cross::spirv(bytes,info,entry,stage,props)) return nullptr;
    dassdl3_cross::Owned data(SDL_ShaderCross_TranspileHLSLFromSPIRV(&info),SDL_free);
    return data ? ctx->allocateString(static_cast<const char*>(data.get()),at) : nullptr;
}
inline bool SDL_ShaderCross_ReflectGraphicsBytes(const das::TArray<uint8_t>& bytes,uint32_t props,
    SDL_ShaderCross_GraphicsShaderResourceInfo& resources,das::TArray<SDL_ShaderCross_IOVarMetadata>& inputs,
    das::TArray<SDL_ShaderCross_IOVarMetadata>& outputs,das::Context* ctx,das::LineInfoArg* at) {
    SDL_ShaderCross_SPIRV_Info info{};
    if(!dassdl3_cross::spirv(bytes,info,"main",SDL_SHADERCROSS_SHADERSTAGE_VERTEX,props)) return false;
    auto meta=SDL_ShaderCross_ReflectGraphicsSPIRV(info.bytecode,info.bytecode_size,props);
    dassdl3_cross::Owned owner(meta,SDL_free);if(!meta) return false;
    resources=meta->resource_info;
    auto copy=[&](SDL_ShaderCross_IOVarMetadata* src,uint32_t count,das::TArray<SDL_ShaderCross_IOVarMetadata>& dst) {
        das::builtin_array_resize(dst,count,sizeof(*src),ctx,at);
        auto target=reinterpret_cast<SDL_ShaderCross_IOVarMetadata*>(dst.data);
        for(uint32_t i=0;i<count;++i) {target[i]=src[i];target[i].name=ctx->allocateString(src[i].name,at);}
    };
    copy(meta->inputs,meta->num_inputs,inputs);copy(meta->outputs,meta->num_outputs,outputs);return true;
}
inline bool SDL_ShaderCross_ReflectComputeBytes(const das::TArray<uint8_t>& bytes,uint32_t props,SDL_ShaderCross_ComputePipelineMetadata& result) {
    SDL_ShaderCross_SPIRV_Info info{};
    if(!dassdl3_cross::spirv(bytes,info,"main",SDL_SHADERCROSS_SHADERSTAGE_COMPUTE,props)) return false;
    auto meta=SDL_ShaderCross_ReflectComputeSPIRV(info.bytecode,info.bytecode_size,props);
    if(!meta) return false;
    result=*meta;SDL_free(meta);return true;
}
inline SDL_GPUShader* SDL_ShaderCross_CompileGraphicsShaderBytes(SDL_GPUDevice* device,const das::TArray<uint8_t>& bytes,
    const char* entry,SDL_ShaderCross_ShaderStage stage,const SDL_ShaderCross_GraphicsShaderResourceInfo& resources,uint32_t props) {
    if(!device || stage==SDL_SHADERCROSS_SHADERSTAGE_COMPUTE) {SDL_SetError("Invalid graphics device/stage");return nullptr;}
    SDL_ShaderCross_SPIRV_Info info{};
    if(!dassdl3_cross::spirv(bytes,info,entry,stage,0)) return nullptr;
    return SDL_ShaderCross_CompileGraphicsShaderFromSPIRV(device,&info,&resources,props);
}
inline SDL_GPUComputePipeline* SDL_ShaderCross_CompileComputePipelineBytes(SDL_GPUDevice* device,const das::TArray<uint8_t>& bytes,
    const char* entry,const SDL_ShaderCross_ComputePipelineMetadata& metadata,uint32_t props) {
    if(!device) {SDL_InvalidParamError("device");return nullptr;}
    SDL_ShaderCross_SPIRV_Info info{};
    if(!dassdl3_cross::spirv(bytes,info,entry,SDL_SHADERCROSS_SHADERSTAGE_COMPUTE,0)) return nullptr;
    return SDL_ShaderCross_CompileComputePipelineFromSPIRV(device,&info,&metadata,props);
}
