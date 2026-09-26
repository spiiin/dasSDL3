options gen2
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_gpu_transfer_boost
require daslib/defer

[export]
def main(smoke : bool) : int {
    verify(is_err(gpu_poll_readback(null, GpuReadbackHandle(0ul))))
    verify(is_err(native_gpu_swapchain(null, null)))
    let result = with_sdl(SDL_INIT_VIDEO) {
        return with_gpu_device() $(device : SDL_GPUDevice?) {
            var bytes : array<uint8>
            resize(bytes, 64)
            // Intentional checked-ID misuse: registry rejects the second release safely.
            let cleanup_error = with_gpu_buffer(device, bytes, SDL_GPU_BUFFERUSAGE_VERTEX) $(buffer : GpuBufferHandle) {
                verify(SDL_ReleaseGPUDataBuffer(device, buffer))
                return sdl_ok()
            }
            verify(is_err(cleanup_error) && unwrap_err(cleanup_error).operation == "SDL_ReleaseGPUDataBuffer")
            let primary = with_gpu_buffer(device, bytes, SDL_GPU_BUFFERUSAGE_VERTEX) $(buffer : GpuBufferHandle) {
                verify(SDL_ReleaseGPUDataBuffer(device, buffer))
                SDL_SetErrorText("body wins")
                return err(sdl_error("body"), type<SdlUnit>)
            }
            verify(is_err(primary) && unwrap_err(primary).message == "body wins")
            let readback = with_gpu_buffer(device, bytes, SDL_GPU_BUFFERUSAGE_VERTEX) $(buffer : GpuBufferHandle) {
                return with_gpu_readback(device, buffer, 0u, 64u) $(ticket : GpuReadbackHandle) {
                    SDL_SetErrorText("old error must not turn pending into failure")
                    let before = gpu_poll_readback(device, ticket)
                    verify(is_ok(before)) // Either pending or ready is valid at this instant.
                    {
                        defer(){SDLTestResultStates(false, false)}
                        SDLTestResultStates(true, false)
                        SDL_SetErrorText("stale pending error")
                        let pending = gpu_poll_readback(device, ticket)
                        verify(is_ok(pending) && !unwrap(pending))
                    }
                    verify(is_ok(gpu_wait_readback(device, ticket)))
                    verify(unwrap(gpu_poll_readback(device, ticket)))
                    return sdl_ok()
                }
            }
            verify(is_ok(readback))
            return with_window("Swapchain Result", 32, 32, 0ul) $(window : SDL_Window?) {
                return with_gpu_window(device, window) {
                    let frame = with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var texture : SDL_GPUTexture?; w, h : uint) {
                        verify(texture != null && w > 0u && h > 0u)
                        SDL_SetErrorText("frame body failure")
                        return err(sdl_error("frame body"), type<int>)
                    }
                    verify(is_err(frame) && unwrap_err(frame).message == "frame body failure")
                    let next_frame = with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var texture : SDL_GPUTexture?; w, h : uint) {
                        return ok(123, type<SdlError>)
                    }
                    verify(is_ok(next_frame) && is_some(unwrap(next_frame)) && unwrap(unwrap(next_frame)) == 123)
                    var array_frame <- with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var texture : SDL_GPUTexture?; w, h : uint) {
                        var values : array<int>
                        push(values, 42)
                        return <- move_ok(values, type<SdlError>)
                    }
                    verify(is_ok(array_frame))
                    var array_option <- move_unwrap(array_frame)
                    verify(is_some(array_option))
                    var frame_values <- move_unwrap(array_option)
                    verify(length(frame_values) == 1 && frame_values[0] == 42)
                    {
                        defer(){SDLTestResultStates(false, false)}
                        SDLTestResultStates(false, true)
                        var called = false
                        let unavailable = with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var texture : SDL_GPUTexture?; w, h : uint) {
                            called = true
                            return ok(1, type<SdlError>)
                        }
                        verify(is_ok(unavailable) && is_none(unwrap(unavailable)) && !called)
                        let nonblocking = with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
                            var value <- native_gpu_swapchain(command, window, false)
                            verify(is_ok(value))
                            var optional <- move_unwrap(value)
                            verify(is_none(optional))
                            return sdl_ok()
                        }
                        verify(is_ok(nonblocking))
                    }
                    verify(SDL_ShowWindow(window))
                    verify(SDL_MinimizeWindow(window))
                    for (i in 0 .. 20) {SDL_PumpEvents(); SDL_Delay(5u)}
                    var entered = false
                    var minimized = with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var texture : SDL_GPUTexture?; w, h : uint) {
                        entered = true
                        return ok(7, type<SdlError>)
                    }
                    verify(is_ok(minimized))
                    verify(is_none(unwrap(minimized)) == !entered)
                    print("Minimized swapchain none: {is_none(unwrap(minimized))}\n")
                    verify(SDL_RestoreWindow(window))
                    return sdl_ok()
                }
            }
        }
    }
    if (is_err(result)) {print("{unwrap_err(result).operation}: {unwrap_err(result).message}\n"); return 1}
    var moved <- with_sdl(SDL_INIT_VIDEO) {
        return <- with_gpu_device() $(device : SDL_GPUDevice?) {
            var values : array<int>
            push(values, 99)
            return <- move_ok(values, type<SdlError>)
        }
    }
    verify(is_ok(moved))
    var values <- move_unwrap(moved)
    verify(length(values) == 1 && values[0] == 99)
    return 0
}
