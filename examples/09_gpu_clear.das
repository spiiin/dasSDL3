options gen2
require dassdl3/sdl3_gpu_boost
require math

// SDL GPU path; no SDL_Renderer and no shaders are needed for a clear pass.
[export]
def main(smoke : bool) : int {
    var frames = 0
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS, true, "") $(device) {
            print("GPU backend: {SDL_GetGPUDeviceDriver(device)}\n")
            with_window("SDL GPU ClearScreen - Escape to exit", 640, 480, SDL_WINDOW_RESIZABLE) $(window) {
                device |> with_gpu_window(window) {
                    var event = SDL_MakeEvent()
                    var running = true
                    var attempts = 0
                    while (running) {
                        while (poll_event(event)) {
                            if (should_close(event, window)) { running = false }
                        }
                        if (!running) { break }
                        let phase = float(frames) / 40.0
                        var size : uint2
                        if (device |> gpu_clear(window, float4(0.15, 0.3 + 0.2 * sin(phase), 0.65, 1.0), size)) {
                            frames++
                            if (frames == 1) { print("Swapchain: {int(size.x)} x {int(size.y)}\n") }
                        }
                        attempts++
                        if (smoke && frames >= 60) { break }
                        if (smoke && attempts >= 300) { panic("GPU smoke: no drawable swapchain after 300 attempts") }
                        SDL_Delay(16u)
                    }
                }
            }
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
    }
    if (!available) { return smoke ? 77 : 1 }
    if (smoke && frames != 60) { panic("GPU smoke interrupted before 60 submitted frames") }
    print("GPU ClearScreen: {frames} submitted frames; claim and device released.\n")
    return 0
}
