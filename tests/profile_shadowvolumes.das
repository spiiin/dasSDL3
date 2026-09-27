options gen2
// Diagnostic copy of shadowvolumes_scene::draw: coarse CPU timers only.
// Keep this fixture aligned with that implementation; not an alternative renderer.
require ../examples/gpu/shadowvolumes_scene.das
require ../examples/gpu/shaders/stencil_scene_shaders.das as rich
require dassdl3/sdl3_window_boost
require daslib/defer
struct Profile {
    prepare, ambient, generate, upload, lighting, flares, bytes, transform, classify, emit : uint64
}
def reference_triangle(var out : array<float>; a, b, c : float3) {
    for (p in fixed_array(a, b, c)) {
        for (v in fixed_array(p.x, p.y, p.z, 0.0, 1.0, 0.0, 0.0, 0.0)) { push(out, v) }
    }
}

// Diagnostic alternative: identical float stream, one resize per triangle.
def measured_triangle(var out : array<float>; bulk : bool; a, b, c : float3) {
    if (!bulk) { reference_triangle(out, a, b, c); return }
    var n = length(out)
    resize(out, n + 24)
    for (v in fixed_array(a, b, c)) {
        out[n] = v.x; out[n + 1] = v.y; out[n + 2] = v.z
        out[n + 3] = 0.0; out[n + 4] = 1.0; out[n + 5] = 0.0; out[n + 6] = 0.0; out[n + 7] = 0.0
        n += 8
    }
}
def measured_append(var out : array<float>; mesh : ClosedMesh; model : float4x4; light : float3; silhouette : bool; distance : float; var profile : Profile; cleanup, bulk : bool) {
    var tick = SDL_GetPerformanceCounter()
    var points, far_points : array<float3>
    var lit : array<bool>
    for (i in 0 .. length(mesh.geometry.vertices) / 8) {
        let world = model * float4(position_at(mesh.geometry, uint(i)), 1.0)
        let p = world.xyz / world.w
        push(points, p); push(far_points, p + normalize(p - light) * distance)
    }
    profile.transform += SDL_GetPerformanceCounter() - tick
    tick = SDL_GetPerformanceCounter()
    for (i in 0 .. length(mesh.geometry.indices) / 3) {
        let a = points[mesh.geometry.indices[i * 3]]; let b = points[mesh.geometry.indices[i * 3 + 1]]; let c = points[mesh.geometry.indices[i * 3 + 2]]
        push(lit, dot(cross(b - a, c - a), light - a) > 0.0)
    }
    profile.classify += SDL_GetPerformanceCounter() - tick
    tick = SDL_GetPerformanceCounter()
    for (i in 0 .. length(lit)) {
        if (!lit[i]) { continue }
        let a = mesh.geometry.indices[i * 3]; let b = mesh.geometry.indices[i * 3 + 1]; let c = mesh.geometry.indices[i * 3 + 2]
        measured_triangle(out, bulk, points[a], points[b], points[c])
        measured_triangle(out, bulk, far_points[c], far_points[b], far_points[a])
        for (e in 0 .. 3) {
            if (silhouette && lit[mesh.neighbours[i * 3 + e]]) { continue }
            let u = mesh.geometry.indices[i * 3 + e]; let v = mesh.geometry.indices[i * 3 + (e + 1) % 3]
            measured_triangle(out, bulk, points[v], points[u], far_points[u])
            measured_triangle(out, bulk, points[v], far_points[u], far_points[v])
        }
    }
    profile.emit += SDL_GetPerformanceCounter() - tick
    if (cleanup) { delete points; delete far_points; delete lit }
}

struct VolumeScratch {
    points, far_points : array<float3>
    lit : array<bool>
}
def reused_append(var out : array<float>; mesh : ClosedMesh; model : float4x4; light : float3; silhouette : bool; distance : float; var profile : Profile; var scratch : VolumeScratch) {
    var tick = SDL_GetPerformanceCounter()
    resize(scratch.points, 0); resize(scratch.far_points, 0); resize(scratch.lit, 0)
    for (i in 0 .. length(mesh.geometry.vertices) / 8) {
        let world = model * float4(position_at(mesh.geometry, uint(i)), 1.0)
        let p = world.xyz / world.w
        push(scratch.points, p); push(scratch.far_points, p + normalize(p - light) * distance)
    }
    profile.transform += SDL_GetPerformanceCounter() - tick
    tick = SDL_GetPerformanceCounter()
    for (i in 0 .. length(mesh.geometry.indices) / 3) {
        let a = scratch.points[mesh.geometry.indices[i * 3]]; let b = scratch.points[mesh.geometry.indices[i * 3 + 1]]; let c = scratch.points[mesh.geometry.indices[i * 3 + 2]]
        push(scratch.lit, dot(cross(b - a, c - a), light - a) > 0.0)
    }
    profile.classify += SDL_GetPerformanceCounter() - tick
    tick = SDL_GetPerformanceCounter()
    for (i in 0 .. length(scratch.lit)) {
        if (!scratch.lit[i]) { continue }
        let a = mesh.geometry.indices[i * 3]; let b = mesh.geometry.indices[i * 3 + 1]; let c = mesh.geometry.indices[i * 3 + 2]
        measured_triangle(out, true, scratch.points[a], scratch.points[b], scratch.points[c])
        measured_triangle(out, true, scratch.far_points[c], scratch.far_points[b], scratch.far_points[a])
        for (e in 0 .. 3) {
            if (silhouette && scratch.lit[mesh.neighbours[i * 3 + e]]) { continue }
            let u = mesh.geometry.indices[i * 3 + e]; let v = mesh.geometry.indices[i * 3 + (e + 1) % 3]
            measured_triangle(out, true, scratch.points[v], scratch.points[u], scratch.far_points[u])
            measured_triangle(out, true, scratch.points[v], scratch.far_points[u], scratch.far_points[v])
        }
    }
    profile.emit += SDL_GetPerformanceCounter() - tick

}

def profiled_draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var color, depth : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings; var p : Profile; var cache : array<array<float>>; cached, cleanup, bulk, reuse, production : bool; var scratch : VolumeScratch) : SdlStatus {
    var tick = SDL_GetPerformanceCounter()
    let eye = settings.inside ? float3(0.0, 8.0, -12.0) : float3(3.0, 20.0, -58.0)
    let at = settings.inside ? float3(0.0, 12.0, 0.0) : float3(0.0, 5.0, 0.0)
    var projection : float4x4
    let q = 500.0 / 499.9
    projection[0] = float4(1.7320508 * float(height) / float(width), 0.0, 0.0, 0.0)
    projection[1] = float4(0.0, 1.7320508, 0.0, 0.0); projection[2] = float4(0.0, 0.0, q, 1.0); projection[3] = float4(0.0, 0.0, -0.1 * q, 0.0)
    let vp = projection * look_at_lh(eye, at, float3(0.0, 1.0, 0.0))
    var objects <- instances(time, settings)
    let light = scene_lights(time, eye, settings)
    var targets <- array(SDL_GPUColorTargetInfo(texture = color, load_op = SDL_GPULoadOp.LOADOP_CLEAR, store_op = SDL_GPUStoreOp.STOREOP_STORE, clear_color = SDL_FColor(a = 1.0)))
    var ds = stencil_attachment(depth, true)
    p.prepare += SDL_GetPerformanceCounter() - tick
    tick = SDL_GetPerformanceCounter()
    with_native_gpu_render_pass(command, targets, ds) $(var pass_ : SDL_GPURenderPass?&) {
        return draw_scene(command, pass_, r, r.ambient, objects, vp, light, settings)
    } |> sdl_try
    p.ambient += SDL_GetPerformanceCounter() - tick
    targets[0].load_op = SDL_GPULoadOp.LOADOP_LOAD
    ds = stencil_attachment(depth, false); ds.stencil_load_op = SDL_GPULoadOp.LOADOP_CLEAR
    for (i in 0 .. settings.lights) {
        tick = SDL_GetPerformanceCounter()
        var vertices : array<float>
        if (settings.shadows || settings.debug) {
            if (reuse) {
                resize(cache[i], 0)
                for (obj in objects) { if (production) { append_volume_reused(cache[i], r.meshes[obj.mesh], obj.model, light.positions[i].xyz, settings.silhouette, 180.0, r.volume_points, r.volume_far_points, r.volume_lit) } else { reused_append(cache[i], r.meshes[obj.mesh], obj.model, light.positions[i].xyz, settings.silhouette, 180.0, p, scratch) } }
            }
            if (!reuse && (!cached || length(cache[i]) == 0)) {
                for (obj in objects) { measured_append(vertices, r.meshes[obj.mesh], obj.model, light.positions[i].xyz, settings.silhouette, 180.0, p, cleanup, bulk) }
                if (cached) { cache[i] <- vertices }
            }
            p.generate += SDL_GetPerformanceCounter() - tick
            tick = SDL_GetPerformanceCounter()
            if (cached || reuse) {
                upload_volume(device, command, r, cache[i]) |> sdl_try
                p.bytes += uint64(length(cache[i])) * 4ul
            } else {
                upload_volume(device, command, r, vertices) |> sdl_try
                p.bytes += uint64(length(vertices)) * 4ul
            }
            p.upload += SDL_GetPerformanceCounter() - tick
        }
        tick = SDL_GetPerformanceCounter()
        with_native_gpu_render_pass(command, targets, ds) $(var pass_ : SDL_GPURenderPass?&) {
            SDL_SetGPUStencilReference(pass_, 0u)
            if (settings.shadows) { draw_volume(command, pass_, r, settings.zfail ? r.zfail : r.zpass, vp, uint(((cached || reuse) ? length(cache[i]) : length(vertices)) / 8)) |> sdl_try }
            var single = light; single.controls = float4(0.0, 1.0, float(i), 1.0)
            draw_scene(command, pass_, r, r.lit, objects, vp, single, settings) |> sdl_try
            if (settings.debug) { draw_volume(command, pass_, r, r.debug, vp, uint(((cached || reuse) ? length(cache[i]) : length(vertices)) / 8)) |> sdl_try }
            return sdl_ok()
        } |> sdl_try
        p.lighting += SDL_GetPerformanceCounter() - tick
        if (cleanup) { delete vertices }
    }
    ds.stencil_load_op = SDL_GPULoadOp.LOADOP_LOAD
    tick = SDL_GetPerformanceCounter()
    with_native_gpu_render_pass(command, targets, ds) $(var pass_) {
        let forward = normalize(at - eye); let right = normalize(cross(float3(0.0, 1.0, 0.0), forward)); let up = cross(forward, right)
        for (i in 0 .. settings.lights) {
            var billboard = identity_matrix(); billboard[0] = float4(right, 0.0); billboard[1] = float4(forward, 0.0); billboard[2] = float4(up, 0.0); billboard[3] = float4(light.positions[i].xyz, 1.0)
            var flare = light; flare.material.y = 1.0; flare.color = light.colors[i]
            rich_object(command, pass_, r.flare, r.quad, billboard, vp, flare, r.flare_texture, r.sampler) |> sdl_try
        }
        return sdl_ok()
    } |> sdl_try
    p.flares += SDL_GetPerformanceCounter() - tick
    if (cleanup) { delete objects; delete targets }
    return sdl_ok()
}


def verify_emitters(var r : Resources) : SdlStatus {
    var scratch : VolumeScratch
    for (time in fixed_array(0.0, 1.5)) {
        var inscope objects <- instances(time, Settings(lights = 4))
        let light = scene_lights(time, float3(3.0, 20.0, -58.0), Settings(lights = 4))
        for (i in 0 .. 4) {
            var inscope expected, actual, reused : array<float>
            var p : Profile
            for (obj in objects) {
                append_volume(expected, r.meshes[obj.mesh], obj.model, light.positions[i].xyz, true, 180.0)
                measured_append(actual, r.meshes[obj.mesh], obj.model, light.positions[i].xyz, true, 180.0, p, true, true)
                reused_append(reused, r.meshes[obj.mesh], obj.model, light.positions[i].xyz, true, 180.0, p, scratch)
            }
            if (length(expected) != length(actual) || length(expected) != length(reused)) {
                return err(SdlError(operation = "profile oracle", message = "Vertex count mismatch"), type<SdlUnit>)
            }
            for (k in 0 .. length(expected)) {
                if (expected[k] != actual[k] || expected[k] != reused[k]) {
                    return err(SdlError(operation = "profile oracle", message = "Vertex stream mismatch"), type<SdlUnit>)
                }
            }
        }
    }
    print("PROFILE_ORACLE original/bulk/reuse identical: two phases, four lights\n")
    return sdl_ok()
}

def profile_case(device : SDL_GPUDevice?; window : SDL_Window?; mode : int) : SdlStatus {
    let small = mode == 1
    sdl_status(SDL_SetWindowSize(window, small ? 640 : 1280, small ? 360 : 720), "resize benchmark") |> sdl_try
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var depth : SDL_GPUTexture?
        var size = uint2(0u)
        defer() { if (depth != null) { SDL_ReleaseGPUTexture(device, depth) } }
        var settings = Settings(lights = 4, shadows = mode != 2)
        var cache : array<array<float>>
        resize(cache, 4)
        var scratch : VolumeScratch
        var p : Profile
        var started, idle_ticks, draw_ticks = 0ul
        var rendered = 0
        var heap_start = 0ul
        let names = fixed_array("baseline", "half_resolution", "no_shadows", "frozen_rebuild", "frozen_cached", "wait_idle", "cleanup", "bulk_cleanup", "reuse", "production")
        for (frame in 0 .. 720) {
            if (frame == 120) { p = Profile(); idle_ticks = 0ul; draw_ticks = 0ul; started = SDL_GetPerformanceCounter(); heap_start = uint64(heap_bytes_allocated()) }
            SDL_PumpEvents()
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var color : SDL_GPUTexture?; width, height : uint) {
                if (width != (small ? 640u : 1280u) || height != (small ? 360u : 720u)) { return err(SdlError(operation = "profile", message = "Unexpected drawable size"), type<SdlUnit>) }
                replace_stencil(device, depth, size, width, height, r.depth_format) |> sdl_try
                let tick = SDL_GetPerformanceCounter()
                profiled_draw(device, command, r, color, depth, width, height, (mode == 3 || mode == 4) ? 0.0 : float(frame % 600) / 60.0, settings, p, cache, mode == 4, mode >= 6, mode == 7, mode == 8 || mode == 9, mode == 9, scratch) |> sdl_try
                draw_ticks += SDL_GetPerformanceCounter() - tick
                rendered++
                return sdl_ok()
            } |> sdl_try
            if (rendered != frame + 1) { return err(SdlError(operation = "profile", message = "Swapchain skipped a frame"), type<SdlUnit>) }
            if (mode == 5) {
                let tick = SDL_GetPerformanceCounter()
                sdl_status(SDL_WaitForGPUIdle(device), "wait idle diagnostic") |> sdl_try
                idle_ticks += SDL_GetPerformanceCounter() - tick
            }
        }
        let elapsed = SDL_GetPerformanceCounter() - started
        let scale = 1000.0lf / double(SDL_GetPerformanceFrequency()) / 600.0lf
        print("PROFILE {names[mode]} fps={1000.0lf/(double(elapsed)*scale)} frame_ms={double(elapsed)*scale} prepare={double(p.prepare)*scale} ambient={double(p.ambient)*scale} generate={double(p.generate)*scale} upload={double(p.upload)*scale} lighting={double(p.lighting)*scale} flares={double(p.flares)*scale} draw={double(draw_ticks)*scale} outside_draw={double(elapsed-draw_ticks-idle_ticks)*scale} idle={double(idle_ticks)*scale} bytes={double(p.bytes)/600.0lf} transform={double(p.transform)*scale} classify={double(p.classify)*scale} emit={double(p.emit)*scale} heap_delta_mb={(double(heap_bytes_allocated())-double(heap_start))/1048576.0lf}\n")
        sdl_status(SDL_WaitForGPUIdle(device), "finish profile case") |> sdl_try
        if (mode == 8) { verify_emitters(r) |> sdl_try }
        return sdl_ok()
    }
}
[export]
def main(unused : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window(WindowOptions(title = "Shadow volumes CPU profile", size = int2(1280, 720))) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(), false, "vulkan") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device, window), "claim") |> sdl_try
        {
            defer() { SDL_ReleaseWindowFromGPUDevice(device, window) }
            sdl_status(SDL_SetGPUSwapchainParameters(device, window, SDL_GPUSwapchainComposition.SWAPCHAINCOMPOSITION_SDR, SDL_GPUPresentMode.PRESENTMODE_IMMEDIATE), "immediate") |> sdl_try
            var choice : string
            SDL_GetHintOptionalCopy("DASSDL3_PROFILE", choice)
            let names = fixed_array("baseline", "half_resolution", "no_shadows", "frozen_rebuild", "frozen_cached", "wait_idle", "cleanup", "bulk_cleanup", "reuse", "production")
            var found = false
            for (mode in 0 .. 10) {
                if (choice == names[mode]) { profile_case(device, window, mode) |> sdl_try; found = true }
            }
            if (!found) { return err(SdlError(operation = "profile", message = "Set DASSDL3_PROFILE to a named profile case"), type<SdlUnit>) }
            return sdl_ok()
        }
    }
    if (is_err(result)) { let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1 }
    return 0
}

