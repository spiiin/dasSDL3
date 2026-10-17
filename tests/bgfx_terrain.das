options gen2
require ../examples/gpu_port_bgfx/example_19_terrain/terrain_app.das as demo
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
        let flat <- render(device, r, settings, "terrain-flat") |> sdl_try
        visible(flat)
        for (i in 0..32) { demo::brush(r.heights, float2(0.5), false) }
        r.mode = -1
        let raised <- render(device, r, settings, "terrain-texture") |> sdl_try
        verify(changed(flat, raised) > 100, "Brush did not deform terrain")
        settings.mode = 1
        let cpu <- render(device, r, settings, "terrain-vertices") |> sdl_try
        verify(changed(raised, cpu, 2) < 20, "GPU height/CPU vertex mismatch")
        settings.reset = true
        let reset <- render(device, r, settings, "terrain-reset") |> sdl_try
        verify(changed(flat, reset, 2) < 20, "Reset did not flatten terrain")
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
    print("terrain: GPU regression PASS\n"); return 0
}
