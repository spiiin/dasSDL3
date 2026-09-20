options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_gpu_swapchain_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    return with_window("SDL GPU swapchain",320,240,0ul) $(window : SDL_Window?) {
        return device |> with_gpu_window(window) {
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
}

[export]
def main(smoke : bool) : int {
    let result = with_sdl() {
        return with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            return run_gpu_example(device, smoke)
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
