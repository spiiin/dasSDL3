options gen2
require ./shaders/hdr_shaders.das as shaders
module hdr_app shared public
// bgfx 09-hdr; BSD-2-Clause (LICENSE-bgfx.txt). FP16 replaces packed RGBE8.
require bgfx_support public
require mesh_data
require dassdl3/sdl3_gpu_sampler_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_window_boost
require daslib/match
require daslib/defer
require math

struct HdrResources {
    sky, scene, lum, average, bright, blur, tonemap : SDL_GPUGraphicsPipeline?
    vb, ib : SDL_GPUBuffer?
    count : uint
    environment : SDL_GPUTexture?
    sampler : SDL_GPUSampler?
}

struct HdrTargets {
    scene, depth, bright, blur : SDL_GPUTexture?
    luminance : array<SDL_GPUTexture?>
    size : uint2
}

struct HdrSettings {
    middle_gray : float = 0.18
    white : float = 1.1
    threshold : float = 1.5
    bloom : bool = true
}

def release_targets(device : SDL_GPUDevice?; var targets : HdrTargets) {
    let textures <- array(targets.scene, targets.depth, targets.bright, targets.blur)
    for (tex in textures) { if (tex != null) { SDL_ReleaseGPUTexture(device, tex) } }
    for (tex in targets.luminance) { if (tex != null) { SDL_ReleaseGPUTexture(device, tex) } }
    targets.scene = null; targets.depth = null; targets.bright = null; targets.blur = null
    clear(targets.luminance); targets.size = uint2(0u)
}

def resize_targets(device : SDL_GPUDevice?; var targets : HdrTargets; width, height : uint) : SdlStatus {
    if (targets.size.x == width && targets.size.y == height) { return sdl_ok() }
    release_targets(device, targets)
    let format = SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT
    let usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER
    var tex = texture(device, width, height, format, usage) |> sdl_try
    targets.scene = tex
    tex = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) |> sdl_try
    targets.depth = tex
    tex = texture(device, max(1u, width / 2u), max(1u, height / 2u), format, usage) |> sdl_try
    targets.bright = tex
    tex = texture(device, max(1u, width / 8u), max(1u, height / 8u), format, usage) |> sdl_try
    targets.blur = tex
    let sizes <- array<uint>(128u, 64u, 16u, 4u, 1u)
    for (side in sizes) {
        tex = texture(device, side, side, format, usage) |> sdl_try
        push(targets.luminance, tex)
    }
    targets.size = uint2(width, height)
    return sdl_ok()
}

def release_resources(device : SDL_GPUDevice?; var r : HdrResources) {
    let pipelines <- array(r.sky, r.scene, r.lum, r.average, r.bright, r.blur, r.tonemap)
    for (graphics in pipelines) { if (graphics != null) { SDL_ReleaseGPUGraphicsPipeline(device, graphics) } }
    if (r.vb != null) { SDL_ReleaseGPUBuffer(device, r.vb) }
    if (r.ib != null) { SDL_ReleaseGPUBuffer(device, r.ib) }
    if (r.environment != null) { SDL_ReleaseGPUTexture(device, r.environment) }
    if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
}

def with_resources(device : SDL_GPUDevice?; output_format : SDL_GPUTextureFormat;
                   body : block<(var resources : HdrResources) : SdlStatus>) : SdlStatus {
    var r : HdrResources
    defer() { release_resources(device, r) }
    let mesh <- load_mesh("{SDL_GetBasePath()}assets/meshes/bunny.msh") |> sdl_try
    r.count = mesh.index_count
    var buffer = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_VERTEX, size = uint(length(mesh.vertices)))) |> sdl_try
    r.vb = buffer
    buffer = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_INDEX, size = uint(length(mesh.indices)))) |> sdl_try
    r.ib = buffer
    upload_bytes(device, r.vb, mesh.vertices) |> sdl_try
    upload_bytes(device, r.ib, mesh.indices) |> sdl_try
    var environment = texture(device, 512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, SDL_GPU_TEXTUREUSAGE_SAMPLER, true) |> sdl_try
    r.environment = environment
    upload_texture(device, r.environment, "uffizi.rgba16f", 512u, 512u, 8u, 6u) |> sdl_try
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR))
    if (r.sampler == null) { return err(sdl_error("SDL_CreateGPUSampler"), type<SdlUnit>) }
    let fp16 = SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT
    var empty_buffers : array<SDL_GPUVertexBufferDescription>; var empty_attributes : array<SDL_GPUVertexAttribute>
    var graphics = pipeline(device, shaders::hdr_sky_vertex, shaders::hdr_sky_vertex_reflect, shaders::hdr_sky_fragment, shaders::hdr_sky_fragment_reflect, fp16, false, empty_buffers, empty_attributes) |> sdl_try
    r.sky = graphics
    graphics = pipeline(device, shaders::hdr_filter_vertex, shaders::hdr_filter_vertex_reflect, shaders::hdr_lum_fragment, shaders::hdr_lum_fragment_reflect, fp16, false, empty_buffers, empty_attributes) |> sdl_try
    r.lum = graphics
    graphics = pipeline(device, shaders::hdr_filter_vertex, shaders::hdr_filter_vertex_reflect, shaders::hdr_avg_fragment, shaders::hdr_avg_fragment_reflect, fp16, false, empty_buffers, empty_attributes) |> sdl_try
    r.average = graphics
    graphics = pipeline(device, shaders::hdr_tone_vertex, shaders::hdr_tone_vertex_reflect, shaders::hdr_bright_fragment, shaders::hdr_bright_fragment_reflect, fp16, false, empty_buffers, empty_attributes) |> sdl_try
    r.bright = graphics
    graphics = pipeline(device, shaders::hdr_filter_vertex, shaders::hdr_filter_vertex_reflect, shaders::hdr_blur_fragment, shaders::hdr_blur_fragment_reflect, fp16, false, empty_buffers, empty_attributes) |> sdl_try
    r.blur = graphics
    graphics = pipeline(device, shaders::hdr_tone_vertex, shaders::hdr_tone_vertex_reflect, shaders::hdr_tone_fragment, shaders::hdr_tone_fragment_reflect, output_format, false, empty_buffers, empty_attributes) |> sdl_try
    r.tonemap = graphics
    let buffers <- array(SDL_GPUVertexBufferDescription(pitch = 24u))
    let attributes <- array(SDL_GPUVertexAttribute(location = 0u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),
        SDL_GPUVertexAttribute(location = 1u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3, offset = 12u))
    graphics = pipeline(device, shaders::hdr_scene_vertex, shaders::hdr_scene_vertex_reflect, shaders::hdr_scene_fragment, shaders::hdr_scene_fragment_reflect, fp16, true, buffers, attributes, true) |> sdl_try
    r.scene = graphics
    return body(r)
}

def uniforms(command : SDL_GPUCommandBuffer?; time : float; size : uint2; settings : HdrSettings; sample_step : float2) {
    let values <- array<float>(time, float(size.x) / float(size.y), float(size.x), float(size.y),
        settings.middle_gray, settings.white * settings.white, settings.threshold, settings.bloom ? 1.0 : 0.0,
        sample_step.x, sample_step.y, 0.0, 0.0)
    return command |> push_native_gpu_vertex_uniforms(0u, values)
}

def post(command : SDL_GPUCommandBuffer?; graphics : SDL_GPUGraphicsPipeline?; var destination : SDL_GPUTexture?;
         var sampler : SDL_GPUSampler?; var textures : array<SDL_GPUTexture?>) : SdlStatus {
    let colors <- array(SDL_GPUColorTargetInfo(texture = destination, load_op = SDL_GPULoadOp.LOADOP_DONT_CARE, store_op = SDL_GPUStoreOp.STOREOP_STORE))
    var bindings : array<SDL_GPUTextureSamplerBinding>
    for (i in 0 .. length(textures)) { push(bindings, SDL_GPUTextureSamplerBinding(texture = textures[i], sampler = sampler)) }
    return with_native_gpu_render_pass(command, colors) $(var render_pass) {
        SDL_BindGPUGraphicsPipeline(render_pass, graphics)
        sdl_status(SDL_BindGPUFragmentSamplersArray(render_pass, 0u, bindings), "SDL_BindGPUFragmentSamplersArray") |> sdl_try
        SDL_DrawGPUPrimitives(render_pass, 3u, 1u, 0u, 0u)
        return sdl_ok()
    }
}

def render_scene(command : SDL_GPUCommandBuffer?; var r : HdrResources; var targets : HdrTargets) : SdlStatus {
    var environment <- array(r.environment)
    post(command, r.sky, targets.scene, r.sampler, environment) |> sdl_try
    let colors <- array(SDL_GPUColorTargetInfo(texture = targets.scene, load_op = SDL_GPULoadOp.LOADOP_LOAD, store_op = SDL_GPUStoreOp.STOREOP_STORE))
    let depth = depth_attachment(targets.depth)
    return with_native_gpu_render_pass(command, colors, depth) $(var render_pass) {
        SDL_BindGPUGraphicsPipeline(render_pass, r.scene)
        let buffers <- array(SDL_GPUBufferBinding(buffer = r.vb))
        let index = SDL_GPUBufferBinding(buffer = r.ib)
        let textures <- array(SDL_GPUTextureSamplerBinding(texture = r.environment, sampler = r.sampler))
        sdl_status(SDL_BindGPUVertexBuffersArray(render_pass, 0u, buffers), "SDL_BindGPUVertexBuffersArray") |> sdl_try
        sdl_status(SDL_BindGPUFragmentSamplersArray(render_pass, 0u, textures), "SDL_BindGPUFragmentSamplersArray") |> sdl_try
        SDL_BindGPUIndexBufferRef(render_pass, index, SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
        SDL_DrawGPUIndexedPrimitives(render_pass, r.count, 1u, 0u, 0, 0u)
        return sdl_ok()
    }
}

def draw(command : SDL_GPUCommandBuffer?; var r : HdrResources; var targets : HdrTargets;
         var output : SDL_GPUTexture?; time : float; settings : HdrSettings) : SdlStatus {
    let size = targets.size
    uniforms(command, time, size, settings, float2(1.0 / 128.0)) |> sdl_try
    render_scene(command, r, targets) |> sdl_try
    var sources <- array(targets.scene)
    post(command, r.lum, targets.luminance[0], r.sampler, sources) |> sdl_try
    let sizes <- array<float>(128.0, 64.0, 16.0, 4.0)
    for (i in 1 .. 5) {
        uniforms(command, time, size, settings, float2(1.0 / sizes[i - 1])) |> sdl_try
        sources[0] = targets.luminance[i - 1]
        post(command, r.average, targets.luminance[i], r.sampler, sources) |> sdl_try
    }
    sources[0] = targets.scene; push(sources, targets.luminance[4])
    uniforms(command, time, size, settings, float2(1.0 / float(size.x), 1.0 / float(size.y))) |> sdl_try
    post(command, r.bright, targets.bright, r.sampler, sources) |> sdl_try
    resize(sources, 1); sources[0] = targets.bright
    uniforms(command, time, size, settings, float2(0.0, 1.0 / float(max(1u, size.y / 2u)))) |> sdl_try
    post(command, r.blur, targets.blur, r.sampler, sources) |> sdl_try
    sources[0] = targets.scene; push(sources, targets.luminance[4]); push(sources, targets.blur)
    uniforms(command, time, size, settings, float2(1.0 / float(max(1u, size.x / 8u)), 0.0)) |> sdl_try
    return post(command, r.tonemap, output, r.sampler, sources)
}

def animate(device : SDL_GPUDevice?; window : SDL_Window?; var r : HdrResources) : SdlStatus {
    var targets : HdrTargets
    defer() { release_targets(device, targets) }
    var settings = HdrSettings(); var running = true; var paused = false; var time = 0.0; var previous = SDL_GetTicks()
    while (running) {
        for (event in poll_events()) {
            if (should_close(event, window)) { running = false }
            match (event) {
                if (SdlEvent(key_down = $v(key))) {
                    if (key.window_id == SDL_GetWindowID(window)) {
                        if (key.keycode == SDLK_SPACE && !key.repeat) { paused = !paused }
                        elif (key.keycode == SDLK_B && !key.repeat) { settings.bloom = !settings.bloom }
                        elif (key.keycode == SDLK_R) { time = 0.0; settings = HdrSettings() }
                        elif (key.keycode == SDLK_UP) { settings.middle_gray = min(1.0, settings.middle_gray + 0.02) }
                        elif (key.keycode == SDLK_DOWN) { settings.middle_gray = max(0.02, settings.middle_gray - 0.02) }
                        elif (key.keycode == SDLK_RIGHT) { settings.threshold = min(10.0, settings.threshold + 0.1) }
                        elif (key.keycode == SDLK_LEFT) { settings.threshold = max(0.0, settings.threshold - 0.1) }
                        elif (key.keycode == SDLK_W) { settings.white = min(10.0, settings.white + 0.1) }
                        elif (key.keycode == SDLK_S) { settings.white = max(0.1, settings.white - 0.1) }
                    }
                }
                if (_) { }
            }
        }
        if (!running) { break }
        let now = SDL_GetTicks(); if (!paused) { time += min(0.1, float(now - previous) * 0.001) * 0.37 }; previous = now
        with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var swapchain : SDL_GPUTexture?; width, height : uint) {
            resize_targets(device, targets, width, height) |> sdl_try
            return draw(command, r, targets, swapchain, time, settings)
        } |> sdl_try
        set_title(window, "bgfx HDR | gray {settings.middle_gray}, white {settings.white}, threshold {settings.threshold} | arrows/W/S/B/Space/R/Esc") |> sdl_try
        SDL_Delay(16u)
    }
    return sdl_ok()
}

def run(device : SDL_GPUDevice?; window : SDL_Window?) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) { return animate(device, window, r) }
}
