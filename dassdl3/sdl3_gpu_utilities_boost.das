options gen2
module sdl3_gpu_utilities_boost shared public
require dassdl3/sdl3_gpu_formats_boost public

// Compiled drivers, not a list of physical adapters or runtime availability.
def public gpu_driver_names() {
    let count = SDL_GPUDriverCountChecked()
    if (count < 0) {return err(sdl_error("gpu_driver_names"), type<array<string> >)}
    var names : array<string>
    for (i in 0 .. count) {push(names, SDL_GPUDriverNameCopy(i))}
    return <- move_ok(names, type<SdlError>)
}
def public gpu_supports_shaders(formats : uint; driver : string = "") {
    let state = SDL_GPUShaderSupportChecked(formats, driver)
    if (state < 0) { return err(sdl_error("gpu_supports_shaders"), type<bool>) }
    return ok(state == 1, type<SdlError>)
}
def public gpu_buffer_name(device : SDL_GPUDevice?; buffer : GpuBufferHandle; name : string) {
    return sdl_status(SDL_SetGPUDataBufferNameChecked(device, buffer, name), "gpu_buffer_name")
}
def public gpu_texture_name(device : SDL_GPUDevice?; texture : GpuTextureHandle; name : string) {
    return sdl_status(SDL_SetGPUTransferTextureNameChecked(device, texture, name), "gpu_texture_name")
}
