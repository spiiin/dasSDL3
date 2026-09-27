options gen2
require ../examples/gpu/stencil_app.das as demo
require ../examples/gpu/bgfx_support.das public
require bgfx_capture
require dassdl3/sdl3_init_boost
require daslib/defer
require math
let WIDTH = 640u
let HEIGHT = 480u
def check(device : SDL_GPUDevice?) : SdlStatus {
    return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
        return sdl_scope() {
            var color : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
            var depth : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT, r.depth_format, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_use
            var reference : array<uint8>
            var reflection_reference : array<uint8>
            for (frame in 0 .. 8) {
                var settings = demo::SceneSettings()
                if (frame == 4) { settings.textures = false }
                if (frame == 5) { settings.specular = false }
                if (frame == 6) { settings.lights = 1 }
                sdl_scope() {
                    var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
                    demo::draw(device, command, r, color, depth, WIDTH, HEIGHT, frame == 7 ? 1.2 : 0.0, frame == 2 || frame == 3, frame != 0 && frame != 2, settings) |> sdl_try
                    return native_gpu_submit(command)
                }  |> sdl_try
                let bytes <- read_image(device, color, WIDTH, HEIGHT, "stencil-{frame}") |> sdl_try
                if (frame >= 4) { reference <- clone(reflection_reference) }
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
                if (frame == 1 && changed < 100) {
                    return err(SdlError(operation = "reflection", message = "No reflected image"), type<SdlUnit>)
                }
                if (frame == 3 && changed < 100) {
                    return err(SdlError(operation = "projection", message = "No shadow"), type<SdlUnit>)
                }
                if (frame >= 4 && changed < 500) {
                    return err(SdlError(operation = "scene features", message = "Texture/specular/light/animation toggle has no visible effect"), type<SdlUnit>)
                }
                if (frame == 1) {
                    // Reflections must remain inside the finite floor's stencil footprint.
                    for (y in 0 .. 200) {
                        for (x in 0 .. int(WIDTH)) {
                            let at = (y * int(WIDTH) + x) * 4
                            for (c in 0 .. 3) { verify(bytes[at + c] == reference[at + c], "Reflection escaped the floor") }
                        }
                    }
                    reflection_reference <- clone(bytes)
                }
                print("stencil frame {frame}: {foreground} foreground, {changed} changed, hash={image_hash(bytes)}.\n")
                if (frame == 3) {
                    for (i in 0 .. int(WIDTH * HEIGHT)) {
                        for (c in 0 .. 3) {
                            if (int(bytes[i * 4 + c]) > int(reference[i * 4 + c]) + 1) {
                                return err(SdlError(operation = "projected shadow", message = "Shadow unexpectedly brightens scene"), type<SdlUnit>)
                            }
                        }
                    }
                }
                if (frame == 0 || frame == 2) {
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
