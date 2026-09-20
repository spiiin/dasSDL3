options gen2
require dassdl3/sdl3_gpu_swapchain_boost

def wait_available(device : SDL_GPUDevice?; window : SDL_Window?) {
    var event = SDL_MakeEvent()
    while (poll_event(event)) {}
    device |> gpu_wait_swapchain(window)

}
[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        verify(!SDL_SetGPUFramesInFlightChecked(null,1u))
        verify(!SDL_WaitGPUSwapchainChecked(null,null))
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            verify(!SDL_SetGPUFramesInFlightChecked(device,0u))
            verify(!SDL_SetGPUFramesInFlightChecked(device,4u))
            verify(!SDL_SetGPUFramesInFlightChecked(device,0xffffffffu))
            verify(SDL_GPUWindowPresentSupported(device,null,0u) == -1)
            let scope_ok_1 = with_window("Swapchain contracts",180,140,SDL_WINDOW_RESIZABLE) $(window) {
                verify(SDL_GPUWindowCompositionSupported(device,window,0u) == -1)
                verify(SDL_ConfigureGPUSwapchainChecked(device,window,0u,0u) == -1)
                verify(!SDL_WaitGPUSwapchainChecked(device,window))
                let scope_ok_2 = device |> with_gpu_window(window) {
                    verify(device |> gpu_supports_present_mode(window,SDL_GPU_PRESENTMODE_VSYNC))
                    verify(device |> gpu_supports_composition(window,SDL_GPU_SWAPCHAINCOMPOSITION_SDR))
                    let initial_format = device |> gpu_swapchain_format(window)
                    verify(initial_format != SDL_GPU_TEXTUREFORMAT_INVALID)
                    verify(SDL_GPUWindowPresentSupported(device,window,0xffffffffu) == -1)
                    verify(SDL_GPUWindowCompositionSupported(device,window,0xffffffffu) == -1)
                    verify(SDL_ConfigureGPUSwapchainChecked(device,window,0u,3u) == -1)
                    verify(SDL_ConfigureGPUSwapchainChecked(device,window,4u,0u) == -1)
                    verify(device |> gpu_swapchain_format(window) == initial_format)
                        for (composition in SDL_GPU_SWAPCHAINCOMPOSITION_SDR .. SDL_GPU_SWAPCHAINCOMPOSITION_HDR10_ST2084+1u) {
                            let supported_composition = device |> gpu_supports_composition(window,composition)
                            for (mode in SDL_GPU_PRESENTMODE_VSYNC .. SDL_GPU_PRESENTMODE_MAILBOX+1u) {
                                let supported_mode = device |> gpu_supports_present_mode(window,mode)
                                let before = device |> gpu_swapchain_format(window)
                                let changed = device |> gpu_try_configure_swapchain(window,composition,mode)
                                verify(changed == (supported_composition && supported_mode))
                                let after = device |> gpu_swapchain_format(window)
                                if (!changed) { verify(after == before) }
                                wait_available(device,window)
                                print("Composition {composition}, mode {mode}: {changed}, format {after}\n")
                            }
                        }
                        verify(device |> gpu_try_configure_swapchain(window,SDL_GPU_SWAPCHAINCOMPOSITION_SDR,SDL_GPU_PRESENTMODE_VSYNC))
                        verify(device |> gpu_swapchain_format(window) == initial_format)
                    for (count in 1u .. 4u) {
                        device |> gpu_frames_in_flight(count)
                        for (i in 0 .. 4) { wait_available(device,window) }
                    }
                    // Configuration is per window; frame limit is per device.
                    let scope_ok_3 = with_window("Second swapchain",120,90,0ul) $(second) {
                        let scope_ok_4 = device |> with_gpu_window(second) {
                            let second_format = device |> gpu_swapchain_format(second)
                            if (device |> gpu_supports_present_mode(window,SDL_GPU_PRESENTMODE_IMMEDIATE)) {
                                verify(device |> gpu_try_configure_swapchain(window,SDL_GPU_SWAPCHAINCOMPOSITION_SDR,SDL_GPU_PRESENTMODE_IMMEDIATE))
                            }
                            verify(device |> gpu_swapchain_format(second) == second_format)
                            wait_available(device,second)
                            wait_available(device,window)
                        }
                        verify(scope_ok_4)
                    }
                    verify(scope_ok_3)
                    let scope_ok_5 = with_gpu_device() $(other) {
                        verify(SDL_GPUWindowPresentSupported(other,window,0u) == -1)
                        verify(SDL_ConfigureGPUSwapchainChecked(other,window,0u,0u) == -1)
                        verify(!SDL_WaitGPUSwapchainChecked(other,window))
                        other |> gpu_frames_in_flight(1u)
                        let scope_ok_6 = with_window("Other GPU",120,90,0ul) $(second) {
                            let scope_ok_7 = other |> with_gpu_window(second) { wait_available(other,second) }
                            verify(scope_ok_7)
                        }
                        verify(scope_ok_6)
                    }
                    verify(scope_ok_5)
                    wait_available(device,window)
                    device |> gpu_frames_in_flight(2u)
                }
                verify(scope_ok_2)
                verify(SDL_GPUWindowFormatChecked(device,window) == SDL_GPU_TEXTUREFORMAT_INVALID)
                verify(!SDL_WaitGPUSwapchainChecked(device,window))
                // Reclaim resets swapchain defaults; no cached adapter state.
                let scope_ok_8 = device |> with_gpu_window(window) {
                    verify(device |> gpu_try_configure_swapchain(window,SDL_GPU_SWAPCHAINCOMPOSITION_SDR,SDL_GPU_PRESENTMODE_VSYNC))
                    wait_available(device,window)
                }
                verify(scope_ok_8)
            }
            verify(scope_ok_1)
            let dead_window = SDL_CreateWindow("destroyed-window check",64,64,SDL_WINDOW_HIDDEN)
            verify(dead_window != null)
            SDL_DestroyWindow(dead_window)
            verify(SDL_GPUWindowPresentSupported(device,dead_window,0u) == -1)
            verify(!SDL_WaitGPUSwapchainChecked(device,dead_window))
            print("Swapchain capabilities/configuration/latency PASS: {SDL_GetGPUDeviceDriver(device)}\n")
        }
        if (available) {
            let dead_device = SDL_CreateGPUDeviceScoped(GPU_SHADER_FORMATS,true,"")
            verify(dead_device != null)
            verify(SDL_DestroyGPUDeviceScoped(dead_device))
            verify(!SDL_SetGPUFramesInFlightChecked(dead_device,1u))
        }
    }
    verify(scope_ok_0)
    return available ? 0 : 77
}
