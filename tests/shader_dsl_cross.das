options gen2
require ../examples/gpu_dsl/dsl_shaders.das
require shader_dsl_pixels
require dassdl3/sdl3_shader_dsl_cross
require dassdl3/sdl3_scope

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        with_shadercross() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(SDL_GetPlatform() == "macOS" ? SDL_GPU_SHADERFORMAT_MSL : SDL_GPU_SHADERFORMAT_DXIL, true, SDL_GetPlatform() == "macOS" ? "metal" : "direct3d12") |> sdl_use
        var vertex : SDL_GPUShader? = device |> with_gpu_dsl_shader_cross(triangle_vertex, triangle_vertex_reflect) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_gpu_dsl_shader_cross(triangle_fragment, triangle_fragment_reflect) |> sdl_use
        return check_pixels(device, vertex, fragment)
    }
    if (is_err(result)) {print("{unwrap_err(result).message}\n"); return 1}
    print("Shader DSL reflection and pixels PASS\n"); return 0
}
