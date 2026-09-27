options gen2
require ../examples/gpu/shadowvolumes_scene.das as demo
require ../examples/gpu/bgfx_support.das public
require bgfx_capture
require ../examples/gpu/port_geometry.das as geo
require ../examples/gpu/shadowvolumes_geometry.das as oracle
require dassdl3/sdl3_init_boost
require daslib/defer
let WIDTH = 640u
let HEIGHT = 480u
def check_scene(device : SDL_GPUDevice?) : SdlStatus {
    // The fast adjacency path must preserve the independently tested cube volume.
    let cube <- demo::closed_cube()
    let model = geo::model_matrix(float3(0.0, 1.05, 0.0), float3(0.8))
    let old <- oracle::shadow_volume(cube.geometry, model, float3(-3.0, 6.0, -2.0), true)
    var fast : array<float>
    demo::append_volume(fast, cube, model, float3(-3.0, 6.0, -2.0), true, 30.0)
    verify(length(fast) == length(old.vertices), "Changed volume topology")
    for (i in 0 .. length(fast) / 8) {
        for (c in 0 .. 3) { verify(fast[i * 8 + c] == old.vertices[i * 8 + c], "Fast volume differs from CPU reference") }
    }
    return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
        for (mesh in r.meshes) {
            for (i in 0 .. length(mesh.geometry.indices)) {
                let a = geo::position_at(mesh.geometry, mesh.geometry.indices[i])
                let b = geo::position_at(mesh.geometry, mesh.geometry.indices[i / 3 * 3 + (i + 1) % 3])
                let neighbour = mesh.neighbours[i]
                var found = 0
                for (e in 0 .. 3) {
                    let edge = neighbour * 3 + e
                    if (geo::position_at(mesh.geometry, mesh.geometry.indices[edge]) == b && geo::position_at(mesh.geometry, mesh.geometry.indices[neighbour * 3 + (e + 1) % 3]) == a) {
                        verify(mesh.neighbours[edge] == i / 3, "Nonreciprocal adjacency"); found++
                    }
                }
                verify(found == 1, "Open or inconsistently wound caster")
            }
        }
        return sdl_scope() {
            var color : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
            var depth : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT, r.depth_format, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_use
            var reference : array<uint8>
            for (frame in 0 .. 13) {
                var settings = demo::Settings()
                if (frame == 1) { settings.shadows = false }
                if (frame == 2) { settings.zfail = false }
                if (frame == 3) { settings.silhouette = false }
                if (frame == 4) { settings.lights = 3 }
                if (frame == 5) { settings.second_scene = true }
                if (frame == 6) { settings.textures = false }
                if (frame == 8) { settings.inside = true }
                if (frame == 9) { settings.debug = true }
                if (frame == 10) { settings.cubes = true }
                if (frame == 11) { settings.alternate_pattern = true }
                if (frame == 12) { settings.specular = false }
                sdl_scope() {
                    var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
                    demo::draw(device, command, r, color, depth, WIDTH, HEIGHT, frame == 7 ? 1.0 : 0.0, settings) |> sdl_try
                    return native_gpu_submit(command)
                } |> sdl_try
                let bytes <- read_image(device, color, WIDTH, HEIGHT, "shadow-scene-{frame}") |> sdl_try
                var changed = 0; var covered = 0
                for (i in 0 .. int(WIDTH * HEIGHT)) {
                    let p = i * 4
                    if (bytes[p] != bytes[0] || bytes[p + 1] != bytes[1] || bytes[p + 2] != bytes[2]) { covered++ }
                    if (frame > 0) {
                        if (abs(int(bytes[p]) - int(reference[p])) > 2 || abs(int(bytes[p + 1]) - int(reference[p + 1])) > 2 || abs(int(bytes[p + 2]) - int(reference[p + 2])) > 2) { changed++ }
                        if (frame == 1) {
                            for (c in 0 .. 3) { verify(int(bytes[p + c]) + 2 >= int(reference[p + c]), "Removing shadows darkens the scene") }
                        }
                    }
                }
                print("shadow scene {frame}: {covered} visible, {changed} changed, hash={image_hash(bytes)}.\n")
                verify(covered > 10000, "Empty scene")
                if (frame == 1 || frame >= 4) { verify(changed > 500, "Missing scene feature") }
                if (frame == 2 || frame == 3) { verify(changed < 100, "Shadow algorithms disagree") }
                if (frame == 0) { reference <- clone(bytes) }
            }
            return sdl_ok()
        }
    }
}
[export]
def main(unused : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use
        return check_scene(device)
    }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }
    return 0
}
