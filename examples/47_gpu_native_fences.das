options gen2
require dassdl3/sdl3_gpu_boost
require daslib/defer

// Native SDL pointers and results. There is no command plan or readback-ticket object.
def create_native_device : SDL_GPUDevice? {
    // An empty string is not SDL's null/default driver. Pick a supported name;
    // SDL_GPU_DRIVER, when set by the test runner, still takes precedence in SDL.
    for (i in 0 .. SDL_GetNumGPUDrivers()) {
        let driver = SDL_GetGPUDriver(i)
        if (SDL_GPUSupportsShaderFormats(GPU_SHADER_FORMATS,driver)) {
            var device = SDL_CreateGPUDevice(GPU_SHADER_FORMATS,true,driver)
            if (device != null) { return device }
        }
    }
    return null
}
def submit_and_wait(device : SDL_GPUDevice?) : bool {
    var command = SDL_AcquireGPUCommandBuffer(device)
    if (command == null) { return false }
    {
        defer() { if (command != null) { SDL_CancelGPUCommandBuffer(command) } }
        // An empty command buffer is sufficient to demonstrate the synchronization API.
        var fence = SDL_SubmitGPUCommandBufferAndAcquireFence(command)
        command = null // SDL consumes it even if submission fails.
        if (fence == null) { return false }
        {
            defer() { SDL_ReleaseGPUFence(device,fence) }
            var fences : array<SDL_GPUFence?>
            resize(fences,1); fences[0] = fence
            if (!SDL_WaitForGPUFencesArray(device,true,fences)) { return false }
            if (!SDL_QueryGPUFence(device,fence)) { return false }
            print("Native SDL fence signaled: {SDL_GetGPUDeviceDriver(device)}\n")
            return true
        }
    }
}

[export]
def main(smoke : bool) : int {
    if (!sdl_init()) { print("SDL_Init: {SDL_GetError()}\n"); return 1 }
    {
        defer() { SDL_Quit() }
        let device = create_native_device()
        if (device == null) { print("GPU device: {SDL_GetError()}\n"); return smoke ? 77 : 1 }
        {
            defer() { SDL_DestroyGPUDevice(device) }
            if (!submit_and_wait(device)) { print("GPU submission: {SDL_GetError()}\n"); return 1 }
            return 0
        }
    }
}
