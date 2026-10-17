// Adapted from bgfx 32-particles; see the example README and group LICENSE-bgfx.txt.
options gen2
module particles_app shared public
require ../common/multipass_support.das public
require ./shaders/particles_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool; additive : bool = true }
struct Particle { start, end, gravity, color, position : float3; age : float; lifetime : float; scale : float; emitter : int }
struct Resources { particles : array<Particle>; instances : array<float>; buffer : SDL_GPUBuffer ?; transfer : SDL_GPUTransferBuffer ?; sprite : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; pipeline : SDL_GPUGraphicsPipeline ?; seed : uint = 1u; accumulator : float; last_time : float; shape : int = -1 }
def random(var seed : uint&) : float { seed = seed * 1664525u + 1013904223u; return float(seed >> 8u) / 16777216.0 }
def step(var r : Resources; settings : Settings; dt : float) {
    if (settings.reset || r.shape != settings.mode) { clear(r.particles); r.accumulator = 0.0; r.seed = 1u; r.shape = settings.mode }
    if (settings.paused) { return }
    var at = length(r.particles) - 1
    while (at >= 0) { r.particles[at].age += dt; if (r.particles[at].age >= r.particles[at].lifetime) { erase(r.particles, at) }; at-- }
    r.accumulator += dt * 160.0
    let spawn = int(r.accumulator); r.accumulator -= float(spawn)
    let palette = fixed_array(float3(1.0, 0.25, 0.03), float3(0.1, 0.45, 1.0), float3(0.2, 1.0, 0.3), float3(0.8, 0.15, 1.0))
    for (emitter in 0..4) { for (i in 0..spawn) {
        if (length(r.particles) >= 4096) { break }
        let a = random(r.seed) * 2.0 * PI; var y = random(r.seed) * 2.0 - 1.0
        if (settings.mode == 1) { y = abs(y) }
        var p = float3(cos(a) * sqrt(max(1.0 - y * y, 0.0)), y, sin(a) * sqrt(max(1.0 - y * y, 0.0)))
        if (settings.mode == 2 || settings.mode == 3) { p = float3(cos(a), 0.0, sin(a)); if (settings.mode == 3) { p *= sqrt(random(r.seed)) } }
        if (settings.mode == 4) { p = float3(random(r.seed) * 2.0 - 1.0, 0.0, random(r.seed) * 2.0 - 1.0) }
        let origin = float3(float(emitter) * 3.4 - 5.1, 0.0, 0.0)
        let direction = emitter % 2 == 0 ? float3(0.0, 1.0, 0.0) : normalize(p + float3(0.0, 0.001, 0.0))
        let life = 1.5 + random(r.seed) * 2.0; let start = origin + p * 0.6
        push(r.particles, Particle(start = start, end = start + direction * (3.0 + random(r.seed) * 4.0), gravity = float3(0.0, -1.5 * life * life, 0.0), color = palette[emitter], lifetime = life, scale = 0.12 + random(r.seed) * 0.15, emitter = emitter))
    } }
    for (p in r.particles) {
        let t = p.age / p.lifetime; let a = lerp(p.start, p.end, t); let b = lerp(p.end, p.end + p.gravity, t); p.position = lerp(a, b, t)
    }
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() {
        if (r.buffer != null) { SDL_ReleaseGPUBuffer(device, r.buffer) }; if (r.transfer != null) { SDL_ReleaseGPUTransferBuffer(device, r.transfer) }; if (r.sprite != null) { SDL_ReleaseGPUTexture(device, r.sprite) }; if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }; if (r.pipeline != null) { SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline) }
    }
    var buffer = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_VERTEX, size = 131072u)) |> sdl_try; r.buffer = buffer
    r.transfer = SDL_CreateGPUTransferBufferRef(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = 131072u))
    if (r.transfer == null) { return err(sdl_error("Particle upload"), type<SdlUnit>) }
    var tex = texture(device, 256u, 256u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.sprite = tex
    upload_texture(device, r.sprite, "particle.rgba8", 256u, 256u, 4u, 1u) |> sdl_try
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR))
    if (r.sampler == null) { return err(sdl_error("Particle sampler"), type<SdlUnit>) }
    var pipeline = sdl_scope() {
        var vs : SDL_GPUShader? = with_example_shader(device, shaders::particles_vertex, shaders::particles_vertex_reflect) |> sdl_use
        var fs : SDL_GPUShader? = with_example_shader(device, shaders::particles_fragment, shaders::particles_fragment_reflect) |> sdl_use
        let info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vs, fragment_shader = fs, rasterizer_state = SDL_GPURasterizerState(enable_depth_clip = true))
        var color = gpu_color_target(format); color.blend_state.enable_blend = true; color.blend_state.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA
        let targets <- array(color)
        let streams <- array(SDL_GPUVertexBufferDescription(pitch = 32u, input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE))
        let attrs <- array(SDL_GPUVertexAttribute(format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4), SDL_GPUVertexAttribute(location = 1u, offset = 16u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4))
        return create_native_gpu_graphics_pipeline(device, info, streams, attrs, targets)
    } |> sdl_try; r.pipeline = pipeline
    return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    let dt = clamp(time - r.last_time, 0.0, 0.05); r.last_time = time; step(r, settings, dt)
    sort(r.particles) $(a, b : Particle) : bool { return length_sq(a.position - float3(0.0, 3.0, -18.0)) > length_sq(b.position - float3(0.0, 3.0, -18.0)) }
    clear(r.instances)
    for (p in r.particles) { let t = p.age / p.lifetime; let color = lerp(p.color, float3(0.05), t); for (v in fixed_array(p.position.x, p.position.y, p.position.z, p.scale * (1.0 + t * 2.0), color.x, color.y, color.z, (1.0 - t) * (1.0 - t))) { push(r.instances, v) } }
    if (length(r.instances) > 0) { upload_floats(device, command, r.buffer, r.transfer, 131072u, r.instances) |> sdl_try }
    let targets <- array(attachment(output, float4(0.012, 0.015, 0.025, 1.0)))
    return with_native_gpu_render_pass(command, targets) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
        push_gpu_dsl_vertex_uniform(command, 0u, shaders::Camera(vp = camera_matrix(width, height, float3(0.0, 3.0, -18.0), float3(0.0, 3.0, 0.0)))) |> sdl_try
        push_gpu_dsl_fragment_uniform(command, 0u, shaders::Style(config = float4(settings.additive ? 1.0 : 0.0, 0.0, 0.0, 0.0))) |> sdl_try
        var images <- array(r.sprite); bind_images(pass_, images, r.sampler) |> sdl_try
        let bindings <- array(SDL_GPUBufferBinding(buffer = r.buffer)); sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, bindings), "Particle instances") |> sdl_try
        if (length(r.particles) > 0) { SDL_DrawGPUPrimitives(pass_, 6u, uint(length(r.particles)), 0u, 0u) }
        return sdl_ok()
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var settings = Settings(); var running = true; var frames = 0; let start = SDL_GetTicks()
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) { running = false }
                match (event) { if (SdlEvent(key_down = $v(k))) { if (!k.repeat) {
                    if (k.keycode == SDLK_M) { settings.mode = (settings.mode + 1) % 5 }
                    elif (k.keycode == SDLK_SPACE) { settings.paused = !settings.paused }
                    elif (k.keycode == SDLK_A) { settings.additive = !settings.additive }
                    elif (k.keycode == SDLK_R) { settings.reset = true }
                } } if (_) {} }
            }
            if (!running) { break }
            let time = float(SDL_GetTicks() - start) * 0.001
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            settings.reset = false
            set_title(window, "Particles | M: shape | A: additive/alpha | M: mode {settings.mode} | Space: pause | R: reset") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
