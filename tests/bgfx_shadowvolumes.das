options gen2
require ../examples/gpu/shadowvolumes_app.das as demo
require ../examples/gpu/bgfx_support.das public
require bgfx_capture
require ../examples/gpu/port_geometry.das
require ../examples/gpu/shadowvolumes_geometry.das
require dassdl3/sdl3_init_boost
require daslib/defer
require math
let WIDTH = 640u
let HEIGHT = 480u
def check(device : SDL_GPUDevice?) : SdlStatus {
    let cube <- cube_geometry()
    let volume <- shadow_volume(cube, model_matrix(float3(0.0, 1.05, 0.0), float3(0.8)), float3(-3.0, 6.0, -2.0), true)
    // Welding by position must leave exactly one reverse neighbour per edge.
    for (i in 0 .. length(volume.indices) / 3) {
        for (e in 0 .. 3) {
            let a = position_at(volume, volume.indices[i * 3 + e])
            let b = position_at(volume, volume.indices[i * 3 + (e + 1) % 3])
            var neighbours = 0
            for (j in 0 .. length(volume.indices) / 3) {
                if (i == j) {
                    continue
                }
                for (k in 0 .. 3) {
                    if (position_at(volume, volume.indices[j * 3 + k]) == b && position_at(volume, volume.indices[j * 3 + (k + 1) % 3]) == a) {
                        neighbours++
                    }
                }
            }
            if (neighbours != 1) {
                return err(SdlError(operation = "closed volume", message = "Open or nonmanifold edge"), type<SdlUnit>)
            }
        }
    }
    return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
        return sdl_scope() {
            var color : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
            var depth : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT, r.depth_format, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_use
            var reference : array<uint8>
            var inside_reference : array<uint8>
            for (frame in 0 .. 6) {
                sdl_scope() {
                    var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
                    demo::draw(device, command, r, color, depth, WIDTH, HEIGHT, 0.0, frame != 1, frame != 2, frame >= 4, false, frame != 3 && frame != 5) |> sdl_try
                    return native_gpu_submit(command)
                }  |> sdl_try
                let bytes <- read_image(device, color, WIDTH, HEIGHT, "shadowvolumes-{frame}") |> sdl_try
                var changed = 0
                var foreground = 0
                for (i in 0 .. int(WIDTH * HEIGHT)) {
                    let p = i * 4
                    if (bytes[p] != bytes[0] || bytes[p + 1] != bytes[1] || bytes[p + 2] != bytes[2]) {
                        foreground++
                    }
                    if (frame > 0 && (bytes[p] != reference[p] || bytes[p + 1] != reference[p + 1] || bytes[p + 2] != reference[p + 2])) {
                        changed++
                    }
                }
                if (foreground < 100) {
                    return err(SdlError(operation = "readback", message = "Empty image"), type<SdlUnit>)
                }
                if ((frame == 1 || frame == 2) && changed > 10) {
                    return err(SdlError(operation = "shadow algorithms", message = "Masks disagree: {changed}"), type<SdlUnit>)
                }
                if (frame == 3 && changed < 100) {
                    return err(SdlError(operation = "shadow mask", message = "No shadow"), type<SdlUnit>)
                }
                print("shadowvolumes frame {frame}: {foreground} foreground, {changed} changed, hash={image_hash(bytes)}.\n")
                if (frame == 3) {
                    check_shadow(reference, bytes, false) |> sdl_try
                }
                if (frame == 4) {
                    inside_reference <- clone(bytes)
                }
                if (frame == 5) {
                    check_shadow(inside_reference, bytes, true) |> sdl_try
                }
                if (frame == 0) {
                    reference <- clone(bytes)
                }
            }
            return sdl_ok()
        }
    }
}
// Independent segment/AABB visibility oracle; no volume triangles or stencil state.
def intersects(a, b : float3; padding : float) : bool {
    let lo = float3(-0.8 - padding, 0.25 - padding, -0.8 - padding)
    let hi = float3(0.8 + padding, 1.85 + padding, 0.8 + padding)
    var near = 0.001
    var far = 0.999
    for (axis in 0 .. 3) {
        let direction = b[axis] - a[axis]
        if (abs(direction) < 0.00001) {
            if (a[axis] < lo[axis] || a[axis] > hi[axis]) {
                return false
            }
        } else {
            let t0 = (lo[axis] - a[axis]) / direction
            let t1 = (hi[axis] - a[axis]) / direction
            near = max(near, min(t0, t1))
            far = min(far, max(t0, t1))
        }
    }
    return near < far
}
def check_shadow(shadow, lit : array<uint8>; inside : bool) : SdlStatus {
    let eye = inside ? float3(1.2, 0.25, 0.8) : float3(5.0, 4.5, -7.0)
    let vp = camera_matrix(WIDTH, HEIGHT, eye, float3(0.0, 0.6, 0.0))
    let light = float3(-3.0, 6.0, -2.0)
    if (!inside) {
        // Convex occluder: the lit top/front surfaces must not shadow themselves.
        for (point in fixed_array(float3(0.2, 1.85, -0.2), float3(0.0, 1.0, -0.8))) {
            let q = vp * float4(point, 1.0)
            let x = int((q.x / q.w * 0.5 + 0.5) * float(WIDTH))
            let y = int((0.5 - q.y / q.w * 0.5) * float(HEIGHT))
            let at = (y * int(WIDTH) + x) * 4
            for (c in 0 .. 3) {
                if (abs(int(lit[at + c]) - int(shadow[at + c])) > 1) {
                    return err(SdlError(operation = "volume self-shadow", message = "Lit cube face is shadowed"), type<SdlUnit>)
                }
            }
        }
    }
    var checked = 0
    var dark = 0
    var errors = 0
    for (z in -40 .. 41) {
        for (x in -40 .. 41) {
            let p = float3(float(x) * 0.1, 0.0, float(z) * 0.1)
            if (intersects(eye, p, 0.04)) {
                continue
            }
            let expected = intersects(p, light, -0.04)
            if (expected != intersects(p, light, 0.04)) {
                continue
            }
            let clip = vp * float4(p, 1.0)
            if (clip.w <= 0.1) {
                continue
            }
            let uv = float2(clip.x / clip.w * 0.5 + 0.5, 0.5 - clip.y / clip.w * 0.5)
            let px = int(uv.x * float(WIDTH))
            let py = int(uv.y * float(HEIGHT))
            if (px < 3 || py < 3 || px >= int(WIDTH) - 3 || py >= int(HEIGHT) - 3) {
                continue
            }
            let i = (py * int(WIDTH) + px) * 4
            let difference = int(lit[i]) + int(lit[i + 1]) + int(lit[i + 2]) - int(shadow[i]) - int(shadow[i + 1]) - int(shadow[i + 2])
            if (expected) {
                dark++
                if (difference < 30) {
                    errors++
                }
            } else {
                if (abs(difference) > 3) {
                    errors++
                }
            }
            checked++
        }
    }
    print("CPU shadow oracle: {checked} samples, {dark} shadow, {errors} mismatches, inside={inside}.\n")
    if (checked < 100 || dark < 10 || errors > checked / 100) {
        return err(SdlError(operation = "CPU shadow oracle", message = "Unexpected stencil mask"), type<SdlUnit>)
    }
    return sdl_ok()
}
[export]
def main(unused : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use
        return check(device)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
