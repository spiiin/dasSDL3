options gen2
module raymarch_app shared public
// Port of bgfx examples/03-raymarch; BSD-2-Clause (LICENSE-bgfx.txt).
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_gpu_pipeline_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_window_boost
require daslib/match
require daslib/defer
require math

let WIDTH = 640u
let HEIGHT = 360u

def draw(command : SDL_GPUCommandBuffer?; pipeline : SDL_GPUGraphicsPipeline?;
         var color, depth : SDL_GPUTexture?; time : float) {
    let uniforms <- array<float>(time, float(WIDTH) / float(HEIGHT), 0.1, 100.0)
    command |> push_native_gpu_vertex_uniforms(0u, uniforms) |> sdl_try
    let targets <- array(SDL_GPUColorTargetInfo(texture = color, load_op = SDL_GPULoadOp.LOADOP_CLEAR,
        store_op = SDL_GPUStoreOp.STOREOP_STORE, clear_color = SDL_FColor(a = 1.0)))
    let depth_target = SDL_GPUDepthStencilTargetInfo(texture = depth, clear_depth = 1.0,
        load_op = SDL_GPULoadOp.LOADOP_CLEAR, store_op = SDL_GPUStoreOp.STOREOP_DONT_CARE,
        stencil_load_op = SDL_GPULoadOp.LOADOP_DONT_CARE, stencil_store_op = SDL_GPUStoreOp.STOREOP_DONT_CARE)
    return sdl_scope() {
        var render_pass : SDL_GPURenderPass?& = with_native_gpu_render_pass(command, targets, depth_target) |> sdl_use
        SDL_BindGPUGraphicsPipeline(render_pass, pipeline)
        SDL_DrawGPUPrimitives(render_pass, 6u, 1u, 0u, 0u)
        return sdl_ok()
    }
}

def frame(device : SDL_GPUDevice?; window : SDL_Window?; pipeline : SDL_GPUGraphicsPipeline?;
          var color, depth : SDL_GPUTexture?; time : float) {
    return with_native_gpu_swapchain(device, window) $(command; var swapchain; width, height) {
        draw(command, pipeline, color, depth, time) |> sdl_try
        // Keep the ray aspect ratio when resizing: letterbox the internal 16:9 image.
        let scale = min(float(width) / float(WIDTH), float(height) / float(HEIGHT))
        let w = uint(float(WIDTH) * scale); let h = uint(float(HEIGHT) * scale)
        let blit = SDL_GPUBlitInfo(source = SDL_GPUBlitRegion(texture = color, w = WIDTH, h = HEIGHT),
            destination = SDL_GPUBlitRegion(texture = swapchain, x = (width - w) / 2u, y = (height - h) / 2u, w = w, h = h),
            load_op = SDL_GPULoadOp.LOADOP_CLEAR, clear_color = SDL_FColor(a = 1.0), filter = SDL_GPUFilter.FILTER_LINEAR)
        SDL_BlitGPUTextureRef(command, blit)
        return sdl_ok()
    }
}

def animate(device : SDL_GPUDevice?; window : SDL_Window?; pipeline : SDL_GPUGraphicsPipeline?;
            var color, depth : SDL_GPUTexture?) {
    var running = true; var paused = false; var time = 0.0; var previous = SDL_GetTicks(); var frames = 0
    while (running) {
        for (event in poll_events()) {
            if (should_close(event, window)) { running = false }
            match (event) {
                if (SdlEvent(key_down = $v(key))) {
                    if (key.window_id == SDL_GetWindowID(window) && !key.repeat) {
                        if (key.keycode == SDLK_SPACE) { paused = !paused }
                        elif (key.keycode == SDLK_R) { time = 0.0 }
                    }
                }
                if (_) { }
            }
        }
        if (!running) { break }
        let now = SDL_GetTicks()
        if (!paused) { time += min(0.1, float(now - previous) * 0.001) }
        previous = now
        frame(device, window, pipeline, color, depth, time) |> sdl_try
        frames++
        SDL_Delay(16u)
    }
    sdl_status(SDL_WaitForGPUIdle(device), "SDL_WaitForGPUIdle") |> sdl_try
    print("Raymarch: {frames} frames, {SDL_GetGPUDeviceDriver(device)}.\n")
    return sdl_ok()
}

def resources(device : SDL_GPUDevice?; window : SDL_Window?; var vertex, fragment : SDL_GPUShader?) {
    var info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vertex, fragment_shader = fragment)
    info |> topology(SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
    info |> rasterizer(SDL_GPURasterizerState(enable_depth_clip = true))
    info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT)
    // Background writes depth 1, so use LESS_OR_EQUAL to retain the original colored quad.
    info |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL)
    info |> depth_write(true)
    let colors <- array(gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
    var buffers : array<SDL_GPUVertexBufferDescription>
    var attributes : array<SDL_GPUVertexAttribute>
    return sdl_scope() {
        let pipeline : SDL_GPUGraphicsPipeline? = device |> with_native_gpu_graphics_pipeline(info, buffers, attributes, colors) |> sdl_use
        var color : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT,
            SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER)) |> sdl_use
        var depth : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT,
            SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_use
        return animate(device, window, pipeline, color, depth)
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?) {
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let ext = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/shaders/raymarch"
    var vs = gpu_shader("{base}.vert.{ext}", format, SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    vs |> uniform_buffers(1u)
    let fs = gpu_shader("{base}.frag.{ext}", format, SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    return sdl_scope() {
        var vertex : SDL_GPUShader? = device |> with_native_gpu_shader_file(vs) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_native_gpu_shader_file(fs) |> sdl_use
        return resources(device, window, vertex, fragment)
    }
}
