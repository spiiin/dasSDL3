options gen2
module stencil_support shared public
require port_geometry public
require ./shaders/stencil_shaders.das as shaders
require dassdl3/sdl3_shader_uniforms
require daslib/defer

def keep_stencil(compare : SDL_GPUCompareOp = SDL_GPUCompareOp.COMPAREOP_ALWAYS) : SDL_GPUStencilOpState {
    return SDL_GPUStencilOpState(fail_op = SDL_GPUStencilOp.STENCILOP_KEEP, pass_op = SDL_GPUStencilOp.STENCILOP_KEEP, depth_fail_op = SDL_GPUStencilOp.STENCILOP_KEEP, compare_op = compare)
}
def scene_pipeline(device : SDL_GPUDevice?; format, depth_format : SDL_GPUTextureFormat; state : SDL_GPUDepthStencilState; blend : int = 0; write_color : bool = true) {
    return sdl_scope() {
        var vs : SDL_GPUShader? = device |> with_example_shader(shaders::stencil_vertex, shaders::stencil_vertex_reflect) |> sdl_use
        var fs : SDL_GPUShader? = device |> with_example_shader(shaders::stencil_fragment, shaders::stencil_fragment_reflect) |> sdl_use
        let info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vs, fragment_shader = fs, rasterizer_state = SDL_GPURasterizerState(enable_depth_clip = true, cull_mode = SDL_GPUCullMode.CULLMODE_NONE), depth_stencil_state = state, target_info = SDL_GPUGraphicsPipelineTargetInfo(has_depth_stencil_target = true, depth_stencil_format = depth_format))
        let layout <- array(SDL_GPUVertexBufferDescription(pitch = 32u))
        let attrs <- array(SDL_GPUVertexAttribute(format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3), SDL_GPUVertexAttribute(location = 1u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3, offset = 12u))
        var blending = SDL_GPUColorTargetBlendState(color_blend_op = SDL_GPUBlendOp.BLENDOP_ADD, alpha_blend_op = SDL_GPUBlendOp.BLENDOP_ADD, enable_color_write_mask = !write_color, color_write_mask = 0u8)
        if (blend != 0) {
            blending.enable_blend = true
            blending.src_color_blendfactor = blend == 1 ? SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA : SDL_GPUBlendFactor.BLENDFACTOR_ONE
            blending.dst_color_blendfactor = blend == 1 ? SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA : SDL_GPUBlendFactor.BLENDFACTOR_ONE
            blending.src_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ZERO
            blending.dst_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
        }
        let targets <- array(SDL_GPUColorTargetDescription(format = format, blend_state = blending))
        return <- create_native_gpu_graphics_pipeline(device, info, layout, attrs, targets)
    }
}
def stencil_format(device : SDL_GPUDevice?) : $Result<SDL_GPUTextureFormat; SdlError> {
    for (format in fixed_array(SDL_GPUTextureFormat.TEXTUREFORMAT_D24_UNORM_S8_UINT, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT_S8_UINT)) {
        if (SDL_GPUTextureSupportsFormat(device, format, SDL_GPUTextureType.TEXTURETYPE_2D, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) {
            return ok(format, type<SdlError>)
        }
    }
    return err(SdlError(operation = "depth/stencil", message = "No supported depth/stencil format"), type<SDL_GPUTextureFormat>)
}
def replace_stencil(device : SDL_GPUDevice?; var target : SDL_GPUTexture?&; var size : uint2&; width, height : uint; format : SDL_GPUTextureFormat) : SdlStatus {
    if (size != uint2(width, height)) {
        var next = texture(device, width, height, format, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) |> sdl_try
        if (target != null) {
            SDL_ReleaseGPUTexture(device, target)
        }
        target = next
        size = uint2(width, height)
    }
    return sdl_ok()
}
def stencil_attachment(var depth : SDL_GPUTexture?; clear : bool) : SDL_GPUDepthStencilTargetInfo {
    return SDL_GPUDepthStencilTargetInfo(texture = depth, clear_depth = 1.0, clear_stencil = 0u8, load_op = clear ? SDL_GPULoadOp.LOADOP_CLEAR : SDL_GPULoadOp.LOADOP_LOAD, store_op = SDL_GPUStoreOp.STOREOP_STORE, stencil_load_op = clear ? SDL_GPULoadOp.LOADOP_CLEAR : SDL_GPULoadOp.LOADOP_LOAD, stencil_store_op = SDL_GPUStoreOp.STOREOP_STORE)
}
def object(command : SDL_GPUCommandBuffer?; pass_ : SDL_GPURenderPass?; pipeline : SDL_GPUGraphicsPipeline?; var mesh : GeometryBuffers; model, vp : float4x4; color : float4; light : float3; ambient : float = 0.18; diffuse : float = 0.82) : SdlStatus {
    let transform = shaders::SceneTransform(model = model, view_projection = vp)
    let lighting = shaders::SceneLighting(color = color, light = float4(light, 1.0), shade = float4(ambient, diffuse, 0.0, 0.0))
    push_gpu_dsl_vertex_uniform(command, 0u, transform) |> sdl_try
    push_gpu_dsl_fragment_uniform(command, 0u, lighting) |> sdl_try
    SDL_BindGPUGraphicsPipeline(pass_, pipeline)
    return draw_geometry(pass_, mesh)
}
