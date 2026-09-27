options gen2
require ../examples/gpu/lod_app.das as demo
require ../examples/gpu/bgfx_support.das public
require bgfx_capture
require dassdl3/sdl3_init_boost
require daslib/defer
require math
let WIDTH = 640u
let HEIGHT = 480u
def check(device : SDL_GPUDevice?) : SdlStatus {
    if (demo::choose_lod(2.0) != 0 || demo::choose_lod(3.0) != 1 || demo::choose_lod(6.0) != 2) {
        return err(SdlError(operation = "LOD selection", message = "Wrong thresholds"), type<SdlUnit>)
    }
    var transition = demo::LodState()
    for (i in 0 .. 32) {
        demo::update_lod(transition, 6.0)
    }
    if (transition.current != 0 || transition.target != 2 || transition.frame != 32) {
        return err(SdlError(operation = "LOD transition", message = "Wrong transition duration"), type<SdlUnit>)
    }
    demo::update_lod(transition, 6.0)
    if (transition.current != 2 || transition.frame != 0) {
        return err(SdlError(operation = "LOD transition", message = "Transition did not finish"), type<SdlUnit>)
    }
    return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
        return sdl_scope() {
            var color : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
            var depth : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_use
            var reference : array<uint8>
            var last_level : array<uint8>
            for (frame in 0 .. 4) {
                let state = demo::LodState(current = frame == 3 ? 0 : frame, target = frame == 3 ? 2 : frame, frame = 16)
                sdl_scope() {
                    var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
                    demo::draw(device, command, r, color, depth, WIDTH, HEIGHT, 3.5, state) |> sdl_try
                    return native_gpu_submit(command)
                }  |> sdl_try
                let bytes <- read_image(device, color, WIDTH, HEIGHT, "lod-{frame}") |> sdl_try
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
                if (frame > 0 && changed < 100) {
                    return err(SdlError(operation = "image variation", message = "Expected changed pixels"), type<SdlUnit>)
                }
                print("lod frame {frame}: {foreground} foreground, {changed} changed, hash={image_hash(bytes)}.\n")
                if (frame == 2) {
                    last_level <- clone(bytes)
                }
                if (frame == 3) {
                    var wrong = 0
                    for (i in 0 .. int(WIDTH * HEIGHT)) {
                        var first = true
                        var last = true
                        for (c in 0 .. 4) {
                            let at = i * 4 + c
                            first = first && abs(int(bytes[at]) - int(reference[at])) <= 1
                            last = last && abs(int(bytes[at]) - int(last_level[at])) <= 1
                        }
                        if (!first && !last) {
                            wrong++
                        }
                    }
                    if (wrong > 10) {
                        return err(SdlError(operation = "LOD stipple", message = "Transition is not a complementary selection: {wrong} pixels"), type<SdlUnit>)
                    }
                }
                if (frame == 0) {
                    reference <- clone(bytes)
                }
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
        return check(device)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
