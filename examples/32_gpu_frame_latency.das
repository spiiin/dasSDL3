options gen2
require dassdl3/sdl3_gpu_swapchain_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            let scope_ok_1 = with_window("SDL GPU swapchain",320,240,0ul) $(window) {
                let scope_ok_2 = device |> with_gpu_window(window) {
                    for (count in 1u .. 4u) {
                        if (!(device |> gpu_frames_in_flight(count))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        print("Allowed frames in flight: {count} (not an FPS cap)\n")
                        for (i in 0 .. (smoke ? 3 : 60)) {
                            var event = SDL_MakeEvent()
                            while (poll_event(event)) {}
                            if (!(device |> gpu_wait_swapchain(window))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        }
                    }
                }
                if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
