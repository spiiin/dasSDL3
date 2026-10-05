options gen2
require backend_support
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_native_boost
require daslib/defer
require dassdl3/sdl3_shader_dsl
require dsl_shaders

def draw_frames(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return sdl_scope() {
        var vertex : SDL_GPUShader? = device |> with_dsl_example_shader(triangle_vertex, triangle_vertex_reflect) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_dsl_example_shader(triangle_fragment, triangle_fragment_reflect) |> sdl_use
        return render_pipeline(device, window, vertex, fragment, smoke)
    }
}

def render_loop(device : SDL_GPUDevice?; window : SDL_Window?; pipeline : SDL_GPUGraphicsPipeline?; smoke : bool) : SdlStatus {
    var frame = 0
    while (frame < (smoke ? 3 : 180)) {
        with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var texture : SDL_GPUTexture?; width, height : uint) {
            var tint <- array<float>(0.25, 0.5, 0.75, 1.0)
            push_native_gpu_fragment_uniforms(command, 0u, tint) |> sdl_try
            var targets <- array(SDL_GPUColorTargetInfo(
                texture = texture,
                load_op = SDL_GPULoadOp.LOADOP_CLEAR,
                store_op = SDL_GPUStoreOp.STOREOP_STORE,
                clear_color = SDL_FColor(r = 0.05, b = 0.15, a = 1.0)))
            return sdl_scope() {
                var render_pass : SDL_GPURenderPass?& = with_native_gpu_render_pass(command, targets) |> sdl_use
                SDL_BindGPUGraphicsPipeline(render_pass, pipeline)
                SDL_DrawGPUPrimitives(render_pass, 3u, 1u, 0u, 0u)

                return sdl_ok()
            }
        } |> sdl_try
        SDL_PumpEvents(); SDL_Delay(16u); frame++
    }
    return sdl_status(SDL_WaitForGPUIdle(device), "SDL_WaitForGPUIdle")
}

def render_pipeline(device : SDL_GPUDevice?; window : SDL_Window?; var vertex, fragment : SDL_GPUShader?; smoke : bool) : SdlStatus {
    var info = SDL_GPUGraphicsPipelineCreateInfo(
        vertex_shader = vertex,
        fragment_shader = fragment,
        primitive_type = SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
    info.rasterizer_state.enable_depth_clip = true
    var buffers : array<SDL_GPUVertexBufferDescription>
    var attributes : array<SDL_GPUVertexAttribute>
    var colors <- array(SDL_GPUColorTargetDescription(
        format = SDL_GetGPUSwapchainTextureFormat(device, window)
    ))
    let pipeline = device |> create_native_gpu_graphics_pipeline(info, buffers, attributes, colors) |> sdl_try
    {
        defer() { SDL_ReleaseGPUGraphicsPipeline(device, pipeline) }
        return render_loop(device, window, pipeline, smoke)
    }
}

[export]
def main(smoke : bool) : int {
    let initialized = sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("daScript shader DSL", 640, 480, 0ul) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(dsl_example_formats(), true, "") |> sdl_use
        if (!SDL_ClaimWindowForGPUDevice(device, window)) {return err(sdl_error("SDL_ClaimWindowForGPUDevice"), type<SdlUnit>)}
        { defer() { SDL_ReleaseWindowFromGPUDevice(device, window) }; return draw_frames(device, window, smoke) }

        return sdl_ok()
    }
    if (is_err(initialized)) { print("Shader DSL: {unwrap_err(initialized).message}\n"); return 1 }
    print("Shader DSL PASS\n"); return 0
}
