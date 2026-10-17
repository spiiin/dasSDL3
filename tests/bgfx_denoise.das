options gen2
require ../examples/gpu_port_bgfx/example_34_denoise/denoise_app.das as demo
require ../examples/gpu_port_bgfx/common/post_scene/scene.das as scene
require bgfx_multipass_checks

def render(device : SDL_GPUDevice?; var world : scene::Scene; var r : demo::Resources; settings : demo::Settings; name : string; frame : uint = 0u) {
    return sdl_scope() {
        var output : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(640u, 360u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
        sdl_scope() { var command : SDL_GPUCommandBuffer ? & = with_native_gpu_commands(device) |> sdl_use
            demo::draw(device, command, world, r, output, 640u, 360u, settings, scene::Camera(eye = float3(0.0, 1.5, 0.0)), 0.0, frame) |> sdl_try
            return native_gpu_submit(command)
        } |> sdl_try
        return read_image(device, output, 640u, 360u, name)
    }
}
def check(device : SDL_GPUDevice?) : SdlStatus {
    return scene::with_scene(device, 43) $(var world) {
        return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
            var s = demo::Settings()
            let a <- render(device, world, r, s, "denoise-default") |> sdl_try; visible(a)
            verify(length(world.models) == 100 && length(world.meshes) == 6)
            s.temporal = false; s.passes = 0; let b <- render(device, world, r, s, "denoise-raw") |> sdl_try; visible(b); verify(changed(a, b) > 1000, "Spatial filter absent")
            let cycle <- render(device, world, r, s, "denoise-noise-cycle", 8u) |> sdl_try; verify(changed(b, cycle, 0) == 0, "Noise must repeat after eight frames")
            s.noise = 0; let c <- render(device, world, r, s, "denoise-clean") |> sdl_try; visible(c); verify(changed(b, c) > 1000)
            s = demo::Settings(); s.txaa = true
            for (i in range(8)) { let d <- render(device, world, r, s, "denoise-txaa", uint(i)) |> sdl_try; visible(d) }
            s.extent = 0; s.passes = 6; let e <- render(device, world, r, s, "denoise-three") |> sdl_try; visible(e)
            return sdl_ok()
        }
    }
}
[export]
def main(unused : bool) : int {
    let result = sdl_scope() { with_sdl(SDL_INIT_VIDEO) |> sdl_use; let device : SDL_GPUDevice ? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use; return check(device) }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }; print("GPU regression PASS\n"); return 0
}
