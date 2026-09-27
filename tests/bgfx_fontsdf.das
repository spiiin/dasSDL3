options gen2
require ../examples/gpu/fontsdf_app.das as demo
require ../examples/gpu/bgfx_support.das public
require bgfx_capture
require ../examples/gpu/shaders/fontsdf_shaders.das as shaders
require dassdl3/sdl3_shader_uniforms
require dassdl3/sdl3_init_boost
require daslib/defer
require math
let WIDTH = 640u
let HEIGHT = 480u
def check(device : SDL_GPUDevice?) : SdlStatus {
    return demo::with_resources(device, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(var r) {
        return sdl_scope() {
            var color : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
            var reference : array<uint8>
            var previous_coverage = 0
            for (frame in 0 .. 4) {
                let controls = demo::TextControls(scale = frame == 3 ? 1.3 : 0.9, angle = frame == 3 ? 0.15 : 0.0, outline = frame > 0, shadow = frame > 1)
                sdl_scope() {
                    var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
                    demo::draw(device, command, r, color, WIDTH, HEIGHT, controls) |> sdl_try
                    return native_gpu_submit(command)
                }  |> sdl_try
                let bytes <- read_image(device, color, WIDTH, HEIGHT, "fontsdf-{frame}") |> sdl_try
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
                if (frame < 3) {
                    // Default unrotated layout must remain inside horizontal margins,
                    // and preserve an empty strip above the first line (Y orientation).
                    for (y in 0 .. int(HEIGHT)) {
                        for (x in 0 .. int(WIDTH)) {
                            if (x >= 20 && x < int(WIDTH) - 20 && y >= 40) { continue }
                            let at = (y * int(WIDTH) + x) * 4
                            for (c in 0 .. 3) {
                                if (bytes[at + c] != bytes[c]) {
                                    return err(SdlError(operation = "SDF layout", message = "Text escaped the layout margins"), type<SdlUnit>)
                                }
                            }
                        }
                    }
                    if (foreground <= previous_coverage) {
                        return err(SdlError(operation = "SDF effects", message = "Outline/shadow did not extend coverage"), type<SdlUnit>)
                    }
                    previous_coverage = foreground
                }
                if (foreground < 100) {
                    return err(SdlError(operation = "readback", message = "Empty image"), type<SdlUnit>)
                }
                if (frame > 0 && changed < 100) {
                    return err(SdlError(operation = "image variation", message = "Expected changed pixels"), type<SdlUnit>)
                }
                print("fontsdf frame {frame}: {foreground} foreground, {changed} changed, hash={image_hash(bytes)}.\n")
                if (frame == 0) {
                    reference <- clone(bytes)
                }
            }
            return check_atlas_isolation(device, r, color)
        }
    }
}
// The current glyph is completely empty, but neighbouring atlas texels are
// opaque. Neither bilinear filtering nor an offset shadow may reveal neighbours.
def check_atlas_isolation(device : SDL_GPUDevice?; var r : demo::TextResources; var color : SDL_GPUTexture?) : SdlStatus {
    return sdl_scope() {
        var atlas : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(16u, 16u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_use
        var transfer : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = 1024u)) |> sdl_use
        var pixels : array<uint8>
        for (y in 0 .. 16) { for (x in 0 .. 16) {
            push(pixels, 255u8); push(pixels, 255u8); push(pixels, 255u8)
            push(pixels, uint8(x >= 4 && x < 12 && y >= 4 && y < 12 ? 0 : 255))
        } }
        sdl_status(SDL_WriteGPUTransferBufferBytes(device, transfer, 1024u, 0u, pixels, false), "atlas fixture") |> sdl_try
        var vertices : array<float>
        for (corner in 0 .. 4) {
            let right = corner == 1 || corner == 2
            let bottom = corner >= 2
            for (v in fixed_array(right ? 100.0 : 0.0, bottom ? -100.0 : 0.0,
                right ? 0.75 : 0.25, bottom ? 0.75 : 0.25, 0.25, 0.25, 0.75, 0.75)) { push(vertices, v) }
        }
        var indices : array<uint8>
        for (i in fixed_array(0u8, 1u8, 2u8, 0u8, 2u8, 3u8)) { push(indices, i); push(indices, 0u8); push(indices, 0u8); push(indices, 0u8) }
        upload_bytes(device, r.ib, indices) |> sdl_try
        sdl_scope() {
            var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
            with_native_gpu_copy_pass(command) $(var copy_) {
                SDL_UploadToGPUTextureRef(copy_, SDL_GPUTextureTransferInfo(transfer_buffer = transfer, pixels_per_row = 16u, rows_per_layer = 16u), SDL_GPUTextureRegion(texture = atlas, w = 16u, h = 16u, d = 1u), false)
                return sdl_ok()
            } |> sdl_try
            upload_floats(device, command, r.vb, r.upload, demo::TEXT_CAPACITY, vertices) |> sdl_try
            let transform = shaders::TextTransform(viewport = float4(float(WIDTH), float(HEIGHT), 1.0, 0.0), origin = float4(100.0, 100.0, 0.0, 0.0))
            let style = shaders::TextStyle(effects = float4(0.1, 2.0, 3.0, 3.0), color = float4(1.0), outline = float4(1.0, 0.0, 0.0, 1.0), shadow = float4(0.0, 1.0, 0.0, 1.0))
            push_gpu_dsl_vertex_uniform(command, 0u, transform) |> sdl_try
            push_gpu_dsl_fragment_uniform(command, 0u, style) |> sdl_try
            let targets <- array(SDL_GPUColorTargetInfo(texture = color, load_op = SDL_GPULoadOp.LOADOP_CLEAR, store_op = SDL_GPUStoreOp.STOREOP_STORE, clear_color = SDL_FColor(r = 0.12, g = 0.14, b = 0.18, a = 1.0)))
            with_native_gpu_render_pass(command, targets) $(var pass_) {
                SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
                let buffers <- array(SDL_GPUBufferBinding(buffer = r.vb))
                let textures <- array(SDL_GPUTextureSamplerBinding(texture = atlas, sampler = r.sampler))
                sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, buffers), "fixture vertices") |> sdl_try
                SDL_BindGPUIndexBufferRef(pass_, SDL_GPUBufferBinding(buffer = r.ib), SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
                sdl_status(SDL_BindGPUFragmentSamplersArray(pass_, 0u, textures), "fixture atlas") |> sdl_try
                SDL_DrawGPUIndexedPrimitives(pass_, 6u, 1u, 0u, 0, 0u)
                return sdl_ok()
            } |> sdl_try
            return native_gpu_submit(command)
        } |> sdl_try
        let bytes <- read_image(device, color, WIDTH, HEIGHT, "fontsdf-isolation") |> sdl_try
        for (i in 0 .. int(WIDTH * HEIGHT)) { for (c in 0 .. 3) {
            if (bytes[i * 4 + c] != bytes[c]) { return err(SdlError(operation = "SDF atlas isolation", message = "Neighbour glyph leaked into an empty glyph"), type<SdlUnit>) }
        } }
        print("SDF atlas isolation: no neighbour bleed.\n")
        return sdl_ok()
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
