options gen2
require ../examples/gpu_dsl/dsl_shaders.das
require shader_dsl_pixels
require dassdl3/sdl3_shader_dsl
require dassdl3/sdl3_scope

def check_reflection {
    let v = gpu_dsl_shader_info(triangle_vertex_reflect) |> unwrap
    let f = gpu_dsl_shader_info(triangle_fragment_reflect) |> unwrap
    verify(v.stage == SDL_GPUShaderStage.SHADERSTAGE_VERTEX && v.num_uniform_buffers == 0u)
    verify(f.stage == SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT && f.num_uniform_buffers == 1u && f.num_samplers == 0u)
    var bad : array<uint>
    verify(is_err(gpu_dsl_shader_info(bad)))
    verify(is_err(gpu_dsl_spirv_bytes(bad)))
    bad <- clone_to_move(triangle_fragment_reflect)
    bad[6] = 0u; verify(is_err(gpu_dsl_shader_info(bad)))// Wrong fragment set.
    bad[6] = 3u; bad[7] = 1u; verify(is_err(gpu_dsl_shader_info(bad)))// Gap.
    bad[7] = 0u; bad[9] = 2u; verify(is_err(gpu_dsl_shader_info(bad)))// Descriptor array.
    bad[9] = 1u; bad[8] = uint(int(SpirvDescriptorKind.storage_buffer)); verify(is_err(gpu_dsl_shader_info(bad)))
    bad <- clone_to_move(triangle_fragment_reflect)
    bad[1] = 4u; verify(is_err(gpu_dsl_shader_info(bad)))// Compute is not this profile.
    bad[1] = 2u; bad[5] = 0xffffffffu; verify(is_err(gpu_dsl_shader_info(bad)))
    bad <- clone_to_move(triangle_fragment_reflect)
    pop(bad); verify(is_err(gpu_dsl_shader_info(bad)))
    var duplicate <- [REFLECTION_MAGIC, 2u, 1u, 1u, 1u, 2u, 3u, 0u, 0u, 1u, 2u, 3u, 0u, 0u, 1u, 2u, 0u]
    verify(is_err(gpu_dsl_shader_info(duplicate)))
    var sampler <- [REFLECTION_MAGIC, 2u, 1u, 1u, 1u, 1u, 2u, 0u, 2u, 1u, 2u, 0u]
    verify((gpu_dsl_shader_info(sampler) |> unwrap).num_samplers == 1u)
    var bytes <- gpu_dsl_spirv_bytes(triangle_vertex) |> move_unwrap
    verify(length(bytes) == length(triangle_vertex) * 4 && bytes[0] == uint8(3) && bytes[1] == uint8(2) && bytes[2] == uint8(35) && bytes[3] == uint8(7))
}

[export]
def main(smoke : bool) : int {
    check_reflection()
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV, true, "vulkan") |> sdl_use
        var vertex : SDL_GPUShader? = device |> with_gpu_dsl_shader(triangle_vertex, triangle_vertex_reflect) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_gpu_dsl_shader(triangle_fragment, triangle_fragment_reflect) |> sdl_use
        return check_pixels(device, vertex, fragment)
    }
    if (is_err(result)) {print("{unwrap_err(result).message}\n"); return 1}
    print("Shader DSL reflection and pixels PASS\n"); return 0
}
