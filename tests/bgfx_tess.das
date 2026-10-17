options gen2
require ../examples/gpu_port_bgfx/example_32_tess/tess_app.das as demo
require ../examples/gpu_port_bgfx/common/post_scene/scene.das as scene
require bgfx_multipass_checks
require bgfx_buffer_checks

def render(device : SDL_GPUDevice?; var r : demo::Resources; s : demo::Settings; name : string; frames : int) {
    return sdl_scope() { var output : SDL_GPUTexture ? = with_native_gpu_texture(device, gpu_texture(640u, 360u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
        for (i in range(frames)) { sdl_scope() { var command : SDL_GPUCommandBuffer ? & = with_native_gpu_commands(device) |> sdl_use; demo::draw(device, command, r, output, 640u, 360u, s, scene::Camera(eye = float3(0.0, 0.5, 0.0), pitch = 0.0)) |> sdl_try; return native_gpu_submit(command) } |> sdl_try }
        return read_image(device, output, 640u, 360u, name)
    }
}
def check(device : SDL_GPUDevice?) : SdlStatus { return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
    var s = demo::Settings(); demo::reset(device, r, s.patch) |> sdl_try
    let a <- render(device, r, s, "tess-default", 24) |> sdl_try; visible(a)
    let counts <- read_buffer(device, r.counters, 32u) |> sdl_try; verify(word(counts, 8) > 2u && word(counts, 16) > 0u, "GPU subdivision/culling absent"); verify(word(counts, 12) == 192u)
    let dispatch <- read_buffer(device, r.indirect, 12u) |> sdl_try; verify(word(dispatch, 0) == word(counts, 8) / 32u + 1u, "Indirect dispatch mismatch")
    s.freeze = true; let b <- render(device, r, s, "tess-frozen", 2) |> sdl_try; visible(b)
    let frozen <- read_buffer(device, r.counters, 32u) |> sdl_try; verify(word(frozen, 8) == word(counts, 8), "Freeze changes node count")
    s.wireframe = true; let c <- render(device, r, s, "tess-wire", 1) |> sdl_try; visible(c); verify(changed(b, c) > 500)
    s.wireframe = false; s.normals = true; let d <- render(device, r, s, "tess-normal", 1) |> sdl_try; visible(d); verify(changed(b, d) > 500)
    s.freeze = false; s.patch = 0; demo::reset(device, r, 0) |> sdl_try; let e <- render(device, r, s, "tess-patch0", 24) |> sdl_try; visible(e)
    let low <- read_buffer(device, r.counters, 32u) |> sdl_try; verify(word(low, 12) == 3u); return sdl_ok()
} }
[export]
def main(unused : bool) : int {
    let result = sdl_scope() { with_sdl(SDL_INIT_VIDEO) |> sdl_use; let device : SDL_GPUDevice ? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use; return check(device) }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }; print("GPU regression PASS\n"); return 0
}
