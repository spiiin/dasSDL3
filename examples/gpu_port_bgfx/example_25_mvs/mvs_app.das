// Adapted from bgfx 34-mvs; see the example README and group LICENSE-bgfx.txt.
options gen2
module mvs_app shared public
require ../common/multipass_support.das public
require ./shaders/mvs_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool }
struct Resources { positions, colors, alternate : SDL_GPUBuffer ?; pipeline : SDL_GPUGraphicsPipeline ?; depth : SDL_GPUTexture ?; size : uint2; angle : float }
def create_stream(device : SDL_GPUDevice?; values : array<float>) {
    var buffer = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_VERTEX, size = uint(length(values)) * 4u)) |> sdl_try
    var success = false
    {
        defer() { if (!success) { SDL_ReleaseGPUBuffer(device, buffer) } }
        sdl_scope() {
            var transfer : SDL_GPUTransferBuffer? = with_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = uint(length(values)) * 4u)) |> sdl_use
            var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
            upload_floats(device, command, buffer, transfer, uint(length(values)) * 4u, values) |> sdl_try
            return native_gpu_submit(command)
        } |> sdl_try
        success = true
    }
    return <- move_ok(buffer, type<SdlError>)
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() {
        for (resource in fixed_array(r.positions, r.colors, r.alternate)) { if (resource != null) { SDL_ReleaseGPUBuffer(device, resource) } }
        if (r.pipeline != null) { SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline) }
        if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth) }
    }
    let cube <- cube_geometry(); var positions, colors, alternate : array<float>
    for (i in 0..36) {
        let p = float3(cube.vertices[i * 8], cube.vertices[i * 8 + 1], cube.vertices[i * 8 + 2])
        for (v in fixed_array(p.x, p.y, p.z)) { push(positions, v) }
        for (v in fixed_array((p.x + 1.0) * 0.5, (p.y + 1.0) * 0.5, (p.z + 1.0) * 0.5, 1.0)) { push(colors, v) }
        for (v in fixed_array(0.9, 0.5, 0.15, 1.0)) { push(alternate, v) }
    }
    var p = create_stream(device, positions) |> sdl_try; r.positions = p
    p = create_stream(device, colors) |> sdl_try; r.colors = p
    p = create_stream(device, alternate) |> sdl_try; r.alternate = p
    var pipeline = sdl_scope() {
        var vs : SDL_GPUShader? = with_example_shader(device, shaders::mvs_vertex, shaders::mvs_vertex_reflect) |> sdl_use
        var fs : SDL_GPUShader? = with_example_shader(device, shaders::mvs_fragment, shaders::mvs_fragment_reflect) |> sdl_use
        var info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vs, fragment_shader = fs, rasterizer_state = SDL_GPURasterizerState(enable_depth_clip = true, cull_mode = SDL_GPUCullMode.CULLMODE_BACK, front_face = SDL_GPUFrontFace.FRONTFACE_CLOCKWISE))
        info <- info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS) |> depth_write(true)
        let streams <- array(SDL_GPUVertexBufferDescription(slot = 0u, pitch = 12u), SDL_GPUVertexBufferDescription(slot = 1u, pitch = 16u))
        let attrs <- array(SDL_GPUVertexAttribute(buffer_slot = 0u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3), SDL_GPUVertexAttribute(location = 1u, buffer_slot = 1u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4))
        let targets <- array(gpu_color_target(format))
        return create_native_gpu_graphics_pipeline(device, info, streams, attrs, targets)
    } |> sdl_try; r.pipeline = pipeline
    return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    replace_depth(device, r.depth, r.size, width, height) |> sdl_try
    if (!settings.paused) { r.angle = time }; if (settings.reset) { r.angle = 0.0 }
    let targets <- array(attachment(output, float4(0.04, 0.04, 0.05, 1.0))); let depth = depth_attachment(r.depth)
    return with_native_gpu_render_pass(command, targets, depth) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
        let streams <- array(SDL_GPUBufferBinding(buffer = r.positions), SDL_GPUBufferBinding(buffer = settings.mode == 0 ? r.colors : r.alternate))
        sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, streams), "Two vertex streams") |> sdl_try
        let vp = camera_matrix(width, height, float3(0.0, 0.0, -40.0), float3(0.0))
        for (y in 0..11) { for (x in 0..11) {
            let model = model_matrix(float3(float(x - 5) * 3.0, float(y - 5) * 3.0, 0.0), float3(0.8), r.angle + float(x + y) * 0.17)
            push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model, vp = vp, tint = float4(1.0))) |> sdl_try
            SDL_DrawGPUPrimitives(pass_, 36u, 1u, 0u, 0u)
        } }
        return sdl_ok()
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var settings = Settings(); var running = true; var frames = 0; var start = SDL_GetTicks()
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) { running = false }
                match (event) { if (SdlEvent(key_down = $v(k))) { if (!k.repeat) {
                    if (k.keycode == SDLK_M) { settings.mode = (settings.mode + 1) % 2 }
                    elif (k.keycode == SDLK_SPACE) { settings.paused = !settings.paused }
                    elif (k.keycode == SDLK_R) { settings.reset = true }
                } } if (_) {} }
            }
            if (!running) { break }
            if (settings.reset) { start = SDL_GetTicks() }
            let time = float(SDL_GetTicks() - start) * 0.001
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            settings.reset = false
            set_title(window, "Multiple vertex streams | M: color buffer | M: mode {settings.mode} | Space: pause | R: reset") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
