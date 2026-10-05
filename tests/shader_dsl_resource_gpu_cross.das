options gen2
require shader_dsl_resource_shaders
require shader_dsl_resource_pixels
require dassdl3/sdl3_scope
require dassdl3/sdl3_shader_dsl_cross
[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        with_shadercross() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(SDL_GetPlatform() == "macOS" ? SDL_GPU_SHADERFORMAT_MSL : SDL_GPU_SHADERFORMAT_DXIL, true, SDL_GetPlatform() == "macOS" ? "metal" : "direct3d12") |> sdl_use
        var compute : SDL_GPUComputePipeline? = device |> with_gpu_dsl_compute_pipeline_cross(resource_compute, resource_compute_reflect, resource_compute_access) |> sdl_use
        var rmw : SDL_GPUComputePipeline? = device |> with_gpu_dsl_compute_pipeline_cross(rmw_compute, rmw_compute_reflect, rmw_compute_access) |> sdl_use
        var vertex : SDL_GPUShader? = device |> with_gpu_dsl_shader_cross(resource_vertex, resource_vertex_reflect, resource_vertex_access) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_gpu_dsl_shader_cross(resource_fragment, resource_fragment_reflect, resource_fragment_access) |> sdl_use
        return check_resources(device, compute, rmw, vertex, fragment)
    }
    if (is_err(result)) {print("{unwrap_err(result).message}\n"); return 1}
    print("Storage resources and std430 GPU PASS\n"); return 0
}
