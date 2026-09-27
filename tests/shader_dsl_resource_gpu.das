options gen2
require shader_dsl_resource_shaders
require shader_dsl_resource_pixels
require dassdl3/sdl3_scope
require dassdl3/sdl3_shader_compute
[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV, true, "vulkan") |> sdl_use
        var compute : SDL_GPUComputePipeline? = device |> with_gpu_dsl_compute_pipeline(resource_compute, resource_compute_reflect, resource_compute_access) |> sdl_use
        var rmw : SDL_GPUComputePipeline? = device |> with_gpu_dsl_compute_pipeline(rmw_compute, rmw_compute_reflect, rmw_compute_access) |> sdl_use
        var vertex : SDL_GPUShader? = device |> with_gpu_dsl_shader(resource_vertex, resource_vertex_reflect, resource_vertex_access) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_gpu_dsl_shader(resource_fragment, resource_fragment_reflect, resource_fragment_access) |> sdl_use
        return check_resources(device, compute, rmw, vertex, fragment)
    }
    if (is_err(result)) {print("{unwrap_err(result).message}\n"); return 1}
    print("Storage resources and std430 GPU PASS\n"); return 0
}
