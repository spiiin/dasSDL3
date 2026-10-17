options gen2
require ../examples/gpu_port_bgfx/example_31_svt/svt_app.das as demo
require ../examples/gpu_port_bgfx/common/post_scene/scene.das as scene
require bgfx_multipass_checks

def render(device : SDL_GPUDevice?; var r : demo::Resources; s : demo::Settings; name : string) {
    return sdl_scope() { var output : SDL_GPUTexture ? = with_native_gpu_texture(device, gpu_texture(640u, 360u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
        sdl_scope() { var command : SDL_GPUCommandBuffer ? & = with_native_gpu_commands(device) |> sdl_use; demo::draw(command, r, output, 640u, 360u, s, scene::Camera(eye = float3(0.0, 5.0, 0.0), pitch = 0.0)) |> sdl_try; return native_gpu_submit(command) } |> sdl_try
        return read_image(device, output, 640u, 360u, name)
    }
}
def check(device : SDL_GPUDevice?) : SdlStatus { return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
    var s = demo::Settings(updates = 25)
    let a <- render(device, r, s, "svt-root") |> sdl_try; visible(a)
    for (i in range(8)) { demo::request_feedback(device, r) |> sdl_try
        let fences <- array(r.fence); sdl_status(SDL_WaitForGPUFencesArray(device, true, fences), "Test feedback wait") |> sdl_try
        demo::process_feedback(device, r, s) |> sdl_try
    }
    verify(r.uploads > 1u && r.pages[5460].slot == 0, "Feedback streaming absent/root evicted")
    let b <- render(device, r, s, "svt-streamed") |> sdl_try; visible(b); verify(changed(a, b) > 100, "Page table not used")
    s.colors = true; s.borders = true; let c <- render(device, r, s, "svt-debug") |> sdl_try; visible(c); verify(changed(b, c) > 1000)
    for (i in range(length(r.slots))) { let id = r.slots[i]; if (id >= 0) { verify(r.pages[id].slot == i, "LRU directory mismatch") } }
    return sdl_ok()
} }
[export]
def main(unused : bool) : int {
    let result = sdl_scope() { with_sdl(SDL_INIT_VIDEO) |> sdl_use; let device : SDL_GPUDevice ? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use; return check(device) }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }; print("GPU regression PASS\n"); return 0
}
