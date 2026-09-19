options gen2
require dassdl3/sdl3_gpu_boost
require daslib/rtti
require daslib/strings_boost

def draw(device : SDL_GPUDevice?; window : SDL_Window?; color : float4) {
    for (i in 0 .. 120) {
        var event = SDL_MakeEvent()
        while (poll_event(event)) {}
        var size : uint2
        if (gpu_clear(device, window, color, size)) {
            verify(size.x > 0u && size.y > 0u)
            return
        }
        verify(size == uint2(0u))
        SDL_Delay(10u)
    }
    panic("GPU window did not become drawable")
}

[export]
def main(smoke : bool) : int {
    verify(smoke)
    var available = false
    var transitions = 0
    var minimized_submissions = 0
    var minimized_skips = 0
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS, true, "") $(device) {
            print("GPU windows backend: {SDL_GetGPUDeviceDriver(device)}\n")
            with_window("GPU outer window", 240, 180, SDL_WINDOW_RESIZABLE) $(first) {
                device |> with_gpu_window(first) {
                    for (cycle in 0 .. 2) {
                        var caught = false
                        try {
                            with_window("GPU inner window", 160, 120, SDL_WINDOW_RESIZABLE) $(second) {
                                device |> with_gpu_window(second) {
                                    verify(SDLTestGPUClaims() == 2)
                                    draw(device, first, float4(0.1, 0.3, 0.6, 1.0))
                                    draw(device, second, float4(0.6, 0.2, 0.1, 1.0))
                                    let minimized = SDLTestGPUMinimized(second, true)
                                    if (minimized < 0) { panic("minimize: {SDL_GetError()}") }
                                    if (minimized == 1) {
                                        var size = uint2(99u)
                                        // SDL may still supply a drawable for a minimized window.
                                        if (gpu_clear(device, second, float4(0.0, 0.0, 0.0, 1.0), size)) {
                                            verify(size.x > 0u && size.y > 0u)
                                            minimized_submissions++
                                        } else {
                                            verify(size == uint2(0u))
                                            minimized_skips++
                                        }
                                        // The other window must continue to present independently.
                                        draw(device, first, float4(0.1, 0.6, 0.2, 1.0))
                                    }
                                    let restored = SDLTestGPUMinimized(second, false)
                                    if (restored < 0) { panic("restore: {SDL_GetError()}") }
                                    if (minimized == 1 && restored == 1) { transitions++ }
                                    if (restored == 1) {
                                        draw(device, second, float4(0.6, 0.5, 0.1, 1.0))
                                        verify(SDLTestGPUResize(second))
                                        draw(device, second, float4(0.2, 0.5, 0.6, 1.0))
                                    }
                                    if (cycle == 1) { panic("inner-window-panic") }
                                }
                            }
                        } recover {
                            var error = ""
                            error := rtrim(this_context().last_exception)
                            if (error != "inner-window-panic") { panic(error) }
                            caught = true
                        }
                        verify(caught == (cycle == 1))
                        verify(SDLTestGPUDevices() == 1 && SDLTestGPUClaims() == 1)
                        verify(SDL_GPUWindowClaimedBy(device, first))
                        draw(device, first, float4(0.2, 0.4, 0.7, 1.0))
                    }
                }
            }
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
        verify(SDLTestGPUDevices() == 0 && SDLTestGPUClaims() == 0)
    }
    if (!available) { return 77 }
    print("Two GPU windows: independent frames and normal/panic inner cleanup passed.\n")
    if (transitions != 2) {
        print("SKIP: window manager did not confirm all minimize/restore transitions.\n")
        return 77
    }
    print("Two minimize/restore cycles: resumed frames and resize passed. Minimized: {minimized_submissions} submitted, {minimized_skips} skipped.\n")
    return 0
}
