#include "libraries/shadercross.h"
#include <cstdio>
#include <cstring>
#define CHECK(x) do {if(!(x)) {std::fprintf(stderr,"Failed: %s: %s\n",#x,SDL_GetError());return 1;}} while(0)
int main() {
    CHECK(SDL_Init(SDL_INIT_VIDEO));CHECK(SDL_ShaderCross_Init());
    CHECK(SDL_ShaderCross_GetHLSLShaderFormats()&SDL_GPU_SHADERFORMAT_SPIRV);
    const char* source="float4 main(float2 uv:TEXCOORD0):SV_Target0 {return float4(uv,0.5,1);}";
    SDL_ShaderCross_HLSL_Info hlsl{source,"main",nullptr,nullptr,SDL_SHADERCROSS_SHADERSTAGE_FRAGMENT,0};
    size_t size=0;auto spv=SDL_ShaderCross_CompileSPIRVFromHLSL(&hlsl,&size);CHECK(spv && size>20);
    SDL_ShaderCross_SPIRV_Info info{static_cast<Uint8*>(spv),size,"main",hlsl.shader_stage,0};
    auto metadata=SDL_ShaderCross_ReflectGraphicsSPIRV(info.bytecode,size,0);CHECK(metadata);
    CHECK(metadata->num_inputs==1 && metadata->inputs[0].vector_size==2);
    CHECK(metadata->num_outputs==1);
    auto msl=SDL_ShaderCross_TranspileMSLFromSPIRV(&info);CHECK(msl);SDL_free(msl);
    auto translated=SDL_ShaderCross_TranspileHLSLFromSPIRV(&info);CHECK(translated);SDL_free(translated);
    size_t compiled_size=0;
    auto dxil=SDL_ShaderCross_CompileDXILFromSPIRV(&info,&compiled_size);CHECK(dxil && compiled_size>4);CHECK(!std::memcmp(dxil,"DXBC",4));SDL_free(dxil);
    dxil=SDL_ShaderCross_CompileDXILFromHLSL(&hlsl,&compiled_size);CHECK(dxil && compiled_size>4);SDL_free(dxil);
    if(SDL_ShaderCross_GetSPIRVShaderFormats()&SDL_GPU_SHADERFORMAT_DXBC) {
        auto dxbc=SDL_ShaderCross_CompileDXBCFromSPIRV(&info,&compiled_size);CHECK(dxbc && compiled_size>4);SDL_free(dxbc);
        dxbc=SDL_ShaderCross_CompileDXBCFromHLSL(&hlsl,&compiled_size);CHECK(dxbc && compiled_size>4);SDL_free(dxbc);
    } else {std::puts("DXBC runtime unavailable: skipped DXBC compilation");}
    SDL_ShaderCross_HLSL_Info compute{"[numthreads(4,2,1)] void main(uint3 id:SV_DispatchThreadID) {}","main",nullptr,nullptr,SDL_SHADERCROSS_SHADERSTAGE_COMPUTE,0};
    size_t compute_size=0;auto cs=SDL_ShaderCross_CompileSPIRVFromHLSL(&compute,&compute_size);CHECK(cs);
    auto cm=SDL_ShaderCross_ReflectComputeSPIRV(static_cast<Uint8*>(cs),compute_size,0);CHECK(cm && cm->threadcount_x==4 && cm->threadcount_y==2);
    SDL_ShaderCross_SPIRV_Info ci{static_cast<Uint8*>(cs),compute_size,"main",compute.shader_stage,0};
    for(const char* backend:{"vulkan","direct3d12"}) {
        auto device=SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_SPIRV|SDL_GPU_SHADERFORMAT_DXIL,false,backend);CHECK(device);
        auto shader=SDL_ShaderCross_CompileGraphicsShaderFromSPIRV(device,&info,&metadata->resource_info,0);CHECK(shader);
        auto pipeline=SDL_ShaderCross_CompileComputePipelineFromSPIRV(device,&ci,cm,0);CHECK(pipeline);
        SDL_ReleaseGPUComputePipeline(device,pipeline);SDL_ReleaseGPUShader(device,shader);SDL_DestroyGPUDevice(device);
    }
    SDL_free(cm);SDL_free(cs);SDL_free(metadata);SDL_free(spv);
    SDL_ShaderCross_Quit();SDL_Quit();std::puts("All shadercross raw APIs; Vulkan/D3D12 objects: PASS");return 0;
}
