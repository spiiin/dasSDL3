options gen2
module compute_support shared public
require ./multipass_support.das public
require dassdl3/sdl3_shader_compute public
require dassdl3/sdl3_shader_storage_spirv
// Application-local resource creation; ownership stays with each example.
def compute_pipeline(device : SDL_GPUDevice?; words, reflection, access : array<uint>) {
    let info = gpu_dsl_compute_info(reflection, access) |> sdl_try
    var native_words <- gpu_dsl_storage_spirv(words, reflection, access) |> sdl_try
    var bytes <- gpu_dsl_spirv_bytes(native_words) |> sdl_try
    if ((SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u) {
        var p = SDL_CreateGPUComputePipelineBytes(device, info, bytes, "main")
        if (p == null) { return err(sdl_error("SDL_CreateGPUComputePipelineBytes"), type<SDL_GPUComputePipeline?>) }
        return <- move_ok(p, type<SdlError>)
    }
    static_if (typeinfo module_exists(sdl3_shader_dsl_cross)) {
        return with_shadercross() {
            let metadata = SDL_ShaderCross_ComputePipelineMetadata(num_samplers = info.num_samplers,
                num_readonly_storage_buffers = info.num_readonly_storage_buffers,
                num_readwrite_storage_buffers = info.num_readwrite_storage_buffers,
                num_uniform_buffers = info.num_uniform_buffers, threadcount_x = info.threadcount_x,
                threadcount_y = info.threadcount_y, threadcount_z = info.threadcount_z)
            return compile_compute_pipeline_spirv(device, bytes, "main", metadata)
        }
    } else { return err(SdlError(operation = "compute_pipeline", message = "Use the shadercross libraries runner"), type<SDL_GPUComputePipeline?>) }
}
