options gen2
require ../examples/gpu_dsl/texture_shaders.das
require shader_dsl_texture_pixels
require dassdl3/sdl3_shader_dsl_cross
require dassdl3/sdl3_scope

[export]
def main(smoke : bool) : int {
    let info = gpu_dsl_shader_info(texture_fragment_reflect) |> unwrap
    verify(info.num_samplers == 1u && info.num_uniform_buffers == 1u)
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        with_shadercross() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(SDL_GetPlatform() == "macOS" ? SDL_GPU_SHADERFORMAT_MSL : SDL_GPU_SHADERFORMAT_DXIL, true, SDL_GetPlatform() == "macOS" ? "metal" : "direct3d12") |> sdl_use
        var vertex : SDL_GPUShader? = device |> with_gpu_dsl_shader_cross(texture_vertex, texture_vertex_reflect) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_gpu_dsl_shader_cross(texture_fragment, texture_fragment_reflect) |> sdl_use
        return check_texture_pixels(device, vertex, fragment)
    }
    if (is_err(result)) {print("{unwrap_err(result).message}\n"); return 1}
    print("Shader DSL texture pixels PASS\n"); return 0
}
