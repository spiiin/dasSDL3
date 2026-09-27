options gen2
require ../examples/gpu/shadowvolumes_scene.das as demo
require dassdl3/sdl3_scope
require dassdl3/sdl3_window_boost
require daslib/defer
require dassdl3/sdl3_init_boost
require ../examples/gpu/stencil_support.das as support

def benchmark(device : SDL_GPUDevice?; window : SDL_Window?) : SdlStatus {
    return demo::with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var depth : SDL_GPUTexture?
        var size = uint2(0u)
        defer() { if (depth != null) { SDL_ReleaseGPUTexture(device, depth) } }
        var settings = demo::Settings(lights = 4)
        let reference_volume = hint_string("DASSDL3_REFERENCE_VOLUME") |> unwrap_or("0") == "1"
        let cache_volume = hint_string("DASSDL3_CACHE_VOLUME") |> unwrap_or("1") != "0"
        var started = 0ul
        var rendered = 0
        print("BENCH cache_volume={cache_volume} reference_volume={reference_volume} settings width=1280 height=720 lights=4 driver={SDL_GetGPUDeviceDriver(device)} debug=0 immediate depth-fail silhouette low-poly delay=0\n")
        for (frame in 0 .. 720) {
            if (frame == 120) { started = SDL_GetPerformanceCounter() }
            SDL_PumpEvents()
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var color : SDL_GPUTexture?; width, height : uint) {
                if (width != 1280u || height != 720u) { return err(SdlError(operation = "benchmark", message = "Unexpected drawable size"), type<SdlUnit>) }
                support::replace_stencil(device, depth, size, width, height, r.depth_format) |> sdl_try
                demo::draw(device, command, r, color, depth, width, height, float(frame % 600) / 60.0, settings, reference_volume, cache_volume) |> sdl_try
                rendered++
                return sdl_ok()
            } |> sdl_try
            if (rendered != frame + 1) { return err(SdlError(operation = "benchmark", message = "Swapchain skipped a frame"), type<SdlUnit>) }
        }
        let seconds = double(SDL_GetPerformanceCounter() - started) / double(SDL_GetPerformanceFrequency())
        print("BENCH_RESULT dasSDL3 frames=600 seconds={seconds} fps={600.0lf/seconds} ms={seconds*1000.0lf/600.0lf}\n")
        sdl_status(SDL_WaitForGPUIdle(device), "wait for benchmark completion") |> sdl_try
        return sdl_ok()
    }
}
[export]
def main(unused : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window(WindowOptions(title = "dasSDL3 FPS benchmark: four lights", size = int2(1280, 720))) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(), false, "vulkan") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device, window), "claim") |> sdl_try
        {
            defer() { SDL_ReleaseWindowFromGPUDevice(device, window) }
            sdl_status(SDL_SetGPUSwapchainParameters(device, window, SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_SDR, SDL_GPUPresentMode.PRESENTMODE_IMMEDIATE), "immediate presentation") |> sdl_try
            return benchmark(device, window)
        }
    }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }
    return 0
}
