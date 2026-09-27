options gen2
module shader_dsl_texture_pixels shared public
require ../examples/gpu_dsl/texture_support.das
require dassdl3/sdl3_scope
require math

def public check_texture_pixels(device : SDL_GPUDevice?; var vertex, fragment : SDL_GPUShader?) : SdlStatus {
    var info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vertex, fragment_shader = fragment,
        primitive_type = SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
    info.rasterizer_state.enable_depth_clip = true
    var buffers : array<SDL_GPUVertexBufferDescription>
    var attributes : array<SDL_GPUVertexAttribute>
    var colors <- array(SDL_GPUColorTargetDescription(format = SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
    return sdl_scope() {
        let pipeline : SDL_GPUGraphicsPipeline? = with_native_gpu_graphics_pipeline(device, info, buffers, attributes, colors) |> sdl_use
        var sampled : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(2u, 2u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_use
        var sampler : SDL_GPUSampler? = with_native_gpu_sampler(device, checker_sampler()) |> sdl_use
        var target : SDL_GPUTexture? = with_native_gpu_texture(device, gpu_texture(8u, 8u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
        var transfer : SDL_GPUTransferBuffer? = with_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD, size = 256u)) |> sdl_use
        upload_checker(device, sampled) |> sdl_try
        for (round in 0 .. 2) {
            with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
                var tint <- round == 0 ? array<float>(1.0, 1.0, 1.0, 1.0) : array<float>(0.5, 1.0, 0.25, 1.0)
                draw_checker(command, pipeline, sampled, target, sampler, tint) |> sdl_try
                with_native_gpu_copy_pass(command) $(var copy_pass : SDL_GPUCopyPass?&) {
                    let source = SDL_GPUTextureRegion(texture = target, w = 8u, h = 8u, d = 1u)
                    let destination = SDL_GPUTextureTransferInfo(transfer_buffer = transfer, pixels_per_row = 8u, rows_per_layer = 8u)
                    SDL_DownloadFromGPUTextureRef(copy_pass, source, destination)
                    return sdl_ok()
                } |> sdl_try
                return native_gpu_submit(command)
            } |> sdl_try
            sdl_status(SDL_WaitForGPUIdle(device), "SDL_WaitForGPUIdle") |> sdl_try
            var pixels : array<uint8>; resize(pixels, 256)
            sdl_status(SDL_ReadGPUTransferBufferBytes(device, transfer, 256u, 0u, pixels), "SDL_ReadGPUTransferBufferBytes") |> sdl_try
            for (y in 0 .. 8) { for (x in 0 .. 8) {
                let at = (y * 8 + x) * 4
                let red = ((y < 4 && x < 4) || (y >= 4 && x >= 4)) ? (round == 0 ? 255 : 128) : 0
                let green = x >= 4 ? 255 : 0
                let blue = y >= 4 ? (round == 0 ? 255 : 64) : 0
                verify(abs(int(pixels[at]) - red) <= 1 && abs(int(pixels[at + 1]) - green) <= 1 && abs(int(pixels[at + 2]) - blue) <= 1 && pixels[at + 3] == uint8(255))
            } }
        }
        return sdl_ok()
    }
}
