options gen2
require dassdl3/sdl3_gpu_swapchain_boost

[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            with_window("SDL GPU swapchain",320,240,0ul) $(window) {
                device |> with_gpu_window(window) {
                    for (count in 1u .. 4u) {
                        device |> gpu_frames_in_flight(count)
                        print("Allowed frames in flight: {count} (not an FPS cap)\n")
                        for (i in 0 .. (smoke ? 3 : 60)) {
                            var event = SDL_MakeEvent()
                            while (poll_event(event)) {}
                            device |> gpu_wait_swapchain(window)
                            gpu_clear(device,window,float4(0.1,0.2*float(count),0.3,1.0))
                        }
                    }
                }
            }
        }
    }
    return available ? 0 : 77
}
