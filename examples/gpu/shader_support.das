options gen2
module shader_support shared public
// Application-local backend selection. No shader files or per-frame compilation.
require dassdl3/sdl3_shader_dsl public
require ?sdl3_shadercross dassdl3/sdl3_shader_dsl_cross public
require dassdl3/sdl3_try
require daslib/defer

def example_shader_formats : uint {
    static_if (typeinfo module_exists(sdl3_shader_dsl_cross)) {return SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_MSL | SDL_GPU_SHADERFORMAT_DXIL}
    else {return SDL_GPU_SHADERFORMAT_SPIRV}
}

def private create_example_shader(device : SDL_GPUDevice?; words, reflection : array<uint>) : $Result<SDL_GPUShader?; SdlError> {
    let info = gpu_dsl_shader_info(reflection) |> sdl_try
    var bytes <- gpu_dsl_spirv_bytes(words) |> sdl_try
    if ((SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u) {
        var shader = SDL_CreateGPUShaderBytes(device, info, bytes, "main")
        if (shader == null) {return err(sdl_error("SDL_CreateGPUShaderBytes"), type<SDL_GPUShader?>)}
        return <- move_ok(shader, type<SdlError>)
    }
    static_if (typeinfo module_exists(sdl3_shader_dsl_cross)) {
        return with_shadercross() {
            let stage = info.stage == SDL_GPUShaderStage.SHADERSTAGE_VERTEX ? SDL_ShaderCross_ShaderStage.SHADERSTAGE_VERTEX : SDL_ShaderCross_ShaderStage.SHADERSTAGE_FRAGMENT
            let resources = SDL_ShaderCross_GraphicsShaderResourceInfo(num_samplers = info.num_samplers, num_uniform_buffers = info.num_uniform_buffers)
            return compile_graphics_shader_spirv(device, bytes, "main", stage, resources)
        }
    } else {return err(SdlError(operation = "GPU example shader", message = "Metal/D3D12 requires the libraries runner with shadercross"), type<SDL_GPUShader?>)}
}

def with_example_shader(device : SDL_GPUDevice?; words, reflection : array<uint>;
                        blk : block<(var shader : SDL_GPUShader?) : $Result<auto(T); SdlError>>) {
    var shader = create_example_shader(device, words, reflection) |> sdl_try
    var result : $Result<T; SdlError>
    {
        defer() {SDL_ReleaseGPUShader(device, shader)}
        static_if (typeinfo can_copy(type<$Result<T; SdlError>>)) {result = blk(shader)}
        else {result <- blk(shader)}
    }
    return <- result
}
