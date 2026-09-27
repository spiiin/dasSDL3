options gen2
module stencil_scene_support shared public
require stencil_support public
require ./shaders/stencil_scene_shaders.das as shaders
require dassdl3/sdl3_shader_uniforms
require daslib/defer

def rich_pipeline(device : SDL_GPUDevice?; format, depth_format : SDL_GPUTextureFormat; state : SDL_GPUDepthStencilState; blend : int = 0; write_color : bool = true) {
    return sdl_scope() {
        var vs : SDL_GPUShader? = device |> with_example_shader(shaders::stencil_scene_vertex, shaders::stencil_scene_vertex_reflect) |> sdl_use
        var fs : SDL_GPUShader? = device |> with_example_shader(shaders::stencil_scene_fragment, shaders::stencil_scene_fragment_reflect) |> sdl_use
        let info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vs, fragment_shader = fs, rasterizer_state = SDL_GPURasterizerState(enable_depth_clip = true, cull_mode = SDL_GPUCullMode.CULLMODE_NONE), depth_stencil_state = state, target_info = SDL_GPUGraphicsPipelineTargetInfo(has_depth_stencil_target = true, depth_stencil_format = depth_format))
        let layout <- array(SDL_GPUVertexBufferDescription(pitch = 32u))
        let attrs <- array(SDL_GPUVertexAttribute(format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3), SDL_GPUVertexAttribute(location = 1u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3, offset = 12u), SDL_GPUVertexAttribute(location = 2u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2, offset = 24u))
        var blending = SDL_GPUColorTargetBlendState(color_blend_op = SDL_GPUBlendOp.BLENDOP_ADD, alpha_blend_op = SDL_GPUBlendOp.BLENDOP_ADD, enable_color_write_mask = !write_color, color_write_mask = 0u8)
        if (blend != 0) {
            blending.enable_blend = true
            blending.src_color_blendfactor = blend == 1 ? SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA : SDL_GPUBlendFactor.BLENDFACTOR_ONE
            blending.dst_color_blendfactor = blend == 1 ? SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA : SDL_GPUBlendFactor.BLENDFACTOR_ONE
            if (blend == 3) { blending.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_SRC_COLOR }
            if (blend == 4) {
                blending.src_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_SRC_COLOR
                blending.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_COLOR
            }
            blending.src_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ZERO
            blending.dst_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
        }
        let targets <- array(SDL_GPUColorTargetDescription(format = format, blend_state = blending))
        return <- create_native_gpu_graphics_pipeline(device, info, layout, attrs, targets)
    }
}

def rich_object(command : SDL_GPUCommandBuffer?; pass_ : SDL_GPURenderPass?; pipeline : SDL_GPUGraphicsPipeline?; var mesh : GeometryBuffers; model, vp : float4x4; lighting : shaders::Lighting; var tex : SDL_GPUTexture?; var sampler : SDL_GPUSampler?) : SdlStatus {
    push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model, view_projection = vp)) |> sdl_try
    push_gpu_dsl_fragment_uniform(command, 0u, lighting) |> sdl_try
    SDL_BindGPUGraphicsPipeline(pass_, pipeline)
    let bindings <- array(SDL_GPUTextureSamplerBinding(texture = tex, sampler = sampler))
    sdl_status(SDL_BindGPUFragmentSamplersArray(pass_, 0u, bindings), "stencil texture") |> sdl_try
    return draw_geometry(pass_, mesh)
}
