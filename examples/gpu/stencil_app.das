options gen2
module stencil_app shared public
require stencil_scene_support public
require ./shaders/stencil_scene_shaders.das as rich
require dassdl3/sdl3_gpu_sampler_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_window_boost
require daslib/defer
require daslib/match
struct StencilResources {
    cube, plane, bunny, column, flare_quad : GeometryBuffers
    normal, mark, reflection, floor, project, lit, unmasked, flare : SDL_GPUGraphicsPipeline?
    stone, figure, flare_texture : SDL_GPUTexture?
    sampler : SDL_GPUSampler?
    depth_format : SDL_GPUTextureFormat
}
struct SceneSettings {
    lights : int = 4
    reflection : float = 0.8
    textures : bool = true
    specular : bool = true
}
def release(device : SDL_GPUDevice?; var r : StencilResources) {
    release(device, r.cube); release(device, r.plane); release(device, r.bunny)
    release(device, r.column); release(device, r.flare_quad)
    for (p in fixed_array(r.normal, r.mark, r.reflection, r.floor, r.project, r.lit, r.unmasked, r.flare)) {
        if (p != null) { SDL_ReleaseGPUGraphicsPipeline(device, p) }
    }
    for (t in fixed_array(r.stone, r.figure, r.flare_texture)) {
        if (t != null) { SDL_ReleaseGPUTexture(device, t) }
    }
    if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : StencilResources) : SdlStatus>) : SdlStatus {
    var r : StencilResources
    defer() { release(device, r) }
    let depth_format = stencil_format(device) |> sdl_try
    r.depth_format = depth_format
    var cube <- cube_geometry()
    // Each cube face has its own six vertices, with full UV coverage.
    let uv = fixed_array(float2(0.0, 0.0), float2(0.0, 1.0), float2(1.0, 1.0), float2(0.0, 0.0), float2(1.0, 1.0), float2(1.0, 0.0))
    for (i in 0 .. length(cube.vertices) / 8) {
        cube.vertices[i * 8 + 6] = uv[i % 6].x; cube.vertices[i * 8 + 7] = uv[i % 6].y
    }
    var plane <- plane_geometry(20.0)
    for (i in 0 .. length(plane.vertices) / 8) {
        plane.vertices[i * 8 + 6] = (plane.vertices[i * 8 + 2] + 20.0) / 8.0
        plane.vertices[i * 8 + 7] = (20.0 - plane.vertices[i * 8]) / 8.0
    }
    var quad <- plane_geometry(1.0)
    for (i in 0 .. length(quad.vertices) / 8) {
        quad.vertices[i * 8 + 6] = (quad.vertices[i * 8] + 1.0) * 0.5
        quad.vertices[i * 8 + 7] = (quad.vertices[i * 8 + 2] + 1.0) * 0.5
    }
    let bunny <- load_geometry("{SDL_GetBasePath()}assets/meshes/bunny.msh") |> sdl_try
    let column <- load_geometry("{SDL_GetBasePath()}assets/bgfx/column.msh") |> sdl_try
    var mesh = upload_geometry(device, cube) |> sdl_try; r.cube = mesh
    mesh = upload_geometry(device, plane) |> sdl_try; r.plane = mesh
    mesh = upload_geometry(device, quad) |> sdl_try; r.flare_quad = mesh
    mesh = upload_geometry(device, bunny) |> sdl_try; r.bunny = mesh
    mesh = upload_geometry(device, column) |> sdl_try; r.column = mesh
    var tex = SDL_CreateGPUTextureRef(device, gpu_texture(512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) |> mip_levels(10u)); r.stone = tex
    if (tex == null) { return err(sdl_error("SDL_CreateGPUTexture"), type<SdlUnit>) }
    tex = texture(device, 512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.figure = tex
    tex = texture(device, 512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.flare_texture = tex
    upload_texture(device, r.stone, "fieldstone-rgba.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
    upload_texture(device, r.figure, "figure-rgba.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
    upload_texture(device, r.flare_texture, "flare.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
    sdl_scope() {
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        SDL_GenerateMipmapsForGPUTexture(command, r.stone)
        return native_gpu_submit(command)
    } |> sdl_try
    var sampling = gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR, SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT)
    sampling.mipmap_mode = SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR
    sampling.max_lod = 9.0
    r.sampler = SDL_CreateGPUSamplerRef(device, sampling)
    if (r.sampler == null) { return err(sdl_error("SDL_CreateGPUSampler"), type<SdlUnit>) }
    var state = SDL_GPUDepthStencilState(enable_depth_test = true, enable_depth_write = true, compare_op = SDL_GPUCompareOp.COMPAREOP_LESS)
    var p = rich_pipeline(device, format, r.depth_format, state) |> sdl_try; r.normal = p
    p = rich_pipeline(device, format, r.depth_format, state, 3) |> sdl_try; r.floor = p
    state.enable_depth_write = false
    p = rich_pipeline(device, format, r.depth_format, state, 4) |> sdl_try; r.flare = p
    state.compare_op = SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL
    p = rich_pipeline(device, format, r.depth_format, state, 2) |> sdl_try; r.unmasked = p
    state.enable_stencil_test = true; state.compare_mask = 255u8; state.write_mask = 0u8
    state.front_stencil_state = keep_stencil(SDL_GPUCompareOp.COMPAREOP_EQUAL)
    state.back_stencil_state = state.front_stencil_state
    p = rich_pipeline(device, format, r.depth_format, state, 2) |> sdl_try; r.lit = p
    state.enable_depth_write = true; state.compare_op = SDL_GPUCompareOp.COMPAREOP_LESS
    p = rich_pipeline(device, format, r.depth_format, state, 1) |> sdl_try; r.reflection = p
    var replace = keep_stencil(); replace.pass_op = SDL_GPUStencilOp.STENCILOP_REPLACE
    state.front_stencil_state = replace; state.back_stencil_state = replace
    state.write_mask = 255u8; state.enable_depth_write = false
    state.compare_op = SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL
    p = rich_pipeline(device, format, r.depth_format, state, 0, false) |> sdl_try; r.project = p
    state.enable_depth_test = false
    p = rich_pipeline(device, format, r.depth_format, state) |> sdl_try; r.mark = p
    return body(r)
}
def projection_shadow(light : float3) : float4x4 {
    // Homogeneous projection onto y=.01, immediately above the floor.
    var m : float4x4
    m[0] = float4(light.y - 0.01, 0.0, 0.0, 0.0)
    m[1] = float4(-light.x, -0.01, -light.z, -1.0)
    m[2] = float4(0.0, 0.0, light.y - 0.01, 0.0)
    m[3] = float4(light.x * 0.01, light.y * 0.01, light.z * 0.01, light.y)
    return m
}
def lights(time : float; projected : bool; settings : SceneSettings) : rich::Lighting {
    var l = rich::Lighting(coefficients = float4(0.02, 0.2, 10.0, 250.0), color = float4(0.7, 0.65, 0.6, 1.0), eye = float4(0.0, 18.0, -40.0, 1.0), controls = float4(1.0, 1.0, 0.0, float(settings.lights)), material = float4(0.0, 0.0, settings.specular ? 1.0 : 0.0, 0.0))
    l.colors = fixed_array(float4(1.0, 0.7, 0.2, 1.0), float4(0.7, 0.2, 1.0, 1.0), float4(0.2, 1.0, 0.7, 1.0), float4(1.0, 0.4, 0.2, 1.0), float4(0.7, 0.7, 0.7, 1.0))
    for (i in 0 .. 5) {
        let n = float(i)
        l.positions[i] = float4(sin(time * 1.1 + n * 0.03 + n * PI / 2.0 * 1.07) * 20.0, 8.0 + (1.0 - cos(time * 1.5 + n * 0.29 + PI / 2.0 * 1.49)) * 4.0, cos(time * 1.3 + n * 0.13 + n * PI / 2.0 * 1.79) * 20.0, projected ? 25.0 : 15.0)
    }
    return l
}
def scene(command : SDL_GPUCommandBuffer?; pass_ : SDL_GPURenderPass?; var r : StencilResources; pipeline : SDL_GPUGraphicsPipeline?; vp, transform : float4x4; time : float; projected : bool; lighting : rich::Lighting; settings : SceneSettings; include_floor : bool = false) : SdlStatus {
    var l = lighting
    l.material.x = 0.0
    let bunny = model_matrix(float3(0.0, 2.0, 0.0), float3(5.0), 1.56 - time)
    rich_object(command, pass_, pipeline, r.bunny, transform * bunny, vp, l, r.stone, r.sampler) |> sdl_try
    if (projected) {
        l.material.x = settings.textures ? 1.0 : 0.0
        for (i in 0 .. 9) {
            let angle = float(i) * 2.0 + 13.0 - time
            let cube = model_matrix(float3(sin(angle) * 13.0, 4.0, cos(angle) * 13.0), float3(1.0), time)
            rich_object(command, pass_, pipeline, r.cube, transform * cube, vp, l, r.figure, r.sampler) |> sdl_try
        }
    } else {
        for (i in 0 .. 4) {
            let column = model_matrix(float3(i % 2 == 0 ? -14.0 : 14.0, 0.0, i / 2 == 0 ? -14.0 : 14.0), float3(1.0))
            rich_object(command, pass_, pipeline, r.column, transform * column, vp, l, r.stone, r.sampler) |> sdl_try
        }
    }
    if (include_floor) {
        l.material.x = settings.textures ? 1.0 : 0.0
        rich_object(command, pass_, pipeline, r.plane, identity_matrix(), vp, l, r.stone, r.sampler) |> sdl_try
    }
    return sdl_ok()
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : StencilResources; var color, depth : SDL_GPUTexture?; width, height : uint; time : float; projected : bool; effect : bool = true; settings : SceneSettings = SceneSettings()) : SdlStatus {
    let eye = float3(0.0, 18.0, -40.0)
    let vp = camera_matrix(width, height, eye, float3(0.0, 3.4, 0.0))
    let identity = identity_matrix()
    var l = lights(time, projected, settings)
    var targets <- array(SDL_GPUColorTargetInfo(texture = color, load_op = SDL_GPULoadOp.LOADOP_CLEAR, store_op = SDL_GPUStoreOp.STOREOP_STORE, clear_color = SDL_FColor(r = 0.19, g = 0.19, b = 0.19, a = 1.0)))
    var ds = stencil_attachment(depth, true)
    with_native_gpu_render_pass(command, targets, ds) $(var pass_ : SDL_GPURenderPass?&) {
        if (!projected && effect) {
            SDL_SetGPUStencilReference(pass_, 1u)
            var mask_l = l; mask_l.material.y = 2.0
            rich_object(command, pass_, r.mark, r.plane, identity, vp, mask_l, r.stone, r.sampler) |> sdl_try
            let reflected = model_matrix(float3(0.0, 0.02, 0.0), float3(1.0, -1.0, 1.0))
            var reflected_l = l
            reflected_l.color.a = settings.reflection
            for (i in 0 .. 5) { reflected_l.positions[i].y = 0.02 - reflected_l.positions[i].y }
            scene(command, pass_, r, r.reflection, vp, reflected, time, false, reflected_l, settings) |> sdl_try
        }
        if (projected) {
            var ambient = l; ambient.controls.y = 0.0
            return scene(command, pass_, r, r.normal, vp, identity, time, true, ambient, settings, true)
        }
        var floor_l = l; floor_l.material.x = settings.textures ? 1.0 : 0.0
        rich_object(command, pass_, effect ? r.floor : r.normal, r.plane, identity, vp, floor_l, r.stone, r.sampler) |> sdl_try
        return scene(command, pass_, r, r.normal, vp, identity, time, false, l, settings)
    } |> sdl_try
    targets[0].load_op = SDL_GPULoadOp.LOADOP_LOAD
    ds = stencil_attachment(depth, false)
    if (projected) {
        for (i in 0 .. settings.lights) {
            ds.stencil_load_op = SDL_GPULoadOp.LOADOP_CLEAR
            with_native_gpu_render_pass(command, targets, ds) $(var pass_ : SDL_GPURenderPass?&) {
                if (effect) {
                    SDL_SetGPUStencilReference(pass_, 1u)
                    scene(command, pass_, r, r.project, vp, projection_shadow(l.positions[i].xyz), time, true, l, settings) |> sdl_try
                }
                SDL_SetGPUStencilReference(pass_, 0u)
                var single = l; single.controls = float4(0.0, 1.0, float(i), 1.0)
                return scene(command, pass_, r, effect ? r.lit : r.unmasked, vp, identity, time, true, single, settings, true)
            } |> sdl_try
        }
    }
    ds.stencil_load_op = SDL_GPULoadOp.LOADOP_LOAD
    return with_native_gpu_render_pass(command, targets, ds) $(var pass_ : SDL_GPURenderPass?&) {
        let forward = normalize(float3(0.0, 3.4, 0.0) - eye)
        let right = normalize(cross(float3(0.0, 1.0, 0.0), forward))
        let up = cross(forward, right)
        for (i in 0 .. settings.lights) {
            var billboard = identity
            billboard[0] = float4(right * 1.5, 0.0)
            billboard[1] = float4(forward, 0.0)
            billboard[2] = float4(up * 1.5, 0.0)
            billboard[3] = float4(l.positions[i].xyz, 1.0)
            var flare_l = l; flare_l.color = l.colors[i]; flare_l.material.y = 1.0
            rich_object(command, pass_, r.flare, r.flare_quad, billboard, vp, flare_l, r.flare_texture, r.sampler) |> sdl_try
        }
        return sdl_ok()
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var depth : SDL_GPUTexture?
        var size = uint2(0u)
        defer() {
            if (depth != null) {
                SDL_ReleaseGPUTexture(device, depth)
            }
        }
        var running = true
        var settings = SceneSettings()
        var projected = false
        var enabled = true
        var paused = false
        var time = 0.0
        var previous = SDL_GetTicks()
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) {
                    running = false
                }
                match (event) {
                    if (SdlEvent(key_down = $v(k))) {
                        if (!k.repeat) {
                            if (k.keycode == SDLK_TAB) {
                                projected = !projected
                            } elif (k.keycode == SDLK_L) {
                                settings.lights = settings.lights % 5 + 1
                            } elif (k.keycode == SDLK_UP) {
                                settings.reflection = min(1.0, settings.reflection + 0.1)
                            } elif (k.keycode == SDLK_DOWN) {
                                settings.reflection = max(0.0, settings.reflection - 0.1)
                            } elif (k.keycode == SDLK_E) {
                                enabled = !enabled
                            } elif (k.keycode == SDLK_SPACE) {
                                paused = !paused
                            } elif (k.keycode == SDLK_R) {
                                time = 0.0
                            }
                        }
                    } if (_) {
                    }
                }
            }
            if (!running) {
                break
            }
            let now = SDL_GetTicks()
            if (!paused) {
                time += min(0.1, float(now - previous) * 0.001)
            }
            previous = now
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var color : SDL_GPUTexture?; width, height : uint) {
                replace_stencil(device, depth, size, width, height, r.depth_format) |> sdl_try
                return draw(device, command, r, color, depth, width, height, time, projected, enabled, settings)
            }  |> sdl_try
            set_title(window, "Stencil: {projected?"projected shadows":"reflection"} | L: {settings.lights} lights | Up/Down: reflection {settings.reflection:.1f} | Tab/E/Space/R/Esc") |> sdl_try
            SDL_Delay(16u)
        }
        return sdl_ok()
    }
}
