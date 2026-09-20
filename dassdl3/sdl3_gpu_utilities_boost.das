options gen2
module sdl3_gpu_utilities_boost shared public
require dassdl3/sdl3_gpu_formats_boost public

// Compiled drivers, not a list of physical adapters or runtime availability.
def public gpu_driver_names() : array<string> {
    let count = SDL_GPUDriverCountChecked()
    var names : array<string>
    for (i in 0 .. count) { push(names,SDL_GPUDriverNameCopy(i)) }
    return <- names
}
def public gpu_supports_shaders(formats : uint; driver : string = "") : bool {
    let result = SDL_GPUShaderSupportChecked(formats,driver)
    return result == 1
}
def public gpu_buffer_name(device : SDL_GPUDevice?; buffer : uint64; name : string) {
    return SDL_SetGPUDataBufferNameChecked(device,buffer,name)
}
def public gpu_texture_name(device : SDL_GPUDevice?; texture : uint64; name : string) {
    return SDL_SetGPUTransferTextureNameChecked(device,texture,name)
}
