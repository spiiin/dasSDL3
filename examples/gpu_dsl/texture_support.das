options gen2
module texture_support shared public
require dassdl3/sdl3_shader_dsl public
require dassdl3/sdl3_scope

// Application data, row-major: red/green above blue/white. No image dependency.
def public upload_checker(device : SDL_GPUDevice?; var texture : SDL_GPUTexture?) : SdlStatus {
    var bytes : array<uint8>; resize(bytes, 16)
    let values = fixed_array(255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255, 255, 255, 255, 255)
    for (i in 0 .. 16) {bytes[i] = uint8(values[i])}
    return sdl_scope() {
        var transfer : SDL_GPUTransferBuffer? = with_native_gpu_transfer_buffer(device,
            SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = 16u)) |> sdl_use
        sdl_status(SDL_WriteGPUTransferBufferBytes(device, transfer, 16u, 0u, bytes, false), "SDL_WriteGPUTransferBufferBytes") |> sdl_try
        return with_native_gpu_commands(device) $(var command : SDL_GPUCommandBuffer?&) {
            with_native_gpu_copy_pass(command) $(var copy_pass : SDL_GPUCopyPass?&) {
                let source = SDL_GPUTextureTransferInfo(transfer_buffer = transfer, pixels_per_row = 2u, rows_per_layer = 2u)
                let destination = SDL_GPUTextureRegion(texture = texture, w = 2u, h = 2u, d = 1u)
                SDL_UploadToGPUTextureRef(copy_pass, source, destination, false)
                return sdl_ok()
            } |> sdl_try
            return native_gpu_submit(command)
        }
    }
}

def public checker_sampler() : SDL_GPUSamplerCreateInfo {
    return SDL_GPUSamplerCreateInfo(min_filter = SDL_GPUFilter.FILTER_NEAREST, mag_filter = SDL_GPUFilter.FILTER_NEAREST,
        mipmap_mode = SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_NEAREST,
        address_mode_u = SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
        address_mode_v = SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE,
        address_mode_w = SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE)
}

def public draw_checker(command : SDL_GPUCommandBuffer?; pipeline : SDL_GPUGraphicsPipeline?;
                        var sampled, target : SDL_GPUTexture?; var sampler : SDL_GPUSampler?; tint : array<float>) : SdlStatus {
    push_native_gpu_fragment_uniforms(command, 0u, tint) |> sdl_try
    var targets <- array(SDL_GPUColorTargetInfo(texture = target, load_op = SDL_GPULoadOp.LOADOP_CLEAR,
        store_op = SDL_GPUStoreOp.STOREOP_STORE, clear_color = SDL_FColor(a = 1.0)))
    return with_native_gpu_render_pass(command, targets) $(var render_pass : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(render_pass, pipeline)
        var bindings <- array(SDL_GPUTextureSamplerBinding(texture = sampled, sampler = sampler))
        sdl_status(SDL_BindGPUFragmentSamplersArray(render_pass, 0u, bindings), "SDL_BindGPUFragmentSamplersArray") |> sdl_try
        SDL_DrawGPUPrimitives(render_pass, 3u, 1u, 0u, 0u)
        return sdl_ok()
    }
}
