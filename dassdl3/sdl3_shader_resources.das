options gen2
module sdl3_shader_resources shared public
require spirv/spirv_reflect
require dassdl3/sdl3_result public

// Validates SDL descriptor order plus explicit access metadata. The SDL compute
// record is reused as a resource-count carrier; graphics uses the readonly counts.
def public gpu_dsl_resource_info(words, access : array<uint>; stage : uint) : $Result<SDL_GPUComputePipelineCreateInfo; SdlError> {
    let failure = SdlError(operation = "gpu_dsl_resource_info", message = "Invalid SDL descriptor order, resource counts, or storage access metadata")
    if ((stage != 1u && stage != 2u && stage != 4u) || length(words) < 7 || words[0] != REFLECTION_MAGIC || words[1] != stage) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    let count = words[5]
    if (count > 52u || count > uint((length(words) - 7) / 5)) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    let end = 6 + int(count) * 5
    if (end + 1 != length(words) || words[end] != 0u) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    if (length(access) < 2 || access[0] != 0x53444c41u || access[1] > 32u || access[1] != uint((length(access) - 2) / 3) || (length(access) - 2) % 3 != 0) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    for (i in 0 .. int(access[1])) {
        let a = 2 + i * 3
        if (access[a + 2] < 1u || access[a + 2] > 3u) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
        for (j in 0 .. i) {let b = 2 + j * 3; if (access[a] == access[b] && access[a + 1] == access[b + 1]) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}}
    }
    let resource_set = stage == 2u ? 2u : 0u
    let uniform_set = stage == 4u ? 2u : resource_set + 1u
    var info = SDL_GPUComputePipelineCreateInfo(format = SDL_GPU_SHADERFORMAT_SPIRV, threadcount_x = words[2], threadcount_y = words[3], threadcount_z = words[4])
    if (stage == 4u && (words[2] == 0u || words[3] == 0u || words[4] == 0u || words[2] > 1024u || words[3] > 1024u || words[4] > 64u || uint64(words[2]) * uint64(words[3]) * uint64(words[4]) > 1024ul)) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    var storage_count = 0u
    for (i in 0 .. int(count)) {
        let at = 6 + i * 5; let set = words[at]; let kind = words[at + 2]
        if (words[at + 3] != 1u || words[at + 4] != stage) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
        for (j in 0 .. i) {let b = 6 + j * 5; if (words[b] == set && words[b + 1] == words[at + 1]) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}}
        if (kind == uint(int(SpirvDescriptorKind.uniform_buffer)) && set == uniform_set) {info.num_uniform_buffers++; continue}
        if (kind == uint(int(SpirvDescriptorKind.combined_image_sampler)) && set == resource_set) {info.num_samplers++; continue}
        let texture = kind == uint(int(SpirvDescriptorKind.storage_image))
        let buffer = kind == uint(int(SpirvDescriptorKind.storage_buffer))
        if (!texture && !buffer) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
        var flags = 0u
        for (j in 0 .. int(access[1])) {let a = 2 + j * 3; if (access[a] == set && access[a + 1] == words[at + 1]) {flags = access[a + 2]}}
        if (flags == 0u) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
        storage_count++
        if (set == resource_set && flags == 1u) {
            if (texture) {info.num_readonly_storage_textures++} else {info.num_readonly_storage_buffers++}
        } elif (stage == 4u && set == 1u && (flags == 2u || flags == 3u)) {
            if (texture) {info.num_readwrite_storage_textures++} else {info.num_readwrite_storage_buffers++}
        } else {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    }
    if (storage_count != access[1] || info.num_samplers > 16u || info.num_uniform_buffers > 4u || info.num_readonly_storage_textures > 8u || info.num_readonly_storage_buffers > 8u || info.num_readwrite_storage_textures > 8u || info.num_readwrite_storage_buffers > 8u) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    for (i in 0 .. int(count)) {
        let at = 6 + i * 5; let set = words[at]; let kind = words[at + 2]; let slot = words[at + 1]
        var first = 0u; var slots = 0u
        if (set == uniform_set && kind == uint(int(SpirvDescriptorKind.uniform_buffer))) {slots = info.num_uniform_buffers}
        elif (set == resource_set) {
            if (kind == uint(int(SpirvDescriptorKind.combined_image_sampler))) {slots = info.num_samplers}
            elif (kind == uint(int(SpirvDescriptorKind.storage_image))) {first = info.num_samplers; slots = info.num_readonly_storage_textures}
            else {first = info.num_samplers + info.num_readonly_storage_textures; slots = info.num_readonly_storage_buffers}
        } else {
            if (kind == uint(int(SpirvDescriptorKind.storage_image))) {slots = info.num_readwrite_storage_textures}
            else {first = info.num_readwrite_storage_textures; slots = info.num_readwrite_storage_buffers}
        }
        if (slot < first || slot - first >= slots) {return err(failure, type<SDL_GPUComputePipelineCreateInfo>)}
    }
    return ok(info, type<SdlError>)
}
