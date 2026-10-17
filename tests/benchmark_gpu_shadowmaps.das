options gen2
require ../examples/gpu_port_bgfx/common/shadowmaps/shadowmaps_app.das as demo
require dassdl3/sdl3_scope
require dassdl3/sdl3_window_boost
require daslib/defer

def benchmark(device : SDL_GPUDevice?; window : SDL_Window?) : SdlStatus {
    return demo::with_resources(device,SDL_GetGPUSwapchainTextureFormat(device,window)) $(var r) {
        var settings=demo::Settings(kind=0,filter=1)
        var started=SDL_GetPerformanceCounter()
        var measuring=false
        var measured=0
        var rendered=0
        print("BENCH settings width=1280 height=720 case=shadowmaps settings=kind=0,filter=1 driver={SDL_GetGPUDeviceDriver(device)} debug=0 immediate samples=1 fixed_time=3 delay=0\n")
        while (true) {
            let elapsed=double(SDL_GetPerformanceCounter()-started)/double(SDL_GetPerformanceFrequency())
            if (!measuring && elapsed>=2.0lf) { measuring=true; measured=0; started=SDL_GetPerformanceCounter() }
            elif (measuring && elapsed>=5.0lf) { break }
            SDL_PumpEvents()
            with_native_gpu_swapchain(device,window) $(command : SDL_GPUCommandBuffer?; var color : SDL_GPUTexture?; width,height : uint) {
                if (width!=1280u || height!=720u) { return err(SdlError(operation="benchmark",message="Unexpected drawable size"),type<SdlUnit>) }
                demo::draw(device,command,r,color,width,height,3.0,settings) |> sdl_try
                rendered++
                return sdl_ok()
            } |> sdl_try
            if (measuring) { measured++ }
            if (rendered!=1) { return err(SdlError(operation="benchmark",message="Swapchain skipped a frame"),type<SdlUnit>) }
            rendered=0
        }
        sdl_status(SDL_WaitForGPUIdle(device),"benchmark drain") |> sdl_try
        let seconds=double(SDL_GetPerformanceCounter()-started)/double(SDL_GetPerformanceFrequency())
        print("BENCH_RESULT dasSDL3 frames={measured} seconds={seconds} fps={double(measured)/seconds} ms={seconds*1000.0lf/double(measured)}\n")
        sdl_status(SDL_WaitForGPUIdle(device),"wait for benchmark completion") |> sdl_try
        return sdl_ok()
    }
}
[export]
def main(unused : bool) : int {
    let result=sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window(WindowOptions(title="dasSDL3 benchmark shadowmaps",size=int2(1280,720))) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(),false,"vulkan") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device,window),"claim") |> sdl_try
        {
            defer() { SDL_ReleaseWindowFromGPUDevice(device,window) }
            sdl_status(SDL_SetGPUSwapchainParameters(device,window,SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_SDR,SDL_GPUPresentMode.PRESENTMODE_IMMEDIATE),"immediate presentation") |> sdl_try
            return benchmark(device,window)
        }
    }
    if (is_err(result)) { let e=unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }
    return 0
}
