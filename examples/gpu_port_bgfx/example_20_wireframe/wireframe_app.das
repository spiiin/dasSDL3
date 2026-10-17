options gen2
// Adapted from bgfx 28-wireframe. Copyright 2016 Dario Manesku.
// BSD-2-Clause: examples/gpu_port_bgfx/LICENSE-bgfx.txt.
module wireframe_app shared public
require ../common/multipass_support.das public
require ./shaders/wireframe_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int = 1; paused : bool; reset : bool }
struct Resources { mesh : GeometryBuffers; pipeline : SDL_GPUGraphicsPipeline ?; depth : SDL_GPUTexture ?; size : uint2; angle : float }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() { release(device, r.mesh); if (r.pipeline != null) { SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline) }; if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth) } }
    let source <- load_geometry("{SDL_GetBasePath()}assets/bgfx/bunny_decimated.msh") |> sdl_try
    var lo = float3(1e20); var hi = float3(-1e20)
    for (i in 0..length(source.vertices) / 8) {
        let base = i * 8; let p = float3(source.vertices[base], source.vertices[base + 1], source.vertices[base + 2])
        lo = min(lo, p); hi = max(hi, p)
    }
    let center = (lo + hi) * 0.5; let scale = 3.5 / max(hi.y - lo.y, 0.001)
    var expanded : Geometry
    // Like bgfx's barycentric path, duplicate indexed vertices once at load time.
    for (i in 0..length(source.indices)) {
        let base = int(source.indices[i]) * 8
        let p = float3(source.vertices[base], source.vertices[base + 1], source.vertices[base + 2])
        let n = float3(source.vertices[base + 3], source.vertices[base + 4], source.vertices[base + 5])
        vertex(expanded, (p - center) * scale, n, i % 3 == 0 ? float2(1.0, 0.0) : (i % 3 == 1 ? float2(0.0, 1.0) : float2(0.0)))
        push(expanded.indices, uint(i))
    }
    var acquired_mesh = upload_geometry(device, expanded) |> sdl_try; r.mesh = acquired_mesh
    let targets <- array(gpu_color_target(format))
    var acquired_pipeline = pass_pipeline(device, shaders::wireframe_vertex, shaders::wireframe_vertex_reflect, shaders::wireframe_fragment, shaders::wireframe_fragment_reflect, targets) |> sdl_try; r.pipeline = acquired_pipeline
    return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    if (r.size != uint2(width, height)) {
        if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth); r.depth = null }
        var acquired_depth = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) |> sdl_try; r.depth = acquired_depth
        r.size = uint2(width, height)
    }
    if (!settings.paused) { r.angle = time * 0.3 }; if (settings.reset) { r.angle = 0.0 }
    let targets <- array(attachment(output, float4(0.035, 0.045, 0.065, 1.0)))
    let depth = depth_attachment(r.depth)
    return with_native_gpu_render_pass(command, targets, depth) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
        let model = model_matrix(float3(0.0), float3(1.0), r.angle)
        push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model, vp = camera_matrix(width, height, float3(0.0, 2.0, -6.0), float3(0.0)))) |> sdl_try
        push_gpu_dsl_fragment_uniform(command, 0u, shaders::Style(params = float4(0.7, float(settings.mode), 0.0, 0.0))) |> sdl_try
        return draw_geometry(pass_, r.mesh)
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var settings = Settings(); var running = true; var frames = 0; let start = SDL_GetTicks()
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) { running = false }
                match (event) { if (SdlEvent(key_down = $v(k))) { if (!k.repeat) {
                    if (k.keycode == SDLK_M) { settings.mode = (settings.mode + 1) % 3 }
                    elif (k.keycode == SDLK_SPACE) { settings.paused = !settings.paused }
                    elif (k.keycode == SDLK_R) { settings.reset = true }
                } } if (_) {} }
            }
            if (!running) { break }
            let time = float(SDL_GetTicks() - start) * 0.001
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            settings.reset = false
            set_title(window, "Wireframe | M: mode {settings.mode} | Space: pause | R: reset") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
