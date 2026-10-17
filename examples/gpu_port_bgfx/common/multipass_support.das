options gen2
require daslib/defer
module multipass_support shared public
// Application-local SDL helpers for bgfx 15/16/18/19/21. No frame graph.
require ./port_geometry.das public
require dassdl3/sdl3_shader_uniforms public
require dassdl3/sdl3_gpu_sampler_boost public
require dassdl3/sdl3_events public
require dassdl3/sdl3_window_boost public
require daslib/match

def pass_pipeline(device : SDL_GPUDevice?; vs, vr, fs, fr : array<uint>; colors : array<SDL_GPUColorTargetDescription>; geometry : bool = true; depth : bool = true; write_depth : bool = true) {
    return sdl_scope() {
        var vertex : SDL_GPUShader? = with_example_shader(device, vs, vr) |> sdl_use
        var fragment : SDL_GPUShader? = with_example_shader(device, fs, fr) |> sdl_use
        var info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vertex, fragment_shader = fragment,
            rasterizer_state = SDL_GPURasterizerState(enable_depth_clip = true))
        if (depth) {
            info <- info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL) |> depth_write(write_depth)
        }
        var layout : array<SDL_GPUVertexBufferDescription>
        var attributes : array<SDL_GPUVertexAttribute>
        if (geometry) {
            info.rasterizer_state.cull_mode = SDL_GPUCullMode.CULLMODE_BACK
            info.rasterizer_state.front_face = SDL_GPUFrontFace.FRONTFACE_CLOCKWISE
            layout <- array(SDL_GPUVertexBufferDescription(pitch = 32u))
            attributes <- array(SDL_GPUVertexAttribute(format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),
                SDL_GPUVertexAttribute(location = 1u, offset = 12u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),
                SDL_GPUVertexAttribute(location = 2u, offset = 24u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2))
        }
        return <- create_native_gpu_graphics_pipeline(device, info, layout, attributes, colors)
    }
}
def attachment(var tex : SDL_GPUTexture?; clear : float4 = float4(0.0); load : bool = false) {
    return SDL_GPUColorTargetInfo(texture = tex, clear_color = SDL_FColor(r = clear.x, g = clear.y, b = clear.z, a = clear.w),
        load_op = load ? SDL_GPULoadOp.LOADOP_LOAD : SDL_GPULoadOp.LOADOP_CLEAR, store_op = SDL_GPUStoreOp.STOREOP_STORE)
}
def bind_images(pass_ : SDL_GPURenderPass?; var images : array<SDL_GPUTexture?>; var sampler : SDL_GPUSampler?) : SdlStatus {
    var bindings : array<SDL_GPUTextureSamplerBinding>
    for (image in images) { push(bindings, SDL_GPUTextureSamplerBinding(texture = image, sampler = sampler)) }
    return sdl_status(SDL_BindGPUFragmentSamplersArray(pass_, 0u, bindings), "SDL_BindGPUFragmentSamplersArray")
}
def fullscreen(command : SDL_GPUCommandBuffer?; pipeline : SDL_GPUGraphicsPipeline?; var target : SDL_GPUTexture?; var sources : array<SDL_GPUTexture?>; var sampler : SDL_GPUSampler?; load : bool = false) : SdlStatus {
    let colors <- array(attachment(target, float4(0.0), load))
    return with_native_gpu_render_pass(command, colors) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, pipeline)
        bind_images(pass_, sources, sampler) |> sdl_try
        SDL_DrawGPUPrimitives(pass_, 3u, 1u, 0u, 0u)
        return sdl_ok()
    }
}
def ortho(extent : float; near, far : float) : float4x4 {
    var p = identity_matrix()
    p[0].x = 1.0 / extent; p[1].y = 1.0 / extent
    p[2].z = 1.0 / (far - near); p[3].z = -near / (far - near)
    return p
}
def perspective(aspect, fov_scale, near, far : float) : float4x4 {
    var p : float4x4
    p[0].x = fov_scale / aspect; p[1].y = fov_scale
    p[2] = float4(0.0, 0.0, far / (far - near), 1.0)
    p[3].z = -near * far / (far - near)
    return p
}
