options gen2
module sdl3_shadercross_boost shared public
require sdl3_shadercross public
require dassdl3/sdl3_result public
require daslib/defer

// A single application-owned session. Do not nest or quit inside the body.
def public with_shadercross(blk : block<() : $Result<auto(CrossValue); SdlError>>) : $Result<CrossValue; SdlError> {
    if(!SDL_ShaderCross_Init()) {return err(sdl_error("SDL_ShaderCross_Init"),type<CrossValue>)}
    var result : $Result<CrossValue; SdlError>
    {
        defer() {SDL_ShaderCross_Quit()}
        static_if(typeinfo can_copy(type<$Result<CrossValue; SdlError>>)) {result=blk()}
        else {result <- blk()}
    }
    return <- result
}
struct ShaderGraphicsReflection {
    resources : SDL_ShaderCross_GraphicsShaderResourceInfo
    inputs : array<SDL_ShaderCross_IOVarMetadata>
    outputs : array<SDL_ShaderCross_IOVarMetadata>
}
def public compile_hlsl_spirv(info : SDL_ShaderCross_HLSL_Info) {
    var bytes : array<uint8>
    if(!SDL_ShaderCross_CompileSPIRVFromHLSLBytes(info,bytes)) {return err(sdl_error("SDL_ShaderCross_CompileSPIRVFromHLSL"),type<array<uint8>>)}
    return <- move_ok(bytes,type<SdlError>)
}
def public compile_hlsl_dxil(info : SDL_ShaderCross_HLSL_Info) {
    var bytes : array<uint8>
    if(!SDL_ShaderCross_CompileDXILFromHLSLBytes(info,bytes)) {return err(sdl_error("SDL_ShaderCross_CompileDXILFromHLSL"),type<array<uint8>>)}
    return <- move_ok(bytes,type<SdlError>)
}
def public compile_hlsl_dxbc(info : SDL_ShaderCross_HLSL_Info) {
    var bytes : array<uint8>
    if(!SDL_ShaderCross_CompileDXBCFromHLSLBytes(info,bytes)) {return err(sdl_error("SDL_ShaderCross_CompileDXBCFromHLSL"),type<array<uint8>>)}
    return <- move_ok(bytes,type<SdlError>)
}
def public compile_spirv_dxil(bytes : array<uint8>; entry : string; stage : SDL_ShaderCross_ShaderStage; props : uint=0u) {
    var output : array<uint8>
    if(!SDL_ShaderCross_CompileDXILFromSPIRVBytes(bytes,entry,stage,props,output)) {return err(sdl_error("SDL_ShaderCross_CompileDXILFromSPIRV"),type<array<uint8>>)}
    return <- move_ok(output,type<SdlError>)
}
def public compile_spirv_dxbc(bytes : array<uint8>; entry : string; stage : SDL_ShaderCross_ShaderStage; props : uint=0u) {
    var output : array<uint8>
    if(!SDL_ShaderCross_CompileDXBCFromSPIRVBytes(bytes,entry,stage,props,output)) {return err(sdl_error("SDL_ShaderCross_CompileDXBCFromSPIRV"),type<array<uint8>>)}
    return <- move_ok(output,type<SdlError>)
}
def public transpile_spirv_msl(bytes : array<uint8>; entry : string; stage : SDL_ShaderCross_ShaderStage; props : uint=0u) {
    let text=SDL_ShaderCross_TranspileMSLFromSPIRVCopy(bytes,entry,stage,props)
    if(length(text)==0) {return err(sdl_error("SDL_ShaderCross_TranspileMSLFromSPIRV"),type<string>)}
    return ok(text,type<SdlError>)
}
def public transpile_spirv_hlsl(bytes : array<uint8>; entry : string; stage : SDL_ShaderCross_ShaderStage; props : uint=0u) {
    let text=SDL_ShaderCross_TranspileHLSLFromSPIRVCopy(bytes,entry,stage,props)
    if(length(text)==0) {return err(sdl_error("SDL_ShaderCross_TranspileHLSLFromSPIRV"),type<string>)}
    return ok(text,type<SdlError>)
}
def public reflect_graphics_spirv(bytes : array<uint8>; props : uint=0u) {
    var result : ShaderGraphicsReflection
    if(!SDL_ShaderCross_ReflectGraphicsBytes(bytes,props,result.resources,result.inputs,result.outputs)) {
        return err(sdl_error("SDL_ShaderCross_ReflectGraphicsSPIRV"),type<ShaderGraphicsReflection>)
    }
    return <- move_ok(result,type<SdlError>)
}
def public reflect_compute_spirv(bytes : array<uint8>; props : uint=0u) {
    var result : SDL_ShaderCross_ComputePipelineMetadata
    if(!SDL_ShaderCross_ReflectComputeBytes(bytes,props,result)) {
        return err(sdl_error("SDL_ShaderCross_ReflectComputeSPIRV"),type<SDL_ShaderCross_ComputePipelineMetadata>)
    }
    return ok(result,type<SdlError>)
}
def public compile_graphics_shader_spirv(device : SDL_GPUDevice?; bytes : array<uint8>; entry : string;
    stage : SDL_ShaderCross_ShaderStage; resources : SDL_ShaderCross_GraphicsShaderResourceInfo; props : uint=0u) {
    var shader=SDL_ShaderCross_CompileGraphicsShaderBytes(device,bytes,entry,stage,resources,props)
    if(shader==null) {return err(sdl_error("SDL_ShaderCross_CompileGraphicsShaderFromSPIRV"),type<SDL_GPUShader?>)}
    return <- move_ok(shader,type<SdlError>)
}
def public compile_compute_pipeline_spirv(device : SDL_GPUDevice?; bytes : array<uint8>; entry : string;
    metadata : SDL_ShaderCross_ComputePipelineMetadata; props : uint=0u) {
    var pipeline=SDL_ShaderCross_CompileComputePipelineBytes(device,bytes,entry,metadata,props)
    if(pipeline==null) {return err(sdl_error("SDL_ShaderCross_CompileComputePipelineFromSPIRV"),type<SDL_GPUComputePipeline?>)}
    return <- move_ok(pipeline,type<SdlError>)
}
