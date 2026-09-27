options gen2
module bgfx_cubes_checks shared public
require ../examples/gpu/cubes_app.das as demo
require bgfx_capture

def check(device : SDL_GPUDevice?; bump : bool) : SdlStatus {
    return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, bump) $(var resources) {
        return sdl_scope() {
            var color : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(640u, 480u,
                SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
            var depth : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(640u, 480u,
                SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_use
            var reference = 0u
            for (frame in 0 .. 4) {
                let time = frame == 3 ? 2.0 : 0.6
                sdl_scope() {
                    var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
                    demo::draw(device, command, resources, color, depth, 640u, 480u, time, bump, bump ? 3 : 11, frame != 1, frame != 2) |> sdl_try
                    return native_gpu_submit(command)
                } |> sdl_try
                let name = bump ? "bump" : "instancing"
                let bytes <- read_image(device, color, 640u, 480u, "{name}-{frame}") |> sdl_try
                let hash = image_hash(bytes)
                var covered = 0
                for (i in 0 .. 640 * 480) { if (int(bytes[i * 4]) != 48 || int(bytes[i * 4 + 1]) != 48 || int(bytes[i * 4 + 2]) != 48) { covered++ } }
                if (covered < 10000 || covered > 640 * 480 * 9 / 10) { return err(SdlError(operation = name, message = "Unexpected object coverage"), type<SdlUnit>) }
                if (frame == 0) { reference = hash }
                if (frame == 1 && hash != reference) { return err(SdlError(operation = name, message = "Instanced and individual draws differ"), type<SdlUnit>) }
                if (bump && frame == 2 && hash == reference) { return err(SdlError(operation = name, message = "Normal mapping has no effect"), type<SdlUnit>) }
                if (frame == 3 && hash == reference) { return err(SdlError(operation = name, message = "Animation has no effect"), type<SdlUnit>) }
                print("{name}: frame {frame}, {covered} pixels, hash={hash}.\n")
            }
            return sdl_ok()
        }
    }
}

def run(bump : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(example_shader_formats(), true, "") |> sdl_use
        return check(device, bump)
    }
    if (is_err(result)) { let error = unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1 }
    return 0
}

