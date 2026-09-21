options gen2
require daslib/defer
module sdl3_gpu_pipeline_boost shared public
require dassdl3/sdl3_gpu_shader_boost public

def public gpu_graphics_pipeline_info() : SDL_GPUGraphicsPipelineCreateInfo {
    var info : SDL_GPUGraphicsPipelineCreateInfo
    info.primitive_type = SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST
    info.rasterizer_state.fill_mode = SDL_GPUFillMode.FILLMODE_FILL
    info.rasterizer_state.cull_mode = SDL_GPUCullMode.CULLMODE_NONE
    info.rasterizer_state.front_face = SDL_GPUFrontFace.FRONTFACE_COUNTER_CLOCKWISE
    info.rasterizer_state.enable_depth_clip = true
    info.multisample_state.sample_count = SDL_GPUSampleCount.SAMPLECOUNT_1
    return info
}
def public gpu_color_target(format : SDL_GPUTextureFormat) : SDL_GPUColorTargetDescription {
    var color : SDL_GPUColorTargetDescription
    color.format = format
    color.blend_state.src_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
    color.blend_state.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ZERO
    color.blend_state.src_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
    color.blend_state.dst_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ZERO
    color.blend_state.color_blend_op = SDL_GPUBlendOp.BLENDOP_ADD
    color.blend_state.alpha_blend_op = SDL_GPUBlendOp.BLENDOP_ADD
    return color
}
def public with_gpu_graphics_pipeline(device : SDL_GPUDevice?; vertex : GpuShaderHandle; fragment : GpuShaderHandle;
        info : SDL_GPUGraphicsPipelineCreateInfo; buffers : array<SDL_GPUVertexBufferDescription>;
        attributes : array<SDL_GPUVertexAttribute>; colors : array<SDL_GPUColorTargetDescription>;
        blk : block<(pipeline : GpuPipelineHandle) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let id = SDL_CreateGPUCheckedGraphicsPipeline(device,vertex,fragment,info,buffers,attributes,colors)
    if (*id == 0ul) { return err(sdl_error("with_gpu_graphics_pipeline"), type<TT>) }
    {
        defer() { if (!SDL_ReleaseGPUCheckedGraphicsPipeline(device,id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUCheckedGraphicsPipeline"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(id) } else { scope_result <- blk(id) }
    }

    return <- scope_result
}
// Convenience for vertex-ID shaders, one color target, no depth and sample 1.
def public with_gpu_graphics_pipeline(device : SDL_GPUDevice?; vertex : GpuShaderHandle; fragment : GpuShaderHandle;
        format : SDL_GPUTextureFormat; blk : block<(pipeline : GpuPipelineHandle) : $Result<auto(TT); SdlError> >) {
    var buffers : array<SDL_GPUVertexBufferDescription>
    var attributes : array<SDL_GPUVertexAttribute>
    var colors : array<SDL_GPUColorTargetDescription>
    resize(colors,1); colors[0] = gpu_color_target(format)
    return <- with_gpu_graphics_pipeline(device,vertex,fragment,gpu_graphics_pipeline_info(),buffers,attributes,colors,blk)
}
def public gpu_graphics_pipeline_descriptor(device : SDL_GPUDevice?; pipeline : GpuPipelineHandle; var info : SDL_GPUGraphicsPipelineCreateInfo) {
    return sdl_status(SDL_GetGPUCheckedGraphicsPipelineInfo(device,pipeline,info), "gpu_graphics_pipeline_descriptor")
}

def public gpu_graphics_pipeline_descriptor(device : SDL_GPUDevice?; pipeline : GpuPipelineHandle) {
    var info : SDL_GPUGraphicsPipelineCreateInfo
    let status = gpu_graphics_pipeline_descriptor(device,pipeline,info)
    if (is_err(status)) { return err(unwrap_err(status),type<SDL_GPUGraphicsPipelineCreateInfo>) }
    var value = info
    return <- move_ok(value,type<SdlError>)
}
