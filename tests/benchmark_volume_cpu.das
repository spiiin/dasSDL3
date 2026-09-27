options gen2
require ../examples/gpu/shadowvolumes_scene.das
[export]
def main(unused : bool) : int {
    let status = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(), false, "vulkan") |> sdl_use
        return with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
            for (mode in 0 .. 4) {
                let start = SDL_GetPerformanceCounter()
                var total = 0ul
                for (frame in 0 .. 30) {
                    let objects <- instances(float(frame) / 60.0, Settings(lights = 4))
                    let lights = scene_lights(float(frame) / 60.0, float3(3.0, 20.0, -58.0), Settings(lights = 4))
                    for (i in 0 .. 4) {
                        var old : array<float>
                        resize(r.volume_vertices, 0)
                        for (obj in objects) {
                            if (mode % 2 == 0) { append_volume(old, r.meshes[obj.mesh], obj.model, lights.positions[i].xyz, true, 180.0) }
                            else { append_volume_reused(r.volume_vertices, r.meshes[obj.mesh], obj.model, lights.positions[i].xyz, true, 180.0, r.volume_points, r.volume_far_points, r.volume_lit) }
                        }
                        total += uint64(mode % 2 == 0 ? length(old) : length(r.volume_vertices))
                    }
                }
                let ms = double(SDL_GetPerformanceCounter() - start) * 1000.0lf / double(SDL_GetPerformanceFrequency()) / 30.0lf
                print("CPU mode={mode} old={mode%2==0} ms={ms} floats={total}\n")
            }
            return sdl_ok()
        }
    }
    if (is_err(status)) { let e = unwrap_err(status); print("{e.operation}: {e.message}\n"); return 1 }
    return 0
}
