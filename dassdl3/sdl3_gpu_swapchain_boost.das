options gen2
module sdl3_gpu_swapchain_boost shared public
require dassdl3/sdl3_gpu_boost public

def public gpu_supports_present_mode(device : SDL_GPUDevice?; window : SDL_Window?; mode : uint) : bool {
    let result = SDL_GPUWindowPresentSupported(device,window,mode)
    if (result < 0) { panic("GPU present support: {SDL_GetError()}") }
    return result == 1
}
def public gpu_supports_composition(device : SDL_GPUDevice?; window : SDL_Window?; composition : uint) : bool {
    let result = SDL_GPUWindowCompositionSupported(device,window,composition)
    if (result < 0) { panic("GPU composition support: {SDL_GetError()}") }
    return result == 1
}
def public gpu_swapchain_format(device : SDL_GPUDevice?; window : SDL_Window?) : uint {
    let result = SDL_GPUWindowFormatChecked(device,window)
    if (result == SDL_GPU_TEXTUREFORMAT_INVALID) { panic("GPU swapchain format: {SDL_GetError()}") }
    return result
}
// Unsupported is false without mutation; invalid input/SDL failure panics.
// Call between frames. A format change requires compatible pipelines.
def public gpu_try_configure_swapchain(device : SDL_GPUDevice?; window : SDL_Window?;
        composition, mode : uint) : bool {
    let result = SDL_ConfigureGPUSwapchainChecked(device,window,composition,mode)
    if (result < 0) { panic("GPU swapchain configure: {SDL_GetError()}") }
    return result == 1
}
// Device-wide setting; SDL stalls/flushes the queue. Not a per-frame operation.
def public gpu_frames_in_flight(device : SDL_GPUDevice?; count : uint) {
    if (!SDL_SetGPUFramesInFlightChecked(device,count)) { panic("GPU frames in flight: {SDL_GetError()}") }
}
// Waits for availability; does not acquire a texture, submit a frame or pump events.
def public gpu_wait_swapchain(device : SDL_GPUDevice?; window : SDL_Window?) {
    if (!SDL_WaitGPUSwapchainChecked(device,window)) { panic("GPU wait swapchain: {SDL_GetError()}") }
}
