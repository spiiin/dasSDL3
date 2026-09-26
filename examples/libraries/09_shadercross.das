options gen2
require dassdl3/sdl3_shadercross_boost
require dassdl3/sdl3_scope

// Offline compilation and owned reflection. No GPU device is required.
[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_shadercross() |> sdl_use
        let info = SDL_ShaderCross_HLSL_Info(
            source = "float4 main(float2 uv : TEXCOORD0) : SV_Target0 \{ return float4(uv, 0.5, 1.0); \}",
            entrypoint = "main", shader_stage = SDL_ShaderCross_ShaderStage.SHADERSTAGE_FRAGMENT)
        var spirv <- compile_hlsl_spirv(info) |> sdl_try
        var reflected <- reflect_graphics_spirv(spirv) |> sdl_try
        let msl = transpile_spirv_msl(spirv, "main", info.shader_stage) |> sdl_try
        var dxil <- compile_spirv_dxil(spirv, "main", info.shader_stage) |> sdl_try
        print("SPIR-V: {length(spirv)} bytes; DXIL: {length(dxil)} bytes; MSL: {length(msl)} characters\n")
        print("Inputs: {length(reflected.inputs)}; outputs: {length(reflected.outputs)}\n")
        for (input in reflected.inputs) {print("Input {input.name}: location {int(input.location)}, components {int(input.vector_size)}\n")}
        return sdl_ok()
    }
    if (is_err(result)) {let error = unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1}
    return 0
}
