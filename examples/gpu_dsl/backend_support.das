options gen2
module backend_support shared public
require dassdl3/sdl3_shader_dsl public
require dassdl3/sdl3_shader_compute public
// Generic bodies see the instantiating caller's modules; expose the guarded import.
require ?sdl3_shadercross dassdl3/sdl3_shader_dsl_cross public
require dassdl3/sdl3_try

// Keep direct SPIR-V independent; native translation is an explicit runner option.
def public dsl_example_formats : uint {
    static_if (typeinfo module_exists(sdl3_shader_dsl_cross)) {
        return SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_MSL | SDL_GPU_SHADERFORMAT_DXIL
    } else { return SDL_GPU_SHADERFORMAT_SPIRV }
}
def public with_dsl_example_shader(device : SDL_GPUDevice?; words, reflection : array<uint>;
    blk : block<(var shader : SDL_GPUShader?) : $Result<auto(T); SdlError>>) {
    if ((SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u) {
        return <- with_gpu_dsl_shader(device, words, reflection, blk)
    }
    static_if (typeinfo module_exists(sdl3_shader_dsl_cross)) {
        return <- with_shadercross() { return <- with_gpu_dsl_shader_cross(device, words, reflection, blk) }
    } else { return err(SdlError(operation = "Shader DSL example", message = "This backend requires the libraries runner with shadercross"), type<T>) }
}
def public with_dsl_example_compute(device : SDL_GPUDevice?; words, reflection : array<uint>;
    blk : block<(var pipeline : SDL_GPUComputePipeline?) : $Result<auto(T); SdlError>>) {
    if ((SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u) {
        return <- with_gpu_dsl_compute_pipeline(device, words, reflection, blk)
    }
    static_if (typeinfo module_exists(sdl3_shader_dsl_cross)) {
        return <- with_shadercross() { return <- with_gpu_dsl_compute_pipeline_cross(device, words, reflection, blk) }
    } else { return err(SdlError(operation = "Shader DSL example", message = "This backend requires the libraries runner with shadercross"), type<T>) }
}
