options gen2
module file_shader_support shared public
require sdl3 public

// Application-local selection for the saved, trusted shader fixtures.
struct FileShaderBackend {
    format : uint
    extension : string
    entry : string
}
def public file_shader_backend(device : SDL_GPUDevice?) : FileShaderBackend {
    let formats = SDL_GetGPUShaderFormats(device)
    if ((formats & SDL_GPU_SHADERFORMAT_SPIRV) != 0u) {
        return FileShaderBackend(format = SDL_GPU_SHADERFORMAT_SPIRV, extension = "spv", entry = "main")
    }
    if ((formats & SDL_GPU_SHADERFORMAT_MSL) != 0u) {
        return FileShaderBackend(format = SDL_GPU_SHADERFORMAT_MSL, extension = "msl", entry = "main0")
    }
    return FileShaderBackend(format = SDL_GPU_SHADERFORMAT_DXIL, extension = "dxil", entry = "main")
}
