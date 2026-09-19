options gen2
require dassdl3/sdl3_gpu_boost
require daslib/rtti
require daslib/strings_boost

def frame(device : SDL_GPUDevice?; window : SDL_Window?) {
    var submitted = false
    for (i in 0 .. 120) {
        var event = SDL_MakeEvent()
        while (poll_event(event)) {}
        var size : uint2
        if (gpu_clear(device, window, float4(0.1, 0.2, 0.3, 1.0), size)) {
            verify(size.x > 0u && size.y > 0u)
            submitted = true
            break
        }
        SDL_Delay(10u)
    }
    verify(submitted, "GPU window did not become drawable")
}
[export]
def main(smoke : bool) : int {
    verify(smoke)
    var available = false
    with_sdl() {
        verify(!try_with_gpu_device(GPU_CLEAR_FORMATS, true, "dassdl3-invalid-driver") $(unused) {
            panic("invalid driver invoked block")
        })
        verify(SDLTestGPUDevices() == 0)
        available = try_with_gpu_device(GPU_CLEAR_FORMATS, true, "") $(device) {
            print("GPU lifetime backend: {SDL_GetGPUDeviceDriver(device)}\n")
            verify(SDLTestGPUDevices() == 1)
            with_window("GPU lifetime contracts", 160, 120, SDL_WINDOW_RESIZABLE) $(window) {
                var size : uint2
                verify(SDL_ClearGPUWindow(device, window, 0.0, 0.0, 0.0, 1.0, size.x, size.y) == -1)
                device |> with_gpu_window(window) {
                    verify(SDLTestGPUClaims() == 1)
                    verify(!SDL_ClaimGPUWindowScoped(device, window))
                    verify(SDL_GPUWindowClaimedBy(device, window))
                    frame(device, window)
                    verify(SDLTestGPUResize(window))
                    frame(device, window)
                    with_window("unclaimed window", 80, 60, SDL_WINDOW_HIDDEN) $(other) {
                        verify(SDL_ClearGPUWindow(device, other, 0.0, 0.0, 0.0, 1.0, size.x, size.y) == -1)
                        verify(!SDL_ReleaseGPUWindowScoped(device, other))
                        verify(SDLTestGPUClaims() == 1)
                    }
                    return
                }
                verify(SDLTestGPUClaims() == 0)
                var caught = false
                try {
                    device |> with_gpu_window(window) {
                        frame(device, window)
                        panic("gpu-window-panic")
                    }
                } recover {
                    caught = true
                    verify(rtrim(this_context().last_exception) == "gpu-window-panic")
                }
                verify(caught && SDLTestGPUClaims() == 0)
                device |> with_gpu_window(window) { frame(device, window) }
                window |> with_renderer() $(renderer) {
                    verify(!SDL_ClaimGPUWindowScoped(device, window))
                    verify(SDLTestGPUClaims() == 0)
                }
            }
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
        verify(SDLTestGPUDevices() == 0 && SDLTestGPUClaims() == 0)
        if (available) {
            var caught = false
            try {
                with_gpu_device() $(device) {
                    with_window("GPU device panic", 160, 120, 0ul) $(window) {
                        device |> with_gpu_window(window) { panic("gpu-device-panic") }
                    }
                }
            } recover {
                caught = true
                verify(rtrim(this_context().last_exception) == "gpu-device-panic")
            }
            verify(caught && SDLTestGPUDevices() == 0 && SDLTestGPUClaims() == 0)
        }
    }
    if (!available) { return 77 }
    print("GPU scopes: normal, early return, panic, reclaim and renderer conflict passed.\n")
    return 0
}
