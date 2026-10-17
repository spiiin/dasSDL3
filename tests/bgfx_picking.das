options gen2
require ../examples/gpu_port_bgfx/example_21_picking/picking_app.das as demo
require bgfx_multipass_checks
require bgfx_buffer_checks
require daslib/defer

def render(device : SDL_GPUDevice?; var r : demo::Resources; settings : demo::Settings; name : string; time : float = 0.6) {
    return sdl_scope() {
        var output : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(640u, 480u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
        sdl_scope() {
            var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
            demo::draw(device, command, r, output, 640u, 480u, time, settings) |> sdl_try
            return native_gpu_submit(command)
        } |> sdl_try
        return read_image(device, output, 640u, 480u, name)
    }
}
def check(device : SDL_GPUDevice?) : SdlStatus {
    return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
        var settings = demo::Settings()
        settings.paused = true
        let baseline <- render(device, r, settings, "picking-scene") |> sdl_try
        visible(baseline)
        for (id in 1..13) {
            let p = demo::camera(640u, 480u) * float4(demo::object_position(id), 1.0)
            let pixel = int2(int((p.x / p.w * 0.5 + 0.5) * 640.0), int((0.5 - p.y / p.w * 0.5) * 480.0))
            demo::request_pick(device, r, pixel) |> sdl_try
            verify(r.fence != null, "Picking did not submit a readback fence")
            let fences <- array(r.fence)
            sdl_status(SDL_WaitForGPUFencesArray(device, true, fences), "Wait in test only") |> sdl_try
            demo::poll_pick(device, r) |> sdl_try
            verify(r.selected == uint(id), "Wrong picked object")
        }
        r.selected = 5u
        let highlight <- render(device, r, settings, "picking-highlight") |> sdl_try
        verify(changed(baseline, highlight) > 100, "Selection highlight missing")
        demo::request_pick(device, r, int2(0)) |> sdl_try
        let fences <- array(r.fence)
        sdl_status(SDL_WaitForGPUFencesArray(device, true, fences), "Background pick test") |> sdl_try
        demo::poll_pick(device, r) |> sdl_try; verify(r.selected == 0u, "Background must have ID zero")
        return sdl_ok()
    }
}
[export]
def main(unused : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use
        return check(device)
    }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }
    print("picking: GPU regression PASS\n"); return 0
}
