options gen2
require ../examples/gpu_dsl/compute_shaders.das
require ../examples/gpu_dsl/compute_support.das
require dassdl3/sdl3_scope

def check_compute_reflection {
    let info = gpu_dsl_compute_info(buffer_compute_reflect) |> unwrap
    verify(info.num_readwrite_storage_buffers == 1u && info.num_uniform_buffers == 1u)
    verify(info.threadcount_x == 64u && info.threadcount_y == 1u && info.threadcount_z == 1u)
    verify(info.num_readonly_storage_buffers == 0u && info.num_samplers == 0u)
    var empty : array<uint>
    verify(is_err(gpu_dsl_compute_info(empty)))
    // Each malformed field is tested independently against the real emitted wire form.
    let changes = fixed_array(int2(0, 0), int2(1, 2), int2(2, 0), int2(3, 0), int2(4, 0), int2(2, 1025), int2(4, 65), int2(5, -1))
    for (change in changes) {
        var bad <- clone_to_move(buffer_compute_reflect)
        bad[change.x] = uint(change.y)
        verify(is_err(gpu_dsl_compute_info(bad)))
    }
    for (i in 0 .. int(buffer_compute_reflect[5])) {
        let at = 6 + i * 5
        let invalid = fixed_array(int2(0, 0), int2(1, 1), int2(2, 255), int2(3, 2), int2(4, 1))
        for (change in invalid) {
            var bad <- clone_to_move(buffer_compute_reflect)
            bad[at + change.x] = uint(change.y)
            verify(is_err(gpu_dsl_compute_info(bad)))
        }
    }
    var trailing <- clone_to_move(buffer_compute_reflect); push(trailing, 0u)
    verify(is_err(gpu_dsl_compute_info(trailing)))
    var truncated <- clone_to_move(buffer_compute_reflect); pop(truncated)
    verify(is_err(gpu_dsl_compute_info(truncated)))
    var push_constant <- clone_to_move(buffer_compute_reflect); push_constant[length(push_constant) - 1] = 1u
    verify(is_err(gpu_dsl_compute_info(push_constant)))
    var duplicate <- [REFLECTION_MAGIC, 4u, 64u, 1u, 1u, 2u, 1u, 0u, 1u, 1u, 4u, 1u, 0u, 1u, 1u, 4u, 0u]
    verify(is_err(gpu_dsl_compute_info(duplicate)))
    var dimensions <- [REFLECTION_MAGIC, 4u, 32u, 2u, 1u, 0u, 0u]
    verify((gpu_dsl_compute_info(dimensions) |> unwrap).threadcount_y == 2u)
    dimensions[2] = 1024u
    verify(is_err(gpu_dsl_compute_info(dimensions)))
    // Out-of-order descriptors are valid when the slots themselves are dense.
    var shuffled <- [REFLECTION_MAGIC, 4u, 64u, 1u, 1u, 2u, 1u, 1u, 1u, 1u, 4u, 1u, 0u, 1u, 1u, 4u, 0u]
    verify((gpu_dsl_compute_info(shuffled) |> unwrap).num_readwrite_storage_buffers == 2u)
    var called = false
    let rejected = with_gpu_dsl_compute_pipeline(null, buffer_compute, duplicate) $(var pipeline : SDL_GPUComputePipeline?) : SdlStatus {
        called = true
        return sdl_ok()
    }
    verify(is_err(rejected) && !called)
}

[export]
def main(smoke : bool) : int {
    check_compute_reflection()
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV, true, "vulkan") |> sdl_use
        var pipeline : SDL_GPUComputePipeline? = device |> with_gpu_dsl_compute_pipeline(buffer_compute, buffer_compute_reflect) |> sdl_use
        return run_compute(device, pipeline)
    }
    if (is_err(result)) {print("Compute: {unwrap_err(result).message}\n"); return 1}
    return 0
}
