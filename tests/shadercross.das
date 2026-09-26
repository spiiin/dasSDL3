options gen2
require dassdl3/sdl3_shadercross_boost
require dassdl3/sdl3_scope
require daslib/defer

[export]
def main(smoke : bool) : int {
    verify(SDL_Init(SDL_INIT_VIDEO))
    var reflected : ShaderGraphicsReflection
    let result = sdl_scope() {
        with_shadercross() |> sdl_use
        let fragment = SDL_ShaderCross_HLSL_Info(source = "float4 main(float2 uv:TEXCOORD0):SV_Target0 \{return float4(uv,0.5,1);\}",
            entrypoint = "main", shader_stage = SDL_ShaderCross_ShaderStage.SHADERSTAGE_FRAGMENT)
        SDL_SetErrorText("stale error")
        var spirv <- compile_hlsl_spirv(fragment) |> sdl_try
        verify(length(spirv) > 20 && spirv[0] == uint8(3) && spirv[1] == uint8(2) && spirv[2] == uint8(35) && spirv[3] == uint8(7))
        reflected <- reflect_graphics_spirv(spirv) |> sdl_try
        verify(length(reflected.inputs) == 1 && length(reflected.outputs) == 1)
        verify(reflected.inputs[0].location == 0u && reflected.inputs[0].vector_size == 2u)
        verify(reflected.inputs[0].vector_type == SDL_ShaderCross_IOVarType.IOVAR_TYPE_FLOAT32)
        verify(reflected.resources.num_samplers == 0u && reflected.resources.num_uniform_buffers == 0u)
        let msl = transpile_spirv_msl(spirv, "main", fragment.shader_stage) |> sdl_try
        let hlsl = transpile_spirv_hlsl(spirv, "main", fragment.shader_stage) |> sdl_try
        verify(length(msl) > 0 && length(hlsl) > 0)
        var dxil <- compile_hlsl_dxil(fragment) |> sdl_try
        verify(length(dxil) > 0 && dxil[0] == uint8(68) && dxil[1] == uint8(88))
        var roundtrip <- compile_spirv_dxil(spirv, "main", fragment.shader_stage) |> sdl_try
        verify(length(roundtrip) > 0)
        if ((SDL_ShaderCross_GetSPIRVShaderFormats() & SDL_GPU_SHADERFORMAT_DXBC) != 0u) {
            var dxbc <- compile_spirv_dxbc(spirv, "main", fragment.shader_stage) |> sdl_try
            var from_source <- compile_hlsl_dxbc(fragment) |> sdl_try
            verify(length(dxbc) > 0 && length(from_source) > 0)
        }
        let compute = SDL_ShaderCross_HLSL_Info(source = "[numthreads(4,2,1)] void main(uint3 id:SV_DispatchThreadID) \{\}",
            entrypoint = "main", shader_stage = SDL_ShaderCross_ShaderStage.SHADERSTAGE_COMPUTE)
        var cs <- compile_hlsl_spirv(compute) |> sdl_try
        let metadata = reflect_compute_spirv(cs) |> sdl_try
        verify(metadata.threadcount_x == 4u && metadata.threadcount_y == 2u && metadata.threadcount_z == 1u)
        let device = SDL_CreateGPUDevice(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL, false, "vulkan")
        verify(device != null)
        {
            defer() {SDL_DestroyGPUDevice(device)}
            let shader = compile_graphics_shader_spirv(device, spirv, "main", fragment.shader_stage, reflected.resources) |> sdl_try
            {
                defer() {SDL_ReleaseGPUShader(device, shader)}
                let pipeline = compile_compute_pipeline_spirv(device, cs, "main", metadata) |> sdl_try
                SDL_ReleaseGPUComputePipeline(device, pipeline)
            }
        }
        let invalid = SDL_ShaderCross_HLSL_Info(source = "this is not HLSL", entrypoint = "main", shader_stage = fragment.shader_stage)
        var failed <- compile_hlsl_spirv(invalid)
        verify(is_err(failed))
        let saved = unwrap_err(failed)
        SDL_ClearError()
        verify(length(saved.message) > 0)
        var empty : array<uint8>
        var bad <- reflect_graphics_spirv(empty)
        verify(is_err(bad))
        var recovered <- compile_hlsl_spirv(fragment) |> sdl_try
        verify(length(recovered) == length(spirv))
        return sdl_ok()
    }
    SDL_Quit()
    if (is_err(result)) {let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1}
    verify(length(reflected.inputs[0].name) > 0)// Copy survives native metadata free and session shutdown.
    print("Shadercross compilation, reflection, owned outputs, errors and GPU objects: PASS\n")
    return 0
}
