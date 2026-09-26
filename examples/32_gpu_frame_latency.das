options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_swapchain_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : SdlStatus {
    return sdl_scope() {
        let window : SDL_Window? = with_window("SDL GPU swapchain", 320, 240, 0ul) |> sdl_use
        device |> with_gpu_window(window) |> sdl_use
        for (count in 1u .. 4u) {
            device |> gpu_frames_in_flight(count) |> sdl_try
            print("Allowed frames in flight: {count} (not an FPS cap)\n")
            for (i in 0 .. (smoke ? 3 : 60)) {
                var event = SDL_MakeEvent()
                while (is_some(poll_event(event))) {}
                device |> gpu_wait_swapchain(window) |> sdl_try
            }
        }

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_gpu_device(GPU_SHADER_FORMATS, true, "") |> sdl_use
        return run_gpu_example(device, smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation == "with_gpu_device" ? 77 : 1
    }
    return 0
}
