options gen2
require ../examples/gpu_dsl/compute_shaders.das
require ../examples/gpu_dsl/compute_support.das
require dassdl3/sdl3_shader_dsl_cross
require dassdl3/sdl3_scope

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        with_shadercross() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(SDL_GetPlatform() == "macOS" ? SDL_GPU_SHADERFORMAT_MSL : SDL_GPU_SHADERFORMAT_DXIL, true, SDL_GetPlatform() == "macOS" ? "metal" : "direct3d12") |> sdl_use
        var pipeline : SDL_GPUComputePipeline? = device |> with_gpu_dsl_compute_pipeline_cross(buffer_compute, buffer_compute_reflect) |> sdl_use
        return run_compute(device, pipeline)
    }
    if (is_err(result)) {print("Compute: {unwrap_err(result).message}\n"); return 1}
    return 0
}
