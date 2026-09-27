options gen2
module sdl3_shader_dsl shared public
require spirv/spirv_reflect public
require dassdl3/sdl3_gpu_native_boost public
require dassdl3/sdl3_try
require dassdl3/sdl3_shader_storage_spirv
require dassdl3/sdl3_shader_resources

def private dsl_dense_slots(slots : array<int>) : bool {
    for (slot in 0 .. length(slots)) {
        var occurrences = 0
        for (actual in slots) { if (actual == slot) { occurrences++ } }
        if (occurrences != 1) { return false }
    }
    return true
}

// Consume reflection emitted alongside [vertex_shader]/[fragment_shader].
// This first graphics profile supports UBOs and combined image samplers only.
def public gpu_dsl_shader_info(words : array<uint>) : $Result<SDL_GPUShaderCreateInfo; SdlError> {
    let failure = SdlError(operation = "gpu_dsl_shader_info", message = "Expected graphics reflection with dense SDL sets: vertex resources/uniforms 0/1, fragment 2/3; only scalar UBO and combined sampler bindings are supported")
    if (length(words) < 7 || words[0] != REFLECTION_MAGIC) { return err(failure, type<SDL_GPUShaderCreateInfo>) }
    let stage = words[1]
    if (stage != 1u && stage != 2u) { return err(failure, type<SDL_GPUShaderCreateInfo>) }
    // Validate the wire form before the permissive upstream decoder sees it.
    let n = length(words)
    let count = words[5]
    if (count > uint((n - 7) / 5)) { return err(failure, type<SDL_GPUShaderCreateInfo>) }
    let end_bindings = 6 + int(count) * 5
    if (end_bindings + 1 != n || words[end_bindings] != 0u) { return err(failure, type<SDL_GPUShaderCreateInfo>) }
    for (i in 0 .. int(count)) {
        let at = 6 + i * 5
        if (words[at + 3] != 1u || words[at + 4] != stage ||
            (words[at + 2] != uint(int(SpirvDescriptorKind.uniform_buffer)) &&
             words[at + 2] != uint(int(SpirvDescriptorKind.combined_image_sampler)))) {
            return err(failure, type<SDL_GPUShaderCreateInfo>)
        }
    }
    var reflection <- decode_reflection(words)
    let resource_set = stage == 1u ? 0 : 2
    var info = SDL_GPUShaderCreateInfo(format = SDL_GPU_SHADERFORMAT_SPIRV,
        stage = stage == 1u ? SDL_GPUShaderStage.SHADERSTAGE_VERTEX : SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    var uniforms, samplers : array<int>
    for (binding in reflection.bindings) {
        if (binding.binding < 0 || binding.binding >= int(count)) { return err(failure, type<SDL_GPUShaderCreateInfo>) }
        if (binding.kind == SpirvDescriptorKind.uniform_buffer && binding.set == resource_set + 1) {
            uniforms |> push(binding.binding)
        } elif (binding.kind == SpirvDescriptorKind.combined_image_sampler && binding.set == resource_set) {
            samplers |> push(binding.binding)
        } else { return err(failure, type<SDL_GPUShaderCreateInfo>) }
    }
    info.num_uniform_buffers = uint(length(uniforms))
    info.num_samplers = uint(length(samplers))
    if (!dsl_dense_slots(uniforms) || !dsl_dense_slots(samplers)) {
        return err(failure, type<SDL_GPUShaderCreateInfo>)
    }
    return ok(info, type<SdlError>)
}

// One owned copy at shader creation; no pointer cast or retained script array.
def public gpu_dsl_spirv_bytes(words : array<uint>) : $Result<array<uint8>; SdlError> {
    if (length(words) < 5 || words[0] != 0x07230203u || length(words) > 0x1fffffff) {
        return err(SdlError(operation = "gpu_dsl_spirv_bytes", message = "Invalid SPIR-V word header or size"), type<array<uint8>>)
    }
    var bytes : array<uint8>
    resize(bytes, length(words) * 4)
    for (i in 0 .. length(words)) {
        var word = words[i]
        for (b in 0 .. 4) { bytes[i * 4 + b] = uint8(word % 256u); word /= 256u }
    }
    return <- move_ok(bytes, type<SdlError>)
}

def public with_gpu_dsl_shader(device : SDL_GPUDevice?; words, reflection : array<uint>;
                               blk : block<(var shader : SDL_GPUShader?) : $Result<auto(T); SdlError>>) {
    let info = gpu_dsl_shader_info(reflection) |> sdl_try
    var bytes <- gpu_dsl_spirv_bytes(words) |> sdl_try
    return device |> with_native_gpu_shader_bytes(info, bytes, "main", blk)
}

def public gpu_dsl_shader_info(words, access : array<uint>) : $Result<SDL_GPUShaderCreateInfo; SdlError> {
    if (length(words) < 2 || (words[1] != 1u && words[1] != 2u)) {return err(SdlError(operation = "gpu_dsl_shader_info", message = "Expected graphics stage"), type<SDL_GPUShaderCreateInfo>)}
    let r = gpu_dsl_resource_info(words, access, words[1]) |> sdl_try
    return ok(SDL_GPUShaderCreateInfo(format = SDL_GPU_SHADERFORMAT_SPIRV,
        stage = words[1] == 1u ? SDL_GPUShaderStage.SHADERSTAGE_VERTEX : SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,
        num_samplers = r.num_samplers, num_storage_textures = r.num_readonly_storage_textures,
        num_storage_buffers = r.num_readonly_storage_buffers, num_uniform_buffers = r.num_uniform_buffers), type<SdlError>)
}

def public with_gpu_dsl_shader(device : SDL_GPUDevice?; words, reflection, access : array<uint>;
                               blk : block<(var shader : SDL_GPUShader?) : $Result<auto(T); SdlError>>) {
    let info = gpu_dsl_shader_info(reflection, access) |> sdl_try
    var native_words <- gpu_dsl_storage_spirv(words, reflection, access) |> sdl_try
    var bytes <- gpu_dsl_spirv_bytes(native_words) |> sdl_try
    return device |> with_native_gpu_shader_bytes(info, bytes, "main", blk)
}
