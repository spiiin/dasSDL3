options gen2
require ../examples/gpu_port_bgfx/example_35_sss/sss_app.das as demo
require ../examples/gpu_port_bgfx/common/post_scene/scene.das as scene
require bgfx_multipass_checks

def render(device : SDL_GPUDevice?; var world : scene::Scene; var r : demo::Resources; settings : demo::Settings; name : string; frame : uint = 0u) {
    return sdl_scope() {
        var output : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(640u, 360u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
        sdl_scope() { var command : SDL_GPUCommandBuffer ? & = with_native_gpu_commands(device) |> sdl_use
            demo::draw(device, command, world, r, output, 640u, 360u, settings, scene::Camera(eye = float3(0.0, 1.5, -4.0)), 0.0, frame) |> sdl_try
            return native_gpu_submit(command)
        } |> sdl_try
        return read_image(device, output, 640u, 360u, name)
    }
}
def check(device : SDL_GPUDevice?) : SdlStatus {
    return scene::with_scene(device, 44) $(var world) {
        return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
            var s = demo::Settings()
            let a <- render(device, world, r, s, "sss-default") |> sdl_try; visible(a)
            verify(length(world.models) == 100 && length(world.meshes) == 6)
            s.shadows_only = true; let b <- render(device, world, r, s, "sss-hard") |> sdl_try; visible(b); verify(changed(a, b) > 1000)
            let cycle <- render(device, world, r, s, "sss-noise-cycle", 8u) |> sdl_try; verify(changed(b, cycle, 0) == 0, "Shadow noise period mismatch")
            s.softness = 1; let c <- render(device, world, r, s, "sss-soft") |> sdl_try; visible(c)
            s.softness = 2; let d <- render(device, world, r, s, "sss-verysoft") |> sdl_try; visible(d); verify(changed(b, d) > 100, "Soft shadows missing")
            s.pixels = true; s.steps = 32; let e <- render(device, world, r, s, "sss-pixels") |> sdl_try; visible(e)
            return sdl_ok()
        }
    }
}
[export]
def main(unused : bool) : int {
    let result = sdl_scope() { with_sdl(SDL_INIT_VIDEO) |> sdl_use; let device : SDL_GPUDevice ? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use; return check(device) }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }; print("GPU regression PASS\n"); return 0
}
