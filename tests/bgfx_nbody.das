options gen2
require ../examples/gpu_port_bgfx/example_17_nbody/nbody_app.das as demo
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
        let initial <- render(device, r, settings, "nbody-initial") |> sdl_try
        visible(initial)
        let positions <- read_buffer(device, r.current, r.count * 16u) |> sdl_try
        let previous <- read_buffer(device, r.previous, r.count * 16u) |> sdl_try
        settings.paused = false
        let evolved <- render(device, r, settings, "nbody-evolved") |> sdl_try
        let actual <- read_buffer(device, r.current, r.count * 16u) |> sdl_try
        for (i in 0..8) {
            let p = vector3(positions, i * 16); let prev = vector3(previous, i * 16); var acceleration = float3(0.0)
            for (j in 0..int(r.count)) { let d = vector3(positions, j * 16) - p; let d2 = dot(d, d); acceleration += d * (0.01 / (sqrt(d2 * d2 * d2) + 0.1)) }
            acceleration += (prev - p) * 0.1; let mag = length(acceleration)
            if (mag > 0.0) { acceleration *= min(mag, 10.0) / mag }
            let expected = p * 2.0 - prev + acceleration * 0.01
            verify(length(vector3(actual, i * 16) - expected) < 0.002, "GPU Verlet/CPU oracle mismatch")
        }
        settings.mode = 2; settings.reset = true; settings.paused = true
        let torus <- render(device, r, settings, "nbody-torus") |> sdl_try
        visible(torus); verify(changed(initial, torus) > 500, "N-body initial shape missing")
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
    print("nbody: GPU regression PASS\n"); return 0
}
