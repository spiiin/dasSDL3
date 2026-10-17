options gen2
require ../examples/gpu_port_bgfx/example_18_occlusion/occlusion_app.das as demo
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
        let culled <- render(device, r, settings, "occlusion-culled") |> sdl_try
        visible(culled)
        let bytes <- read_buffer(device, r.commands, 121u * 20u) |> sdl_try
        var hidden = 0
        for (i in 0..121) { verify(word(bytes, i * 20) == 36u); verify(word(bytes, i * 20 + 16) == uint(i)); if (word(bytes, i * 20 + 4) == 0u) { hidden++ } }
        verify(hidden > 10 && hidden < 110, "No meaningful GPU occlusion")
        settings.mode = 1
        let full <- render(device, r, settings, "occlusion-unculled") |> sdl_try
        verify(changed(culled, full, 0) == 0, "Culling changes visible pixels")
        print("GPU culled {hidden}/121 objects; exact image parity.\n")
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
    print("occlusion: GPU regression PASS\n"); return 0
}
