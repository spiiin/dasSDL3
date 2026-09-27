options gen2
module sdl3_shader_dsl_cross shared public
require dassdl3/sdl3_shader_dsl public
require dassdl3/sdl3_shader_compute public
require dassdl3/sdl3_shadercross_boost public
require dassdl3/sdl3_try
require dassdl3/sdl3_shader_storage_spirv
require daslib/defer

// Caller owns one with_shadercross session. Resources retain ordinary SDL ownership.
def public with_gpu_dsl_shader_cross(device : SDL_GPUDevice?; words, reflection : array<uint>;
                                     blk : block<(var shader : SDL_GPUShader?) : $Result<auto(T); SdlError>>) {
    let info = gpu_dsl_shader_info(reflection) |> sdl_try
    var bytes <- gpu_dsl_spirv_bytes(words) |> sdl_try
    let stage = info.stage == SDL_GPUShaderStage.SHADERSTAGE_VERTEX ? SDL_ShaderCross_ShaderStage.SHADERSTAGE_VERTEX : SDL_ShaderCross_ShaderStage.SHADERSTAGE_FRAGMENT
    let resources = SDL_ShaderCross_GraphicsShaderResourceInfo(num_samplers = info.num_samplers, num_uniform_buffers = info.num_uniform_buffers)
    var shader = compile_graphics_shader_spirv(device, bytes, "main", stage, resources) |> sdl_try
    var result : $Result<T; SdlError>
    {
        defer() {SDL_ReleaseGPUShader(device, shader)}
        static_if (typeinfo can_copy(type<$Result<T; SdlError>>)) {result = blk(shader)}
        else {result <- blk(shader)}
    }
    return <- result
}

def public with_gpu_dsl_compute_pipeline_cross(device : SDL_GPUDevice?; words, reflection : array<uint>;
                                               blk : block<(var pipeline : SDL_GPUComputePipeline?) : $Result<auto(T); SdlError>>) {
    let info = gpu_dsl_compute_info(reflection) |> sdl_try
    var bytes <- gpu_dsl_spirv_bytes(words) |> sdl_try
    let metadata = SDL_ShaderCross_ComputePipelineMetadata(
        num_readwrite_storage_buffers = info.num_readwrite_storage_buffers,
        num_uniform_buffers = info.num_uniform_buffers,
        threadcount_x = info.threadcount_x,
        threadcount_y = info.threadcount_y,
        threadcount_z = info.threadcount_z)
    var pipeline = compile_compute_pipeline_spirv(device, bytes, "main", metadata) |> sdl_try
    var result : $Result<T; SdlError>
    {
        defer() {SDL_ReleaseGPUComputePipeline(device, pipeline)}
        static_if (typeinfo can_copy(type<$Result<T; SdlError>>)) {result = blk(pipeline)}
        else {result <- blk(pipeline)}
    }
    return <- result
}

// Caller owns one with_shadercross session. Resources retain ordinary SDL ownership.
def public with_gpu_dsl_shader_cross(device : SDL_GPUDevice?; words, reflection, access : array<uint>;
                                     blk : block<(var shader : SDL_GPUShader?) : $Result<auto(T); SdlError>>) {
    let info = gpu_dsl_shader_info(reflection, access) |> sdl_try
    var native_words <- gpu_dsl_storage_spirv(words, reflection, access) |> sdl_try
    var bytes <- gpu_dsl_spirv_bytes(native_words) |> sdl_try
    let stage = info.stage == SDL_GPUShaderStage.SHADERSTAGE_VERTEX ? SDL_ShaderCross_ShaderStage.SHADERSTAGE_VERTEX : SDL_ShaderCross_ShaderStage.SHADERSTAGE_FRAGMENT
    let resources = SDL_ShaderCross_GraphicsShaderResourceInfo(num_samplers = info.num_samplers, num_uniform_buffers = info.num_uniform_buffers, num_storage_textures = info.num_storage_textures, num_storage_buffers = info.num_storage_buffers)
    var shader = compile_graphics_shader_spirv(device, bytes, "main", stage, resources) |> sdl_try
    var result : $Result<T; SdlError>
    {
        defer() {SDL_ReleaseGPUShader(device, shader)}
        static_if (typeinfo can_copy(type<$Result<T; SdlError>>)) {result = blk(shader)}
        else {result <- blk(shader)}
    }
    return <- result
}

def public with_gpu_dsl_compute_pipeline_cross(device : SDL_GPUDevice?; words, reflection, access : array<uint>;
                                               blk : block<(var pipeline : SDL_GPUComputePipeline?) : $Result<auto(T); SdlError>>) {
    let info = gpu_dsl_compute_info(reflection, access) |> sdl_try
    var native_words <- gpu_dsl_storage_spirv(words, reflection, access) |> sdl_try
    var bytes <- gpu_dsl_spirv_bytes(native_words) |> sdl_try
    let metadata = SDL_ShaderCross_ComputePipelineMetadata(
        num_readwrite_storage_buffers = info.num_readwrite_storage_buffers,
        num_samplers = info.num_samplers, num_readonly_storage_textures = info.num_readonly_storage_textures,
        num_readonly_storage_buffers = info.num_readonly_storage_buffers, num_readwrite_storage_textures = info.num_readwrite_storage_textures,
        num_uniform_buffers = info.num_uniform_buffers,
        threadcount_x = info.threadcount_x,
        threadcount_y = info.threadcount_y,
        threadcount_z = info.threadcount_z)
    var pipeline = compile_compute_pipeline_spirv(device, bytes, "main", metadata) |> sdl_try
    var result : $Result<T; SdlError>
    {
        defer() {SDL_ReleaseGPUComputePipeline(device, pipeline)}
        static_if (typeinfo can_copy(type<$Result<T; SdlError>>)) {result = blk(pipeline)}
        else {result <- blk(pipeline)}
    }
    return <- result
}
