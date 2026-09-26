options gen2
module sdl3_gpu_swapchain_boost shared public
require dassdl3/sdl3_gpu_boost public

def public gpu_supports_present_mode(device : SDL_GPUDevice?; window : SDL_Window?; mode : uint) {
    let state = SDL_GPUWindowPresentSupported(device, window, mode)
    if (state < 0) { return err(sdl_error("gpu_supports_present_mode"), type<bool>) }
    return ok(state == 1, type<SdlError>)
}
def public gpu_supports_composition(device : SDL_GPUDevice?; window : SDL_Window?; composition : uint) {
    let state = SDL_GPUWindowCompositionSupported(device, window, composition)
    if (state < 0) { return err(sdl_error("gpu_supports_composition"), type<bool>) }
    return ok(state == 1, type<SdlError>)
}
def public gpu_swapchain_format(device : SDL_GPUDevice?; window : SDL_Window?) {
    let result = SDL_GPUWindowFormatChecked(device, window)
    let value = result
    if (value == 0u) { return err(sdl_error("gpu_swapchain_format"), type<uint>) }
    return ok(value, type<SdlError>)
}
// False means unsupported or failure; inspect the native tri-state query when needed.
// Call between frames. A format change requires compatible pipelines.
def public gpu_configure_swapchain(device : SDL_GPUDevice?; window : SDL_Window?;
                                   composition, mode : uint) {
    let state = SDL_ConfigureGPUSwapchainChecked(device, window, composition, mode)
    if (state < 0) { return err(sdl_error("gpu_configure_swapchain"), type<bool>) }
    return ok(state == 1, type<SdlError>)
}
// Device-wide setting; SDL stalls/flushes the queue. Not a per-frame operation.
def public gpu_frames_in_flight(device : SDL_GPUDevice?; count : uint) {
    return sdl_status(SDL_SetGPUFramesInFlightChecked(device, count), "gpu_frames_in_flight")
}
// Waits for availability; does not acquire a texture, submit a frame or pump events.
def public gpu_wait_swapchain(device : SDL_GPUDevice?; window : SDL_Window?) {
    return sdl_status(SDL_WaitGPUSwapchainChecked(device, window), "gpu_wait_swapchain")
}
