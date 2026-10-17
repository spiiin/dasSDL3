// Adapted from bgfx 33-pom; see the example README and group LICENSE-bgfx.txt.
options gen2
module pom_app shared public
require ../common/multipass_support.das public
require ./shaders/pom_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int = 4; paused : bool; reset : bool; scale : float = 0.06; steps : float = 32.0 }
struct Resources { quad : GeometryBuffers; pipeline : SDL_GPUGraphicsPipeline ?; diffuse, normal, heightmap, depth : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; size : uint2; angle : float }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() { release(device, r.quad); if (r.pipeline != null) { SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline) }; if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }; for (resource in fixed_array(r.diffuse, r.normal, r.heightmap, r.depth)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } } }
    var g : Geometry
    let coords = fixed_array(float2(0.0, 0.0), float2(0.0, 1.0), float2(1.0, 1.0), float2(0.0, 0.0), float2(1.0, 1.0), float2(1.0, 0.0))
    for (i in 0..6) { let uv = coords[i]; vertex(g, float3(uv.x * 6.0 - 3.0, 3.0 - uv.y * 6.0, 0.0), float3(0.0, 0.0, -1.0), uv); push(g.indices, uint((i / 3) * 3 + 2 - i % 3)) }
    var quad = upload_geometry(device, g) |> sdl_try; r.quad = quad
    var t = texture(device, 256u, 256u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.diffuse = t
    t = texture(device, 256u, 256u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.normal = t
    t = texture(device, 256u, 256u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.heightmap = t
    upload_texture(device, r.diffuse, "parallax-d.rgba8", 256u, 256u, 4u, 1u) |> sdl_try
    upload_texture(device, r.normal, "parallax-n.rgba8", 256u, 256u, 4u, 1u) |> sdl_try
    upload_texture(device, r.heightmap, "parallax-h.rgba8", 256u, 256u, 4u, 1u) |> sdl_try
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR))
    if (r.sampler == null) { return err(sdl_error("POM sampler"), type<SdlUnit>) }
    let targets <- array(gpu_color_target(format))
    var pipeline = pass_pipeline(device, shaders::pom_vertex, shaders::pom_vertex_reflect, shaders::pom_fragment, shaders::pom_fragment_reflect, targets) |> sdl_try; r.pipeline = pipeline
    return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    replace_depth(device, r.depth, r.size, width, height) |> sdl_try
    if (!settings.paused) { r.angle = 0.5 + sin(time * 0.3) * 0.4 }; if (settings.reset) { r.angle = 0.5 }
    let colors <- array(attachment(output, float4(0.04, 0.05, 0.065, 1.0))); let depth = depth_attachment(r.depth)
    return with_native_gpu_render_pass(command, colors, depth) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
        var images <- array(r.diffuse, r.normal, r.heightmap); bind_images(pass_, images, r.sampler) |> sdl_try
        push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model_matrix(float3(0.0), float3(1.0), r.angle), vp = camera_matrix(width, height, float3(0.0, 0.0, -9.0), float3(0.0)), eye = float4(0.0, 0.0, -9.0, 1.0), light = float4(-3.0, 5.0, -5.0, 1.0))) |> sdl_try
        push_gpu_dsl_fragment_uniform(command, 0u, shaders::Material(config = float4(float(settings.mode), settings.scale, settings.steps, 0.0))) |> sdl_try
        return draw_geometry(pass_, r.quad)
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var settings = Settings(); var running = true; var frames = 0; var start = SDL_GetTicks()
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) { running = false }
                match (event) { if (SdlEvent(key_down = $v(k))) { if (!k.repeat) {
                    if (k.keycode == SDLK_M) { settings.mode = (settings.mode + 1) % 5 }
                    elif (k.keycode == SDLK_SPACE) { settings.paused = !settings.paused }
                    elif (k.keycode == SDLK_R) { settings.reset = true }
                } } if (_) {} }
            }
            if (!running) { break }
            if (settings.reset) { start = SDL_GetTicks() }
            let time = float(SDL_GetTicks() - start) * 0.001
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            settings.reset = false
            set_title(window, "POM | M: flat/normal/parallax/steep/occlusion | M: mode {settings.mode} | Space: pause | R: reset") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
