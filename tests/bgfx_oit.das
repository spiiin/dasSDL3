options gen2
require ../examples/gpu/oit_app.das as demo
require bgfx_multipass_checks
require daslib/defer

def render(device : SDL_GPUDevice?; var r : demo::Resources; settings : demo::Settings; name : string) {
    return sdl_scope() {
        var output : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(640u, 480u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
        sdl_scope() {
            var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
            demo::draw(device, command, r, output, 640u, 480u, 0.6, settings) |> sdl_try
            return native_gpu_submit(command)
        } |> sdl_try
        return read_image(device, output, 640u, 480u, name)
    }
}
def check(device : SDL_GPUDevice?) : SdlStatus {
    return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
        for (mode in 0..3) {
            var settings = demo::Settings(mode = mode)
            let a <- render(device, r, settings, "oit-{mode}-forward") |> sdl_try
            settings.reverse = true
            let b <- render(device, r, settings, "oit-{mode}-reverse") |> sdl_try
            visible(a); visible(b)
            var colorful = 0
            for (i in 0 .. length(a) / 4) {
                let red = int(a[i * 4]); let green = int(a[i * 4 + 1]); let blue = int(a[i * 4 + 2])
                if (max(red, max(green, blue)) - min(red, min(green, blue)) > 40) { colorful++ }
            }
            verify(colorful > 1000, "OIT lost the transparent object colors")
            let pixels = changed(a, b, 3)
            if (mode == 0) { verify(pixels > 100, "Alpha blending unexpectedly order-independent") }
            else { verify(pixels < 100, "Weighted OIT depends on draw order") }
            print("OIT mode={mode}: {pixels} order-dependent pixels.\n")
        }
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
    return 0
}
