options gen2
require daslib/defer
module sdl3_gpu_pipeline_boost shared public
require dassdl3/sdl3_gpu_shader_boost public

def public create_gpu_graphics_pipeline(device : SDL_GPUDevice?; vertex : GpuShaderHandle; fragment : GpuShaderHandle;
                                        info : SDL_GPUGraphicsPipelineCreateInfo; buffers : array<SDL_GPUVertexBufferDescription>;
                                        attributes : array<SDL_GPUVertexAttribute>; colors : array<SDL_GPUColorTargetDescription>) {
    return checked_handle_result(SDL_CreateGPUCheckedGraphicsPipeline(device, vertex, fragment, info, buffers, attributes, colors), "SDL_CreateGPUCheckedGraphicsPipeline")
}

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

    let acquired = create_gpu_graphics_pipeline(device, vertex, fragment, info, buffers, attributes, colors)
    if (is_err(acquired)) { return err(unwrap_err(acquired), type<TT>) }
    let id = unwrap(acquired)
    {
        defer() { if (!SDL_ReleaseGPUCheckedGraphicsPipeline(device, id) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_ReleaseGPUCheckedGraphicsPipeline"), type<TT>) } }
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
    resize(colors, 1); colors[0] = gpu_color_target(format)
    return <- with_gpu_graphics_pipeline(device, vertex, fragment, gpu_graphics_pipeline_info(), buffers, attributes, colors, blk)
}
def public gpu_graphics_pipeline_descriptor(device : SDL_GPUDevice?; pipeline : GpuPipelineHandle; var info : SDL_GPUGraphicsPipelineCreateInfo) {
    return sdl_status(SDL_GetGPUCheckedGraphicsPipelineInfo(device, pipeline, info), "gpu_graphics_pipeline_descriptor")
}

def public gpu_graphics_pipeline_descriptor(device : SDL_GPUDevice?; pipeline : GpuPipelineHandle) {
    var info : SDL_GPUGraphicsPipelineCreateInfo
    let status = gpu_graphics_pipeline_descriptor(device, pipeline, info)
    if (is_err(status)) { return err(unwrap_err(status), type<SDL_GPUGraphicsPipelineCreateInfo>) }
    var value = info
    return <- move_ok(value, type<SdlError>)
}

// Owns descriptor arrays only; shader handles are borrowed until creation.
struct GpuGraphicsPipelineOptions {
    vertex : GpuShaderHandle
    fragment : GpuShaderHandle
    info : SDL_GPUGraphicsPipelineCreateInfo = gpu_graphics_pipeline_info()
    buffers : array<SDL_GPUVertexBufferDescription>
    attributes : array<SDL_GPUVertexAttribute>
    colors : array<SDL_GPUColorTargetDescription>
}
def public with_gpu_graphics_pipeline(device : SDL_GPUDevice?; settings : GpuGraphicsPipelineOptions;
                                      blk : block<(pipeline : GpuPipelineHandle) : $Result<auto(TT); SdlError>>) {
    return <- with_gpu_graphics_pipeline(device, settings.vertex, settings.fragment, settings.info,
        settings.buffers, settings.attributes, settings.colors, blk)
}

// Mutating builder: array operations append; state setters overwrite only named fields.
// No GPU ownership or validation until with_gpu_graphics_pipeline creates the resource.
def public gpu_pipeline(vertex, fragment : GpuShaderHandle) {
    var settings <- GpuGraphicsPipelineOptions(vertex = vertex, fragment = fragment)
    return <- settings
}

// Value builders return an owned descriptor. Always use the result.
// Pipeline arrays move out of the input; no reference escapes and no unsafe is needed.
[nodiscard]
def public vertex_buffer(var settings : GpuGraphicsPipelineOptions; slot, pitch : uint;
                         rate : SDL_GPUVertexInputRate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_VERTEX) : GpuGraphicsPipelineOptions {
    push(settings.buffers, SDL_GPUVertexBufferDescription(slot = slot, pitch = pitch, input_rate = rate))
    return <- settings
}

[nodiscard]
def public vertex_attribute(var settings : GpuGraphicsPipelineOptions; location, buffer_slot : uint;
                            format : SDL_GPUVertexElementFormat; offset : uint) : GpuGraphicsPipelineOptions {
    push(settings.attributes, SDL_GPUVertexAttribute(location = location, buffer_slot = buffer_slot, format = format, offset = offset))
    return <- settings
}

[nodiscard]
def public color_target(var settings : GpuGraphicsPipelineOptions; format : SDL_GPUTextureFormat) : GpuGraphicsPipelineOptions {
    push(settings.colors, gpu_color_target(format))
    return <- settings
}

[nodiscard]
def public color_target(var settings : GpuGraphicsPipelineOptions; description : SDL_GPUColorTargetDescription) : GpuGraphicsPipelineOptions {
    push(settings.colors, description)
    return <- settings
}

[nodiscard]
def public depth_target(var settings : GpuGraphicsPipelineOptions; format : SDL_GPUTextureFormat) : GpuGraphicsPipelineOptions {
    settings.info.target_info.has_depth_stencil_target = true
    settings.info.target_info.depth_stencil_format = format
    return <- settings
}

[nodiscard]
def public depth_test(var settings : GpuGraphicsPipelineOptions; compare : SDL_GPUCompareOp;
                      enabled : bool = true) : GpuGraphicsPipelineOptions {
    settings.info.depth_stencil_state.compare_op = compare
    settings.info.depth_stencil_state.enable_depth_test = enabled
    return <- settings
}

[nodiscard]
def public depth_write(var settings : GpuGraphicsPipelineOptions; enabled : bool) : GpuGraphicsPipelineOptions {
    settings.info.depth_stencil_state.enable_depth_write = enabled
    return <- settings
}

// Native state overloads also support direct SDL pipeline creation.
[nodiscard]
def public topology(var settings : SDL_GPUGraphicsPipelineCreateInfo; kind : SDL_GPUPrimitiveType) : SDL_GPUGraphicsPipelineCreateInfo {
    settings.primitive_type = kind
    return <- settings
}
[nodiscard]
def public rasterizer(var settings : SDL_GPUGraphicsPipelineCreateInfo; state : SDL_GPURasterizerState) : SDL_GPUGraphicsPipelineCreateInfo {
    settings.rasterizer_state = state
    return <- settings
}
[nodiscard]
def public sample_count(var settings : SDL_GPUGraphicsPipelineCreateInfo; count : SDL_GPUSampleCount) : SDL_GPUGraphicsPipelineCreateInfo {
    settings.multisample_state.sample_count = count
    return <- settings
}
[nodiscard]
def public topology(var settings : GpuGraphicsPipelineOptions; kind : SDL_GPUPrimitiveType) : GpuGraphicsPipelineOptions {
    settings.info <- topology(settings.info, kind)
    return <- settings
}
[nodiscard]
def public rasterizer(var settings : GpuGraphicsPipelineOptions; state : SDL_GPURasterizerState) : GpuGraphicsPipelineOptions {
    settings.info <- rasterizer(settings.info, state)
    return <- settings
}
[nodiscard]
def public sample_count(var settings : GpuGraphicsPipelineOptions; count : SDL_GPUSampleCount) : GpuGraphicsPipelineOptions {
    settings.info <- sample_count(settings.info, count)
    return <- settings
}
// Complete state setters preserve access to less common SDL settings.
[nodiscard]
def public multisampling(var settings : SDL_GPUGraphicsPipelineCreateInfo; state : SDL_GPUMultisampleState) : SDL_GPUGraphicsPipelineCreateInfo {
    settings.multisample_state = state
    return <- settings
}
[nodiscard]
def public multisampling(var settings : GpuGraphicsPipelineOptions; state : SDL_GPUMultisampleState) : GpuGraphicsPipelineOptions {
    settings.info <- multisampling(settings.info, state)
    return <- settings
}
[nodiscard]
def public blending(var target : SDL_GPUColorTargetDescription; state : SDL_GPUColorTargetBlendState) : SDL_GPUColorTargetDescription {
    target.blend_state = state
    return <- target
}
[nodiscard]
def public color_write_mask(var target : SDL_GPUColorTargetDescription; mask : uint8; enabled : bool = true) : SDL_GPUColorTargetDescription {
    target.blend_state.color_write_mask = mask
    target.blend_state.enable_color_write_mask = enabled
    return <- target
}

[nodiscard]
def public depth_stencil(var settings : SDL_GPUGraphicsPipelineCreateInfo; state : SDL_GPUDepthStencilState) : SDL_GPUGraphicsPipelineCreateInfo {
    settings.depth_stencil_state = state
    return <- settings
}
[nodiscard]
def public depth_stencil(var settings : GpuGraphicsPipelineOptions; state : SDL_GPUDepthStencilState) : GpuGraphicsPipelineOptions {
    settings.info <- depth_stencil(settings.info, state)
    return <- settings
}
[nodiscard]
def public depth_target(var settings : SDL_GPUGraphicsPipelineCreateInfo; format : SDL_GPUTextureFormat) : SDL_GPUGraphicsPipelineCreateInfo {
    settings.target_info.has_depth_stencil_target = true
    settings.target_info.depth_stencil_format = format
    return <- settings
}
[nodiscard]
def public depth_test(var settings : SDL_GPUGraphicsPipelineCreateInfo; compare : SDL_GPUCompareOp; enabled : bool = true) : SDL_GPUGraphicsPipelineCreateInfo {
    settings.depth_stencil_state.compare_op = compare
    settings.depth_stencil_state.enable_depth_test = enabled
    return <- settings
}
[nodiscard]
def public depth_write(var settings : SDL_GPUGraphicsPipelineCreateInfo; enabled : bool) : SDL_GPUGraphicsPipelineCreateInfo {
    settings.depth_stencil_state.enable_depth_write = enabled
    return <- settings
}
[nodiscard]
def public stencil_test(var settings : SDL_GPUGraphicsPipelineCreateInfo; enabled : bool = true) : SDL_GPUGraphicsPipelineCreateInfo {
    settings.depth_stencil_state.enable_stencil_test = enabled
    return <- settings
}
[nodiscard]
def public stencil_faces(var settings : SDL_GPUGraphicsPipelineCreateInfo; front, back : SDL_GPUStencilOpState) : SDL_GPUGraphicsPipelineCreateInfo {
    settings.depth_stencil_state.front_stencil_state = front
    settings.depth_stencil_state.back_stencil_state = back
    return <- settings
}
[nodiscard]
def public stencil_faces(var settings : SDL_GPUGraphicsPipelineCreateInfo; both : SDL_GPUStencilOpState) : SDL_GPUGraphicsPipelineCreateInfo {
    return <- stencil_faces(settings, both, both)
}
[nodiscard]
def public stencil_masks(var settings : SDL_GPUGraphicsPipelineCreateInfo; compare, write : uint8) : SDL_GPUGraphicsPipelineCreateInfo {
    settings.depth_stencil_state.compare_mask = compare
    settings.depth_stencil_state.write_mask = write
    return <- settings
}
[nodiscard]
def public stencil_test(var settings : GpuGraphicsPipelineOptions; enabled : bool = true) : GpuGraphicsPipelineOptions {
    settings.info <- stencil_test(settings.info, enabled)
    return <- settings
}
[nodiscard]
def public stencil_faces(var settings : GpuGraphicsPipelineOptions; front, back : SDL_GPUStencilOpState) : GpuGraphicsPipelineOptions {
    settings.info <- stencil_faces(settings.info, front, back)
    return <- settings
}
[nodiscard]
def public stencil_faces(var settings : GpuGraphicsPipelineOptions; both : SDL_GPUStencilOpState) : GpuGraphicsPipelineOptions {
    settings.info <- stencil_faces(settings.info, both)
    return <- settings
}
[nodiscard]
def public stencil_masks(var settings : GpuGraphicsPipelineOptions; compare, write : uint8) : GpuGraphicsPipelineOptions {
    settings.info <- stencil_masks(settings.info, compare, write)
    return <- settings
}
