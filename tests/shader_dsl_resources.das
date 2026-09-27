options gen2
require shader_dsl_resource_shaders
require dassdl3/sdl3_shader_compute
require dassdl3/sdl3_shader_storage_spirv

[export]
def main(smoke : bool) : int {
    let info = gpu_dsl_compute_info(resource_compute_reflect, resource_compute_access) |> unwrap
    verify(info.num_samplers == 1u && info.num_readonly_storage_buffers == 1u && info.num_readwrite_storage_buffers == 1u)
    verify(info.num_readonly_storage_textures == 1u && info.num_readwrite_storage_textures == 1u && info.num_uniform_buffers == 0u)
    verify(info.threadcount_x == 4u && info.threadcount_y == 4u)
    let vertex = gpu_dsl_shader_info(resource_vertex_reflect, resource_vertex_access) |> unwrap
    let fragment = gpu_dsl_shader_info(resource_fragment_reflect, resource_fragment_access) |> unwrap
    verify(vertex.num_samplers == 1u && vertex.num_storage_buffers == 1u && vertex.num_storage_textures == 1u)
    verify(fragment.num_samplers == 1u && fragment.num_storage_buffers == 1u && fragment.num_storage_textures == 1u)
    verify(is_err(gpu_dsl_compute_info(resource_compute_reflect)))
    verify(is_err(gpu_dsl_shader_info(resource_vertex_reflect)))
    var empty : array<uint>
    verify(is_err(gpu_dsl_compute_info(resource_compute_reflect, empty)))
    for (index in fixed_array(0, 1, 2, 3, 4)) {
        var bad <- clone_to_move(resource_compute_access)
        bad[index] = 0xffffffffu
        verify(is_err(gpu_dsl_compute_info(resource_compute_reflect, bad)))
    }
    for (i in 0 .. int(resource_compute_access[1])) {
        var bad <- clone_to_move(resource_compute_access)
        let at = 2 + i * 3
        bad[at + 2] = bad[at + 2] == 1u ? 3u : 1u
        verify(is_err(gpu_dsl_compute_info(resource_compute_reflect, bad)))
    }
    var duplicate <- clone_to_move(resource_compute_access)
    duplicate[5] = duplicate[2]; duplicate[6] = duplicate[3]
    verify(is_err(gpu_dsl_compute_info(resource_compute_reflect, duplicate)))
    var missing <- clone_to_move(resource_compute_access); pop(missing)
    verify(is_err(gpu_dsl_compute_info(resource_compute_reflect, missing)))
    for (i in 0 .. int(resource_compute_reflect[5])) {
        var bad <- clone_to_move(resource_compute_reflect)
        bad[6 + i * 5 + 3] = 2u
        verify(is_err(gpu_dsl_compute_info(bad, resource_compute_access)))
        bad <- clone_to_move(resource_compute_reflect)
        bad[6 + i * 5 + 1] = 99u
        verify(is_err(gpu_dsl_compute_info(bad, resource_compute_access)))
    }
    // Readonly metadata is required for graphics, including storage buffers.
    var writable <- clone_to_move(resource_fragment_access); writable[4] = 3u
    verify(is_err(gpu_dsl_shader_info(resource_fragment_reflect, writable)))
    var called = false
    let rejected = with_gpu_dsl_compute_pipeline(null, resource_compute, resource_compute_reflect, missing) $(var pipeline : SDL_GPUComputePipeline?) : SdlStatus {
        called = true; return sdl_ok()
    }
    verify(is_err(rejected) && !called)
    var a <- gpu_dsl_storage_spirv(resource_compute, resource_compute_reflect, resource_compute_access) |> move_unwrap
    var b <- gpu_dsl_storage_spirv(resource_compute, resource_compute_reflect, resource_compute_access) |> move_unwrap
    verify(length(a) == length(b)); for (i in 0 .. length(a)) {verify(a[i] == b[i])}
    verify(is_err(gpu_dsl_storage_spirv(empty, resource_compute_reflect, resource_compute_access)))
    var truncated <- clone_to_move(resource_compute); resize(truncated, 6)
    verify(is_err(gpu_dsl_storage_spirv(truncated, resource_compute_reflect, resource_compute_access)))
    print("SDL shader resources: metadata and lowering PASS\n")
    return 0
}
