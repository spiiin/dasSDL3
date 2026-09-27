options gen2
module shader_dsl_uniform_pixels shared public
require dassdl3/sdl3_shader_dsl
require dassdl3/sdl3_scope
require math
require ../examples/gpu_dsl/uniform_shaders.das
require dassdl3/sdl3_shader_uniforms

def public check_uniform_pixels(device : SDL_GPUDevice?; var vertex, fragment : SDL_GPUShader?) : SdlStatus {
    var info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vertex, fragment_shader = fragment,
        primitive_type = SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
    info.rasterizer_state.enable_depth_clip = true
    var buffers : array<SDL_GPUVertexBufferDescription>
    var attributes : array<SDL_GPUVertexAttribute>
    var colors <- array(SDL_GPUColorTargetDescription(format = SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
    return sdl_scope() {
        let pipeline : SDL_GPUGraphicsPipeline? = with_native_gpu_graphics_pipeline(device, info, buffers, attributes, colors) |> sdl_use
        var texture_info = gpu_texture(8u, 8u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)
        var texture : SDL_GPUTexture? = with_native_gpu_texture(device, texture_info) |> sdl_use
        var transfer : SDL_GPUTransferBuffer? = with_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD, size = 256u)) |> sdl_use
        // Two draws prove the reflected UBO is populated per command, not a baked constant.
        for (round in 0 .. 2) {
            with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
                push_gpu_dsl_vertex_uniform(command, 0u, example_vertex_uniforms()) |> sdl_try
                push_gpu_dsl_fragment_uniform(command, 0u, example_uniforms(round == 1)) |> sdl_try
                var targets <- array(SDL_GPUColorTargetInfo(texture = texture, load_op = SDL_GPULoadOp.LOADOP_CLEAR,
                    store_op = SDL_GPUStoreOp.STOREOP_STORE, clear_color = SDL_FColor(a = 1.0)))
                with_native_gpu_render_pass(command, targets) $(var render_pass : SDL_GPURenderPass?&) {
                    SDL_BindGPUGraphicsPipeline(render_pass, pipeline)
                    SDL_DrawGPUPrimitives(render_pass, 3u, 1u, 0u, 0u)
                    return sdl_ok()
                } |> sdl_try
                with_native_gpu_copy_pass(command) $(var copy_pass : SDL_GPUCopyPass?&) {
                    let source = SDL_GPUTextureRegion(texture = texture, w = 8u, h = 8u, d = 1u)
                    let destination = SDL_GPUTextureTransferInfo(transfer_buffer = transfer, pixels_per_row = 8u, rows_per_layer = 8u)
                    SDL_DownloadFromGPUTextureRef(copy_pass, source, destination)
                    return sdl_ok()
                } |> sdl_try
                return native_gpu_submit(command)
            } |> sdl_try
            sdl_status(SDL_WaitForGPUIdle(device), "SDL_WaitForGPUIdle") |> sdl_try
            var pixels : array<uint8>; resize(pixels, 256)
            sdl_status(SDL_ReadGPUTransferBufferBytes(device, transfer, 256u, 0u, pixels), "SDL_ReadGPUTransferBufferBytes") |> sdl_try
            let center = (4 * 8 + 4) * 4
            verify(abs(int(pixels[center]) - (round == 0 ? 64 : 191)) <= 1)
            verify(abs(int(pixels[center + 1]) - 128) <= 1)
            verify(abs(int(pixels[center + 2]) - (round == 0 ? 191 : 64)) <= 1)
            verify(pixels[center + 3] == uint8(255))
            verify(pixels[0] == uint8(0) && pixels[1] == uint8(0) && pixels[2] == uint8(0))
        }
        return sdl_ok()
    }
}
