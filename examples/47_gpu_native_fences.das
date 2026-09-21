options gen2
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_scope
require daslib/defer

// Native SDL pointers and results. There is no command plan or readback-ticket object.
def submit_and_wait(device : SDL_GPUDevice?) : $Result<SdlUnit; SdlError> {
    var command = device |> acquire_native_gpu_command_buffer() |> sdl_try
    {
        defer() { if (command != null) { SDL_CancelGPUCommandBuffer(command) } }
        // An empty command buffer is sufficient to demonstrate the synchronization API.
        var fence = native_gpu_submit_fence(command) |> sdl_try // Consumes command even on Err.
        {
            defer() { SDL_ReleaseGPUFence(device,fence) }
            var fences : array<SDL_GPUFence?>
            resize(fences,1); fences[0] = fence
            if (!SDL_WaitForGPUFencesArray(device,true,fences)) { return err(sdl_error("submit_and_wait"),type<SdlUnit>) }
            if (!SDL_QueryGPUFence(device,fence)) { return err(sdl_error("submit_and_wait"),type<SdlUnit>) }
            print("Native SDL fence signaled: {SDL_GetGPUDeviceDriver(device)}\n")
            return sdl_ok()
        }
    }
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device = create_native_gpu_device(GPU_SHADER_FORMATS,true) |> sdl_try
        {
            defer(){SDL_DestroyGPUDevice(device)}
            return submit_and_wait(device)
        }
    }
    if (is_err(result)) {
        let error=unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="SDL_CreateGPUDeviceDefault" ? 77 : 1
    }
    return 0
}
