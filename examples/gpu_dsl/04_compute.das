options gen2
require backend_support
require compute_shaders
require compute_support
require dassdl3/sdl3_scope

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(dsl_example_formats(), true, "") |> sdl_use
        var pipeline : SDL_GPUComputePipeline? = device |> with_dsl_example_compute(buffer_compute, buffer_compute_reflect) |> sdl_use
        return run_compute(device, pipeline)
    }
    if (is_err(result)) {print("Compute: {unwrap_err(result).message}\n"); return 1}
    return 0
}
