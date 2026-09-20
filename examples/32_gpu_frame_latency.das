options gen2
require dassdl3/sdl3_gpu_swapchain_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            let scope_ok_1 = with_window("SDL GPU swapchain",320,240,0ul) $(window : SDL_Window?) {
                let scope_ok_2 = device |> with_gpu_window(window) {
                    for (count in 1u .. 4u) {
                        var operation_result_1 <- device |> gpu_frames_in_flight(count)
                        if (is_err(operation_result_1)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                        print("Allowed frames in flight: {count} (not an FPS cap)\n")
                        for (i in 0 .. (smoke ? 3 : 60)) {
                            var event = SDL_MakeEvent()
                            while (is_some(poll_event(event))) {}
                            var operation_result_2 <- device |> gpu_wait_swapchain(window)
                            if (is_err(operation_result_2)) { example_failed = true; print("SDL operation: {unwrap_err(operation_result_2).message}\n"); return err(unwrap_err(operation_result_2),type<SdlUnit>) }
                        }
                    }

                    return sdl_ok()
                }
                if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }

                return sdl_ok()
            }
            if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
