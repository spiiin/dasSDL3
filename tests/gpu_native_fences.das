options gen2
require dassdl3/sdl3_gpu_boost
require daslib/defer

def exercise(device : SDL_GPUDevice?) {
    verify(SDLTestNativeFenceArrayBounds(device))
    // Execute the generated pointer/count entry point too: SDL rejects missing storage.
    verify(!SDL_WaitForGPUFences(device,true,null,1u))
    verify(SDL_GetError() != "")
    var fences : array<SDL_GPUFence?>
    verify(!SDL_WaitForGPUFencesArray(device,true,fences))
    resize(fences,2)
    verify(!SDL_WaitForGPUFencesArray(device,false,fences))
    verify(!SDL_WaitForGPUFencesArray(null,true,fences))
    for (iteration in 0 .. 32) {
        // Bare block confines the defer macro to this iteration.
        {
            var first = SDL_AcquireGPUCommandBuffer(device)
            verify(first != null)
            defer() { if (first != null) { SDL_CancelGPUCommandBuffer(first) } }
            var a = SDL_SubmitGPUCommandBufferAndAcquireFence(first)
            first = null // consumed on success OR failure
            verify(a != null)
            {
                defer() { SDL_ReleaseGPUFence(device,a) }
                fences[0] = a
                // Do not assume the GPU is still pending: even an empty submit can finish immediately.
                let initially_ready = SDL_QueryGPUFence(device,a)
                var second = SDL_AcquireGPUCommandBuffer(device)
                verify(second != null)
                defer() { if (second != null) { SDL_CancelGPUCommandBuffer(second) } }
                var b = SDL_SubmitGPUCommandBufferAndAcquireFence(second)
                second = null
                verify(b != null)
                {
                    defer() { SDL_ReleaseGPUFence(device,b) }
                    fences[1] = b
                    verify(SDL_WaitForGPUFencesArray(device,false,fences))
                    verify(SDL_QueryGPUFence(device,a) || SDL_QueryGPUFence(device,b))
                    verify(SDL_WaitForGPUFencesArray(device,true,fences))
                    verify(SDL_QueryGPUFence(device,a) && SDL_QueryGPUFence(device,b))
                    // Array contents are not retained; a subsequent call uses the new order.
                    fences[0] = b; fences[1] = a
                    verify(SDL_WaitForGPUFencesArray(device,true,fences))
                }
            }
            fences[0] = null; fences[1] = null
        }
    }
    let cancelled = SDL_AcquireGPUCommandBuffer(device)
    verify(cancelled != null && SDL_CancelGPUCommandBuffer(cancelled))
    let submitted = SDL_AcquireGPUCommandBuffer(device)
    verify(submitted != null && SDL_SubmitGPUCommandBuffer(submitted))
    verify(SDL_WaitForGPUIdle(device))
}

def early_return(device : SDL_GPUDevice?) {
    let command = SDL_AcquireGPUCommandBuffer(device)
    verify(command != null)
    { defer() { verify(SDL_CancelGPUCommandBuffer(command)) }; return }
}

[export]
def main(smoke : bool) : int {
    var available = false
    let initialized = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            exercise(device)
            early_return(device)
            // Raw handles are deliberately not checked IDs. Never dereference stale/foreign handles.
            let nested = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(other) { exercise(other) }
            verify(nested)
            exercise(device)
            print("Native command/fence lifecycle PASS: {SDL_GetGPUDeviceDriver(device)}\n")
        }
    }
    verify(initialized)
    return available ? 0 : 77
}
