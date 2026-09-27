options gen2
module sdl3_shader_compute shared public
require dassdl3/sdl3_shader_dsl public
require dassdl3/sdl3_try
require dassdl3/sdl3_shader_storage_spirv
require dassdl3/sdl3_shader_resources

// Initial compute profile: RW storage buffers in set 1, uniform blocks in set 2.
// Upstream reflection has no readonly flag; set 0 storage is deliberately rejected.
def public gpu_dsl_compute_info(words : array<uint>) : $Result<SDL_GPUComputePipelineCreateInfo; SdlError> {
    let failure = SdlError(operation = "gpu_dsl_compute_info", message = "Expected compute reflection: dense RW buffer set 1 and uniform set 2, no descriptor arrays or push constants")
    if (length(words) < 7 || words[0] != REFLECTION_MAGIC || words[1] != 4u) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    let count = words[5]
    if (count > uint((length(words) - 7) / 5)) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    let end = 6 + int(count) * 5
    if (end + 1 != length(words) || words[end] != 0u) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    let x = words[2]; let y = words[3]; let z = words[4]
    // A bounded profile, not a claim that every device supports its upper limits.
    if (x == 0u || y == 0u || z == 0u || x > 1024u || y > 1024u || z > 64u || uint64(x) * uint64(y) * uint64(z) > 1024ul) {
        return err(SdlError(operation = "gpu_dsl_compute_info", message = "Invalid compute local size: positive axes, x/y <=1024, z <=64, product <=1024 required"), type<SDL_GPUComputePipelineCreateInfo>)
    }
    var info = SDL_GPUComputePipelineCreateInfo(format = SDL_GPU_SHADERFORMAT_SPIRV, threadcount_x = x, threadcount_y = y, threadcount_z = z)
    for (i in 0 .. int(count)) {
        let at = 6 + i * 5
        if (words[at + 3] != 1u || words[at + 4] != 4u) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
        if (words[at] == 1u && words[at + 2] == uint(int(SpirvDescriptorKind.storage_buffer))) {info.num_readwrite_storage_buffers++}
        elif (words[at] == 2u && words[at + 2] == uint(int(SpirvDescriptorKind.uniform_buffer))) {info.num_uniform_buffers++}
        else {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
        for (j in 0 .. i) {
            let previous = 6 + j * 5
            if (words[previous] == words[at] && words[previous + 1] == words[at + 1]) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
        }
    }
    if (info.num_readwrite_storage_buffers > 8u || info.num_uniform_buffers > 4u) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    for (i in 0 .. int(count)) {
        let at = 6 + i * 5
        let slots = words[at] == 1u ? info.num_readwrite_storage_buffers : info.num_uniform_buffers
        if (words[at + 1] >= slots) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    }
    return ok(info, type<SdlError>)
}

def public with_gpu_dsl_compute_pipeline(device : SDL_GPUDevice?; words, reflection : array<uint>;
                                         blk : block<(var pipeline : SDL_GPUComputePipeline?) : $Result<auto(T); SdlError>>) {
    let info = gpu_dsl_compute_info(reflection) |> sdl_try
    var bytes <- gpu_dsl_spirv_bytes(words) |> sdl_try
    return device |> with_native_gpu_compute_pipeline_bytes(info, bytes, "main", blk)
}

def public gpu_dsl_compute_info(words, access : array<uint>) : $Result<SDL_GPUComputePipelineCreateInfo; SdlError> {
    return gpu_dsl_resource_info(words, access, 4u)
}
def public with_gpu_dsl_compute_pipeline(device : SDL_GPUDevice?; words, reflection, access : array<uint>;
                                         blk : block<(var pipeline : SDL_GPUComputePipeline?) : $Result<auto(T); SdlError>>) {
    let info = gpu_dsl_compute_info(reflection, access) |> sdl_try
    var native_words <- gpu_dsl_storage_spirv(words, reflection, access) |> sdl_try
    var bytes <- gpu_dsl_spirv_bytes(native_words) |> sdl_try
    return device |> with_native_gpu_compute_pipeline_bytes(info, bytes, "main", blk)
}
