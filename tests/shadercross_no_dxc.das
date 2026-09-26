options gen2
require dassdl3/sdl3_shadercross_boost
require dassdl3/sdl3_iostream_boost
require dassdl3/sdl3_scope
[export]
def main(smoke : bool) : int {
    let result=sdl_scope() {
        with_shadercross() |> sdl_use
        verify((SDL_ShaderCross_GetHLSLShaderFormats() & SDL_GPU_SHADERFORMAT_SPIRV)==0u)
        verify((SDL_ShaderCross_GetSPIRVShaderFormats() & SDL_GPU_SHADERFORMAT_DXIL)==0u)
        var spirv <- load_file("{SDL_GetBasePath()}assets/libraries/shadercross-fixture.spv") |> sdl_try
        var reflection <- reflect_graphics_spirv(spirv) |> sdl_try
        verify(length(reflection.inputs)==1)
        let msl=transpile_spirv_msl(spirv,"main",SDL_ShaderCross_ShaderStage.SHADERSTAGE_FRAGMENT) |> sdl_try
        let hlsl=transpile_spirv_hlsl(spirv,"main",SDL_ShaderCross_ShaderStage.SHADERSTAGE_FRAGMENT) |> sdl_try
        verify(length(msl)>0 && length(hlsl)>0)
        let info=SDL_ShaderCross_HLSL_Info(source=hlsl,entrypoint="main",shader_stage=SDL_ShaderCross_ShaderStage.SHADERSTAGE_FRAGMENT)
        var unsupported <- compile_hlsl_spirv(info)
        verify(is_err(unsupported))
        var dxil <- compile_spirv_dxil(spirv,"main",info.shader_stage)
        verify(is_err(dxil))
        return sdl_ok()
    }
    if(is_err(result)) {let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    print("DXC disabled; SPIR-V reflection and translation: PASS\n")
    return 0
}
