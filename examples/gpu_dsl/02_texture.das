options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_native_boost
require daslib/defer
require dassdl3/sdl3_shader_dsl
require texture_shaders
require texture_support

def draw_frames(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return sdl_scope() {
        var vertex : SDL_GPUShader? = device |> with_gpu_dsl_shader(texture_vertex, texture_vertex_reflect) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_gpu_dsl_shader(texture_fragment, texture_fragment_reflect) |> sdl_use
        return render_pipeline(device, window, vertex, fragment, smoke)
    }
}

def render_loop(device : SDL_GPUDevice?; window : SDL_Window?; pipeline : SDL_GPUGraphicsPipeline?; smoke : bool) : SdlStatus {
    return sdl_scope() {
        var sampled : SDL_GPUTexture? = with_native_gpu_texture(device,
            gpu_texture(2u, 2u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_use
        var sampler : SDL_GPUSampler? = with_native_gpu_sampler(device, checker_sampler()) |> sdl_use
        upload_checker(device, sampled) |> sdl_try
        var frame = 0
        while (frame < (smoke ? 3 : 180)) {
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var target : SDL_GPUTexture?; width, height : uint) {
                var tint <- array<float>(1.0, 1.0, 1.0, 1.0)
                return draw_checker(command, pipeline, sampled, target, sampler, tint)
            } |> sdl_try
            SDL_PumpEvents(); SDL_Delay(16u); frame++
        }
        return sdl_status(SDL_WaitForGPUIdle(device), "SDL_WaitForGPUIdle")
    }
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
        let window : SDL_Window? = with_window("daScript DSL - texture sampling", 640, 480, 0ul) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(SDL_GPU_SHADERFORMAT_SPIRV, true, "vulkan") |> sdl_use
        if (!SDL_ClaimWindowForGPUDevice(device, window)) {return err(sdl_error("SDL_ClaimWindowForGPUDevice"), type<SdlUnit>)}
        { defer() { SDL_ReleaseWindowFromGPUDevice(device, window) }; return draw_frames(device, window, smoke) }

        return sdl_ok()
    }
    if (is_err(initialized)) { print("Shader DSL: {unwrap_err(initialized).message}\n"); return 1 }
    print("Shader DSL texture PASS\n"); return 0
}
