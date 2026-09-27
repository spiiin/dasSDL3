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
        // Reuse the same work arrays across meshes, phases, lights and both algorithms.
        var cached_vertices : array<float>
        var cached_indices : array<uint8>
        var origins, normals : array<float4>
        var ranges : array<demo::VolumeRange>
        var optimized, compact : array<float>
        var indices : array<uint8>
        var indexed_points : array<float4>
        var indexed_lit : array<bool>
        var points, far_points : array<float4>
        var lit : array<bool>
        for (phase in fixed_array(0.0, 1.5)) {
            let objects <- demo::instances(phase, demo::Settings(lights = 4))
            let light = demo::scene_lights(phase, float3(3.0, 20.0, -58.0), demo::Settings(lights = 4))
            resize(cached_vertices, 0); resize(origins, 0); resize(normals, 0); resize(ranges, length(objects))
            for (j in 0 .. length(objects)) {
                ranges[j] = demo::prepare_volume(cached_vertices, origins, normals, r.meshes[objects[j].mesh], objects[j].model, indexed_points)
            }
            for (silhouette in fixed_array(true, false)) {
                for (i in 0 .. 4) {
                    var inscope expected : array<float>
                    resize(optimized, 0); resize(compact, 0); resize(indices, 0)
                    for (obj in objects) {
                        demo::append_volume_indexed(compact, indices, r.meshes[obj.mesh], obj.model, light.positions[i].xyz, silhouette, indexed_points, indexed_lit)
                        demo::append_volume(expected, r.meshes[obj.mesh], obj.model, light.positions[i].xyz, silhouette, 180.0)
                        demo::append_volume_reused(optimized, r.meshes[obj.mesh], obj.model, light.positions[i].xyz, silhouette, 180.0, points, far_points, lit)
                    }
                    resize(cached_indices, 0)
                    for (j in 0 .. length(objects)) {
                        demo::append_prepared_volume(cached_indices, r.meshes[objects[j].mesh], ranges[j], origins, normals, light.positions[i].xyz, silhouette, indexed_lit)
                    }
                    verify(length(cached_vertices) == length(compact), "Cached vertex count differs")
                    for (k in 0 .. length(compact)) { verify(cached_vertices[k] == compact[k], "Cached vertex differs") }
                    verify(length(cached_indices) == length(indices), "Cached index count differs")
                    for (k in 0 .. length(indices)) { verify(cached_indices[k] == indices[k], "Cached index differs") }
                    verify(length(expected) == length(optimized), "Reused volume count differs")
                    verify(length(indices) / 4 == length(expected) / 8, "Indexed triangle count differs")
                    verify(length(compact) * 4 + length(indices) < length(expected) * 4, "Indexed upload is not smaller")
                    for (k in 0 .. length(indices) / 4) {
                        let index = int(uint(indices[k * 4]) + uint(indices[k * 4 + 1]) * 256u + uint(indices[k * 4 + 2]) * 65536u + uint(indices[k * 4 + 3]) * 16777216u)
                        verify(index >= 0 && index < length(compact) / 4, "Index outside compact vertices")
                        let base = index * 4
                        var point = float4(compact[base], compact[base + 1], compact[base + 2], 1.0)
                        if (compact[base + 3] > 0.5) { point += normalize((point - float4(light.positions[i].xyz, 1.0)).xzyw).xzyw * 180.0 }
                        verify(point.x == expected[k * 8] && point.y == expected[k * 8 + 1] && point.z == expected[k * 8 + 2], "Indexed volume geometry differs")
                    }

                    for (k in 0 .. length(expected)) { if (expected[k] != optimized[k]) { print("Mismatch phase={phase} light={i} silhouette={silhouette} index={k} field={k%8} old={expected[k]} new={optimized[k]}\n") }; verify(expected[k] == optimized[k], "Reused volume stream differs") }
                }
            }
        }
        print("Reused volumes: exact stream parity for both algorithms, two phases, four lights.\n")
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
                if (frame == 4) { settings.lights = 4 }
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
                sdl_scope() {
                    var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
                    demo::draw(device, command, r, color, depth, WIDTH, HEIGHT, frame == 7 ? 1.0 : 0.0, settings, false, false) |> sdl_try
                    return native_gpu_submit(command)
                } |> sdl_try
                let uncached <- read_image(device, color, WIDTH, HEIGHT, "shadow-scene-uncached-{frame}") |> sdl_try
                for (k in 0 .. length(bytes)) { verify(bytes[k] == uncached[k], "Frame cache changes rendered pixels") }
                // Compare the new GPU extrusion against the previous CPU volume renderer.
                sdl_scope() {
                    var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
                    demo::draw(device, command, r, color, depth, WIDTH, HEIGHT, frame == 7 ? 1.0 : 0.0, settings, true) |> sdl_try
                    return native_gpu_submit(command)
                } |> sdl_try
                let cpu_bytes <- read_image(device, color, WIDTH, HEIGHT, "shadow-scene-cpu-{frame}") |> sdl_try
                var gpu_changed = 0
                for (pixel in 0 .. int(WIDTH * HEIGHT)) {
                    let p = pixel * 4
                    if (abs(int(bytes[p]) - int(cpu_bytes[p])) > 2 || abs(int(bytes[p + 1]) - int(cpu_bytes[p + 1])) > 2 || abs(int(bytes[p + 2]) - int(cpu_bytes[p + 2])) > 2) { gpu_changed++ }
                }
                print("GPU extrusion frame {frame}: {gpu_changed} changed pixels against CPU reference.\n")
                verify(gpu_changed < 100, "GPU extrusion changes the image")
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
