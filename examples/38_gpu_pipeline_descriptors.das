options gen2
require sdl3

// Value-only pipeline state. General pipeline creation is a separate API stage.
[export]
def main(smoke : bool) : int {
    var sampler : SDL_GPUSamplerCreateInfo
    sampler.min_filter = SDL_GPUFilter.FILTER_LINEAR
    sampler.mag_filter = SDL_GPUFilter.FILTER_LINEAR
    sampler.mipmap_mode = SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR
    sampler.address_mode_u = SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE
    sampler.address_mode_v = sampler.address_mode_u
    sampler.address_mode_w = sampler.address_mode_u
    sampler.max_lod = 16.0
    verify(sampler.props == 0u && !sampler.enable_compare && !sampler.enable_anisotropy)

    var stencil : SDL_GPUStencilOpState
    stencil.fail_op = SDL_GPUStencilOp.STENCILOP_KEEP
    stencil.pass_op = SDL_GPUStencilOp.STENCILOP_REPLACE
    stencil.depth_fail_op = SDL_GPUStencilOp.STENCILOP_KEEP
    stencil.compare_op = SDL_GPUCompareOp.COMPAREOP_ALWAYS
    var depth : SDL_GPUDepthStencilState
    depth.compare_op = SDL_GPUCompareOp.COMPAREOP_LESS
    depth.enable_depth_test = true
    depth.enable_depth_write = true
    depth.back_stencil_state = stencil
    depth.front_stencil_state = stencil
    depth.compare_mask = uint8(255)
    depth.write_mask = uint8(255)
    // Stencil stays disabled until a stencil-capable attachment is supplied.
    verify(!depth.enable_stencil_test)

    var blend : SDL_GPUColorTargetBlendState
    blend.src_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA
    blend.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA
    blend.color_blend_op = SDL_GPUBlendOp.BLENDOP_ADD
    blend.src_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
    blend.dst_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA
    blend.alpha_blend_op = SDL_GPUBlendOp.BLENDOP_ADD
    blend.enable_blend = true
    blend.color_write_mask = uint8(SDL_GPU_COLORCOMPONENT_R | SDL_GPU_COLORCOMPONENT_G | SDL_GPU_COLORCOMPONENT_B)
    blend.enable_color_write_mask = true
    var target : SDL_GPUColorTargetDescription
    target.format = SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM
    target.blend_state = blend
    blend.enable_blend = false
    verify(target.blend_state.enable_blend) // Nested state is copied by value.

    var transfer : SDL_GPUTransferBufferCreateInfo
    transfer.usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD
    transfer.size = 4096u
    verify(transfer.props == 0u)
    print("GPU sampler, depth/stencil, color blending and transfer descriptors ready\n")
    return 0
}
