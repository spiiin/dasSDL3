options gen2
require ../examples/gpu_port_bgfx/example_33_bunnylod/bunnylod_app.das as demo
require bgfx_multipass_checks

def render(device : SDL_GPUDevice?; var r : demo::Resources; lod : float; name : string) {
    demo::update_lod(device, r, lod) |> sdl_try
    return sdl_scope() { var output : SDL_GPUTexture ? = with_native_gpu_texture(device, gpu_texture(640u, 360u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
        sdl_scope() { var command : SDL_GPUCommandBuffer ? & = with_native_gpu_commands(device) |> sdl_use; demo::draw(device, command, r, output, 640u, 360u, 0.0) |> sdl_try; return native_gpu_submit(command) } |> sdl_try
        return read_image(device, output, 640u, 360u, name)
    }
}
def check(device : SDL_GPUDevice?) : SdlStatus { return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
    let a <- render(device, r, 1.0, "bunnylod-full") |> sdl_try; visible(a); var lit = 0; for (i in range(length(a) / 4)) { if (int(a[i * 4]) + int(a[i * 4 + 1]) + int(a[i * 4 + 2]) > 200) { lit++ } }; verify(lit > 1000, "Bunny is unlit"); let full = r.buffers.count
    let b <- render(device, r, 0.2, "bunnylod-low") |> sdl_try; visible(b); verify(r.buffers.count < full / 5u && r.buffers.count > 0u, "Collapse does not reduce triangles"); verify(changed(a, b) > 100)
    let c <- render(device, r, 1.0, "bunnylod-restored") |> sdl_try; verify(changed(a, c) == 0, "LOD reset differs"); return sdl_ok()
} }
[export]
def main(unused : bool) : int {
    let result = sdl_scope() { with_sdl(SDL_INIT_VIDEO) |> sdl_use; let device : SDL_GPUDevice ? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use; return check(device) }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }; print("GPU regression PASS\n"); return 0
}
