options gen2
require ./gpu_port_bgfx/common/file_shader_support.das
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_native_boost
require daslib/defer

// The caller owns the returned pipeline. The mobile host uses the same
// setup and drawing code as the desktop entry point, one frame per callback.
def make_triangle_pipeline(device : SDL_GPUDevice?; window : SDL_Window?) {
    let backend = file_shader_backend(device)
    let ext = backend.extension
    let base = "{SDL_GetBasePath()}assets/shaders/triangle"
    var shader = gpu_shader(
        "{base}.vert.{ext}",
        backend.format,
        SDL_GPUShaderStage.SHADERSTAGE_VERTEX) |> entrypoint(backend.entry)
    var vertex = device |> load_native_gpu_shader(shader) |> sdl_try
    {
        defer() { SDL_ReleaseGPUShader(device, vertex) }
        shader.info.stage = SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT
        shader.path = "{base}.frag.{ext}"
        var fragment = device |> load_native_gpu_shader(shader) |> sdl_try
        {
            defer() { SDL_ReleaseGPUShader(device, fragment) }
            return make_pipeline(device, window, vertex, fragment)
        }
    }
}

def draw_frame(device : SDL_GPUDevice?; window : SDL_Window?; pipeline : SDL_GPUGraphicsPipeline?) {
    return <- with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var texture : SDL_GPUTexture?; width, height : uint) {
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
    }
}

def make_pipeline(device : SDL_GPUDevice?; window : SDL_Window?; var vertex, fragment : SDL_GPUShader?) {
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
    return <- create_native_gpu_graphics_pipeline(device, info, buffers, attributes, colors)
}

[export]
def triangle_create(device : SDL_GPUDevice?; window : SDL_Window?) : SDL_GPUGraphicsPipeline? {
    var result <- make_triangle_pipeline(device, window)
    if (is_err(result)) {
        print("Native graphics setup: {unwrap_err(result).message}\n")
        return null
    }
    return move_unwrap(result)
}

[export]
def triangle_frame(device : SDL_GPUDevice?; window : SDL_Window?; pipeline : SDL_GPUGraphicsPipeline?) : int {
    let result = draw_frame(device, window, pipeline)
    if (is_err(result)) {
        print("Native graphics frame: {unwrap_err(result).message}\n")
        return -1
    }
    return is_some(unwrap(result)) ? 1 : 0
}

def draw_frames(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    let pipeline = make_triangle_pipeline(device, window) |> sdl_try
    {
        defer() { SDL_ReleaseGPUGraphicsPipeline(device, pipeline) }
        var frame = 0
        while (frame < (smoke ? 3 : 180)) {
            draw_frame(device, window, pipeline) |> sdl_try
            SDL_PumpEvents(); SDL_Delay(16u); frame++
        }
        return sdl_status(SDL_WaitForGPUIdle(device), "SDL_WaitForGPUIdle")
    }
}

[export]
def main(smoke : bool) : int {
    let initialized = sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("Native SDL GPU triangle", 640, 480, 0ul) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(GPU_SHADER_FORMATS, true, "") |> sdl_use
        if (!SDL_ClaimWindowForGPUDevice(device, window)) {return err(sdl_error("48_gpu_native_graphics"), type<SdlUnit>)}
        { defer() { SDL_ReleaseWindowFromGPUDevice(device, window) }; return draw_frames(device, window, smoke) }

        return sdl_ok()
    }
    if (is_err(initialized)) { print("Native graphics: {unwrap_err(initialized).message}\n"); return 1 }
    print("Native graphics PASS\n"); return 0
}
