options gen2
require daslib/defer
require daslib/match
module shadowmaps_app shared public
require ../multipass_support.das public
require ./shaders/shadowmap_shaders.das as shaders
struct Settings { kind : int = 0; filter : int = 1; shadows : bool = true; debug : bool = false; linear_depth : bool = false }
struct Resources {
    cube, plane, bunny, hollow, tree : GeometryBuffers
    depth_pipeline, lighting, blur, preview : SDL_GPUGraphicsPipeline?
    maps : SDL_GPUTexture? [4]
    scratch, shadow_depth, depth : SDL_GPUTexture?
    sampler, linear_sampler : SDL_GPUSampler?
    size : uint2
}
def release(device : SDL_GPUDevice?; var r : Resources) {
    release(device, r.cube); release(device, r.plane); release(device, r.bunny); release(device, r.hollow); release(device, r.tree)
    for (p in fixed_array(r.depth_pipeline, r.lighting, r.blur, r.preview)) { if (p != null) { SDL_ReleaseGPUGraphicsPipeline(device, p) } }
    for (t in r.maps) { if (t != null) { SDL_ReleaseGPUTexture(device, t) } }
    for (t in fixed_array(r.scratch, r.shadow_depth, r.depth)) { if (t != null) { SDL_ReleaseGPUTexture(device, t) } }
    if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
    if (r.linear_sampler != null) { SDL_ReleaseGPUSampler(device, r.linear_sampler) }
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r : Resources
    defer() { release(device, r) }
    let cube <- cube_geometry(); let plane <- plane_geometry(20.0)
    let bunny <- load_geometry("{SDL_GetBasePath()}assets/meshes/bunny.msh") |> sdl_try
    var g = upload_geometry(device, cube) |> sdl_try; r.cube = g
    g = upload_geometry(device, plane) |> sdl_try; r.plane = g
    g = upload_geometry(device, bunny) |> sdl_try; r.bunny = g
    let hollow <- load_geometry("{SDL_GetBasePath()}assets/bgfx/hollowcube.msh") |> sdl_try
    let tree <- load_geometry("{SDL_GetBasePath()}assets/bgfx/tree.msh") |> sdl_try
    g = upload_geometry(device, hollow) |> sdl_try; r.hollow = g
    g = upload_geometry(device, tree) |> sdl_try; r.tree = g
    let format_map = SDL_GPUTextureFormat.TEXTUREFORMAT_R32G32B32A32_FLOAT
    let usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER
    for (i in 0..4) { var t = texture(device, 512u, 512u, format_map, usage) |> sdl_try; r.maps[i] = t }
    var t = texture(device, 512u, 512u, format_map, usage) |> sdl_try; r.scratch = t
    t = texture(device, 512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) |> sdl_try; r.shadow_depth = t
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_NEAREST))
    if (r.sampler == null) { return err(sdl_error("SDL_CreateGPUSampler"), type<SdlUnit>) }
    r.linear_sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR))
    if (r.linear_sampler == null) { return err(sdl_error("SDL_CreateGPUSampler"), type<SdlUnit>) }
    let maps <- array(gpu_color_target(format_map)); let colors <- array(gpu_color_target(format))
    var p = pass_pipeline(device, shaders::shadowmap_depth_vertex, shaders::shadowmap_depth_vertex_reflect, shaders::shadowmap_depth, shaders::shadowmap_depth_reflect, maps) |> sdl_try; r.depth_pipeline = p
    p = pass_pipeline(device, shaders::shadowmap_vertex, shaders::shadowmap_vertex_reflect, shaders::shadowmap_lighting, shaders::shadowmap_lighting_reflect, colors) |> sdl_try; r.lighting = p
    p = pass_pipeline(device, shaders::shadowmap_fullscreen, shaders::shadowmap_fullscreen_reflect, shaders::shadowmap_blur, shaders::shadowmap_blur_reflect, maps, false, false) |> sdl_try; r.blur = p
    p = pass_pipeline(device, shaders::shadowmap_fullscreen, shaders::shadowmap_fullscreen_reflect, shaders::shadowmap_debug, shaders::shadowmap_debug_reflect, colors, false, false) |> sdl_try; r.preview = p
    return body(r)
}
def matrices(time : float; settings : Settings; aspect : float) : shaders::ShadowFrame {
    let eye = float3(0.0, 13.0, -28.0); let at = float3(0.0, 2.0, 0.0)
    let forward = normalize(at - eye)
    let light = float3(sin(time * 0.3) * 12.0, 16.0, -12.0)
    var f = shaders::ShadowFrame(light = float4(light, float(settings.kind)), eye = float4(eye, 1.0), forward = float4(forward, settings.linear_depth ? 1.0 : 0.0), splits = float4(12.0, 24.0, 45.0, 85.0), controls = float4(float(settings.filter), 0.0015, 1.0 / 512.0, settings.shadows ? 1.0 : 0.0))
    if (settings.kind == 0) { f.m0 = perspective(1.0, 0.8, 1.0, 80.0) * look_at_lh(light, float3(0.0), float3(0.0, 1.0, 0.0)) }
    elif (settings.kind == 1) {
        // Four tetrahedral views, as in bgfx's omni shadow implementation.
        let projection = perspective(1.0, 0.35, 0.5, 80.0)
        f.m0 = projection * look_at_lh(light, light + float3(1.0, 1.0, 1.0), float3(0.0, 1.0, 0.0))
        f.m1 = projection * look_at_lh(light, light + float3(-1.0, -1.0, 1.0), float3(0.0, 1.0, 0.0))
        f.m2 = projection * look_at_lh(light, light + float3(-1.0, 1.0, -1.0), float3(0.0, 1.0, 0.0))
        f.m3 = projection * look_at_lh(light, light + float3(1.0, -1.0, -1.0), float3(0.0, 1.0, 0.0))
    } elif (settings.kind == 2) {
        // Fit each camera-frustum interval conservatively, not four copies of one map.
        var near = 0.1
        for (i in 0..4) {
            let far = f.splits[i]
            let center = eye + forward * (near + far) * 0.5
            let extent = sqrt(far * far * (1.0 + aspect * aspect) / 3.0 + (far - near) * (far - near) * 0.25)
            let view = look_at_lh(center + normalize(light) * 60.0, center, float3(0.0, 1.0, 0.0))
            let m = ortho(extent, 0.1, 160.0) * view
            if (i == 0) { f.m0 = m } elif (i == 1) { f.m1 = m } elif (i == 2) { f.m2 = m } else { f.m3 = m }
            near = far
        }
    } else { f.m0 = ortho(25.0, 0.1, 100.0) * look_at_lh(normalize(light) * 40.0, float3(0.0), float3(0.0, 1.0, 0.0)) }
    return f
}
def scene(command : SDL_GPUCommandBuffer?; pass_ : SDL_GPURenderPass?; var r : Resources; vp : float4x4; time : float; frame : shaders::ShadowFrame; shading : bool) : SdlStatus {
    SDL_BindGPUGraphicsPipeline(pass_, shading ? r.lighting : r.depth_pipeline)
    if (shading) { var images <- array(r.maps[0], r.maps[1], r.maps[2], r.maps[3]); bind_images(pass_, images, r.sampler) |> sdl_try }
    for (i in 0..(int(frame.light.w) == 3 ? 4 : 8)) {
        var model = identity_matrix()
        var f = frame; f.tint = float4(0.75, 0.75, 0.75, 0.0)
        if (i == 1) { model = model_matrix(float3(7.0, 2.2, 0.0), float3(2.2), -time * 0.25) }
        if (i == 2) { model = model_matrix(float3(-7.0, 1.2, 0.0), float3(1.2), time * 0.25) }
        if (i == 3) { model = model_matrix(float3(0.0, 5.0, 0.0), float3(1.0), time * 0.25) }
        if (i >= 4) { model = model_matrix(float3(float((i - 4) % 2) * 24.0 - 12.0, 0.0, float((i - 4) / 2) * 20.0 - 5.0), float3(0.8), float(i)) }
        push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model, vp = vp)) |> sdl_try
        push_gpu_dsl_fragment_uniform(command, 0u, f) |> sdl_try
        if (i == 0) { draw_geometry(pass_, r.plane) |> sdl_try }
        elif (i == 1) { draw_geometry(pass_, r.bunny) |> sdl_try }
        elif (i == 2) { draw_geometry(pass_, r.cube) |> sdl_try }
        elif (i == 3) { draw_geometry(pass_, r.hollow) |> sdl_try }
        else { draw_geometry(pass_, r.tree) |> sdl_try }
    }
    return sdl_ok()
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    replace_depth(device, r.depth, r.size, width, height) |> sdl_try
    let frame = matrices(time, settings, float(width) / float(height))
    let count = settings.kind == 1 || settings.kind == 2 ? 4 : 1
    for (i in 0..count) {
        var vp = frame.m0
        if (i == 1) { vp = frame.m1 } elif (i == 2) { vp = frame.m2 } elif (i == 3) { vp = frame.m3 }
        let colors <- array(attachment(r.maps[i], float4(1.0)))
        let depth = depth_attachment(r.shadow_depth)
        with_native_gpu_render_pass(command, colors, depth) $(var pass_ : SDL_GPURenderPass?&) {
            return scene(command, pass_, r, vp, time, frame, false)
        } |> sdl_try
        if (settings.filter >= 3) {
            push_gpu_dsl_fragment_uniform(command, 0u, shaders::Filter(step = float4(1.0 / 512.0, 0.0, 0.0, 0.0))) |> sdl_try
            var source <- array(r.maps[i])
            fullscreen(command, r.blur, r.scratch, source, r.linear_sampler) |> sdl_try
            push_gpu_dsl_fragment_uniform(command, 0u, shaders::Filter(step = float4(0.0, 1.0 / 512.0, 0.0, 0.0))) |> sdl_try
            source[0] = r.scratch
            fullscreen(command, r.blur, r.maps[i], source, r.linear_sampler) |> sdl_try
        }
    }
    if (settings.debug) { var source <- array(r.maps[0]); return fullscreen(command, r.preview, output, source, r.sampler) }
    let vp = camera_matrix(width, height, frame.eye.xyz, float3(0.0, 2.0, 0.0))
    let colors <- array(attachment(output, float4(0.04, 0.05, 0.07, 1.0)))
    let depth = depth_attachment(r.depth)
    return with_native_gpu_render_pass(command, colors, depth) $(var pass_ : SDL_GPURenderPass?&) { return scene(command, pass_, r, vp, time, frame, true) }
}
def run(device : SDL_GPUDevice?; window : SDL_Window?; simple, smoke : bool) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var settings = Settings(kind = simple ? 3 : 0)
        var running = true; var paused = false; var time = 0.0; var previous = SDL_GetTicks(); var frames = 0
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) { running = false }
                match (event) {
                    if (SdlEvent(key_down = $v(k))) { if (!k.repeat) {
                        if (k.keycode == SDLK_L && !simple) { settings.kind = (settings.kind + 1) % 3 }
                        elif (k.keycode == SDLK_F) { settings.filter = (settings.filter + 1) % (simple ? 2 : 5) }
                        elif (k.keycode == SDLK_Z && !simple) { settings.linear_depth = !settings.linear_depth }
                        elif (k.keycode == SDLK_S) { settings.shadows = !settings.shadows }
                        elif (k.keycode == SDLK_D) { settings.debug = !settings.debug }
                        elif (k.keycode == SDLK_SPACE) { paused = !paused }
                    } } if (_) {}
                }
            }
            if (!running) { break }
            let now = SDL_GetTicks(); if (!paused) { time += float(now - previous) * 0.001 }; previous = now
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            set_title(window, "Shadow maps | L: light {settings.kind} | F: filter {settings.filter} | Z: linear {settings.linear_depth} | S: shadows | D: map | Space: pause") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
