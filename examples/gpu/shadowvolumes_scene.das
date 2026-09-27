options gen2
module shadowvolumes_scene shared public
require stencil_scene_support public
require dassdl3/sdl3_shader_uniforms
require shadowvolumes_topology public
require ./shaders/stencil_scene_shaders.das as rich
require ./shaders/stencil_shaders.das as volume_shaders
require dassdl3/sdl3_gpu_sampler_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_window_boost
require daslib/defer
require daslib/match
struct Settings {
    lights : int = 1
    second_scene, alternate_pattern, cubes, debug, inside : bool
    zfail : bool = true
    silhouette : bool = true
    shadows, textures, specular : bool = true
}
struct Instance {
    mesh : int
    model : float4x4
    color : float4 = float4(0.68, 0.65, 0.6, 1.0)
    textured : bool
}
struct Resources {
    meshes : array<ClosedMesh>
    buffers : array<GeometryBuffers>
    floor, quad : GeometryBuffers
    stone, figure, flare_texture : SDL_GPUTexture?
    sampler : SDL_GPUSampler?
    ambient, lit, flare, zpass, zfail, debug : SDL_GPUGraphicsPipeline?
    volume : SDL_GPUBuffer?
    transfer : SDL_GPUTransferBuffer?
    capacity : uint
    depth_format : SDL_GPUTextureFormat
}
def release(device : SDL_GPUDevice?; var r : Resources) {
    for (mesh in r.buffers) { release(device, mesh) }
    release(device, r.floor); release(device, r.quad)
    for (p in fixed_array(r.ambient, r.lit, r.flare, r.zpass, r.zfail, r.debug)) { if (p != null) { SDL_ReleaseGPUGraphicsPipeline(device, p) } }
    for (t in fixed_array(r.stone, r.figure, r.flare_texture)) { if (t != null) { SDL_ReleaseGPUTexture(device, t) } }
    if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
    if (r.volume != null) { SDL_ReleaseGPUBuffer(device, r.volume) }
    if (r.transfer != null) { SDL_ReleaseGPUTransferBuffer(device, r.transfer) }
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r : Resources
    defer() { release(device, r) }
    let depth_format = stencil_format(device) |> sdl_try; r.depth_format = depth_format
    var cube <- closed_cube(); emplace(r.meshes, cube)
    for (name in fixed_array("bunny_decimated", "column", "platform")) {
        var mesh <- load_closed_mesh(name) |> sdl_try
        emplace(r.meshes, mesh)
    }
    for (mesh in r.meshes) {
        var buffer = upload_geometry(device, mesh.geometry) |> sdl_try; push(r.buffers, buffer)
    }
    var floor <- plane_geometry(100.0)
    for (i in 0 .. length(floor.vertices) / 8) {
        floor.vertices[i * 8 + 6] = floor.vertices[i * 8] / 8.0; floor.vertices[i * 8 + 7] = floor.vertices[i * 8 + 2] / 8.0
    }
    var quad <- plane_geometry(1.0)
    for (i in 0 .. length(quad.vertices) / 8) {
        quad.vertices[i * 8 + 6] = (quad.vertices[i * 8] + 1.0) * 0.5; quad.vertices[i * 8 + 7] = (quad.vertices[i * 8 + 2] + 1.0) * 0.5
    }
    var buffer = upload_geometry(device, floor) |> sdl_try; r.floor = buffer
    buffer = upload_geometry(device, quad) |> sdl_try; r.quad = buffer
    var tex = SDL_CreateGPUTextureRef(device, gpu_texture(512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) |> mip_levels(10u)); r.stone = tex
    if (tex == null) { return err(sdl_error("SDL_CreateGPUTexture"), type<SdlUnit>) }
    tex = SDL_CreateGPUTextureRef(device, gpu_texture(512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) |> mip_levels(10u)); r.figure = tex
    if (tex == null) { return err(sdl_error("SDL_CreateGPUTexture"), type<SdlUnit>) }
    tex = texture(device, 512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.flare_texture = tex
    upload_texture(device, r.stone, "fieldstone-rgba.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
    upload_texture(device, r.figure, "figure-rgba.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
    upload_texture(device, r.flare_texture, "flare.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
    sdl_scope() {
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        SDL_GenerateMipmapsForGPUTexture(command, r.stone); SDL_GenerateMipmapsForGPUTexture(command, r.figure)
        return native_gpu_submit(command)
    } |> sdl_try
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR, SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT))
    if (r.sampler == null) { return err(sdl_error("SDL_CreateGPUSampler"), type<SdlUnit>) }
    var state = SDL_GPUDepthStencilState(enable_depth_test = true, enable_depth_write = true, compare_op = SDL_GPUCompareOp.COMPAREOP_LESS)
    var p = rich_pipeline(device, format, r.depth_format, state) |> sdl_try; r.ambient = p
    state.enable_depth_write = false; state.compare_op = SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL
    p = rich_pipeline(device, format, r.depth_format, state, 4) |> sdl_try; r.flare = p
    p = scene_pipeline(device, format, r.depth_format, state, 1) |> sdl_try; r.debug = p
    state.enable_stencil_test = true; state.compare_mask = 255u8; state.write_mask = 0u8
    state.front_stencil_state = keep_stencil(SDL_GPUCompareOp.COMPAREOP_EQUAL); state.back_stencil_state = state.front_stencil_state
    p = rich_pipeline(device, format, r.depth_format, state, 2) |> sdl_try; r.lit = p
    state.compare_op = SDL_GPUCompareOp.COMPAREOP_LESS; state.write_mask = 255u8
    state.front_stencil_state = keep_stencil(); state.back_stencil_state = keep_stencil()
    state.front_stencil_state.pass_op = SDL_GPUStencilOp.STENCILOP_INCREMENT_AND_WRAP
    state.back_stencil_state.pass_op = SDL_GPUStencilOp.STENCILOP_DECREMENT_AND_WRAP
    p = scene_pipeline(device, format, r.depth_format, state, 0, false) |> sdl_try; r.zpass = p
    state.front_stencil_state = keep_stencil(); state.back_stencil_state = keep_stencil()
    state.front_stencil_state.depth_fail_op = SDL_GPUStencilOp.STENCILOP_DECREMENT_AND_WRAP
    state.back_stencil_state.depth_fail_op = SDL_GPUStencilOp.STENCILOP_INCREMENT_AND_WRAP
    p = scene_pipeline(device, format, r.depth_format, state, 0, false) |> sdl_try; r.zfail = p
    return body(r)
}
def instances(time : float; settings : Settings) : array<Instance> {
    var objects : array<Instance>
    let bunny = settings.cubes ? 0 : 1
    if (settings.second_scene) {
        for (z in -1 .. 2) {
            for (x in -1 .. 2) { push(objects, Instance(mesh = bunny, model = model_matrix(float3(float(x) * 20.0, settings.cubes ? 5.0 : 0.0, float(z) * 20.0), float3(5.0), PI), textured = settings.cubes)) }
        }
    } else {
        push(objects, Instance(mesh = bunny, model = model_matrix(float3(0.0, 10.0, 0.0), float3(5.0), 4.0 - time * 0.7), textured = settings.cubes))
        for (level in 0 .. 2) {
            for (i in 0 .. 9) {
                let a = float(i) * 2.0 + 13.0 + time * 1.1
                push(objects, Instance(mesh = 0, model = model_matrix(float3(sin(a) * 13.0, level == 0 ? 6.0 : 22.0, cos(a) * 13.0), float3(1.0)), textured = true))
            }
        }
        for (i in 0 .. 4) { push(objects, Instance(mesh = 2, model = model_matrix(float3(i % 2 == 0 ? -16.0 : 16.0, 3.3, i / 2 == 0 ? -16.0 : 16.0), float3(1.5), 1.57), color = float4(0.25, 0.25, 0.25, 1.0))) }
        push(objects, Instance(mesh = 3, model = model_matrix(float3(0.0), float3(24.0)), textured = true))
        // Rotation by pi around X preserves winding; the upper slab faces down.
        push(objects, Instance(mesh = 3, model = model_matrix(float3(0.0, 28.2, 0.0), float3(21.0, -21.0, -21.0)), textured = true))
    }
    return <- objects
}
def scene_lights(time : float; eye : float3; settings : Settings) : rich::Lighting {
    var l = rich::Lighting(coefficients = float4(0.05, 0.8, 25.0, 50.0), fog = float4(0.0, 0.0, 0.0, 0.0055), eye = float4(eye, 1.0), color = float4(1.0), controls = float4(1.0, 0.0, 0.0, 1.0), material = float4(0.0, 0.0, settings.specular ? 1.0 : 0.0, 0.0))
    l.colors = fixed_array(float4(1.0, 0.7, 0.2, 1.0), float4(0.7, 0.2, 1.0, 1.0), float4(0.2, 1.0, 0.7, 1.0), float4(1.0, 0.4, 0.2, 1.0), float4(0.7, 0.7, 0.7, 1.0))
    for (i in 0 .. settings.lights) {
        let a = settings.alternate_pattern ? float(i) * 2.0 / float(settings.lights) + time * 1.3 + PI : 2.0 * PI / float(settings.lights) * float(i) + time * 1.1 + 3.0
        let radius = settings.alternate_pattern ? 40.0 : 20.0
        l.positions[i] = float4(cos(a) * radius, 20.0, sin(a) * radius, 20.0)
    }
    return l
}
def draw_scene(command : SDL_GPUCommandBuffer?; pass_ : SDL_GPURenderPass?; var r : Resources; pipeline : SDL_GPUGraphicsPipeline?; objects : array<Instance>; vp : float4x4; light : rich::Lighting; settings : Settings) : SdlStatus {
    var l = light
    l.color = float4(0.7, 0.65, 0.6, 1.0); l.material.x = settings.textures ? 1.0 : 0.0
    rich_object(command, pass_, pipeline, r.floor, identity_matrix(), vp, l, settings.second_scene ? r.figure : r.stone, r.sampler) |> sdl_try
    for (obj in objects) {
        l.color = obj.color; l.material.x = obj.textured && settings.textures ? 1.0 : 0.0
        rich_object(command, pass_, pipeline, r.buffers[obj.mesh], obj.model, vp, l, r.figure, r.sampler) |> sdl_try
    }
    return sdl_ok()
}
def upload_volume(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; values : array<float>) : SdlStatus {
    let bytes = uint(length(values)) * 4u
    if (bytes > 67108864u) { return err(SdlError(operation = "shadow volume", message = "Scene exceeds 64 MiB volume limit"), type<SdlUnit>) }
    if (r.capacity < bytes) {
        let capacity = max(1048576u, bytes)
        var vb = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_VERTEX, size = capacity)) |> sdl_try
        var transfer_result = create_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = capacity))
        if (is_err(transfer_result)) { SDL_ReleaseGPUBuffer(device, vb); return err(unwrap_err(transfer_result), type<SdlUnit>) }
        if (r.volume != null) { SDL_ReleaseGPUBuffer(device, r.volume) }
        if (r.transfer != null) { SDL_ReleaseGPUTransferBuffer(device, r.transfer) }
        r.volume = vb; r.transfer = transfer_result._value; r.capacity = capacity
    }
    return upload_floats(device, command, r.volume, r.transfer, r.capacity, values)
}
def draw_volume(command : SDL_GPUCommandBuffer?; pass_ : SDL_GPURenderPass?; var r : Resources; pipeline : SDL_GPUGraphicsPipeline?; vp : float4x4; count : uint) : SdlStatus {
    push_gpu_dsl_vertex_uniform(command, 0u, volume_shaders::SceneTransform(model = identity_matrix(), view_projection = vp)) |> sdl_try
    push_gpu_dsl_fragment_uniform(command, 0u, volume_shaders::SceneLighting(color = float4(0.1, 0.8, 0.2, 0.1), shade = float4(1.0, 0.0, 0.0, 0.0))) |> sdl_try
    SDL_BindGPUGraphicsPipeline(pass_, pipeline)
    let bindings <- array(SDL_GPUBufferBinding(buffer = r.volume))
    sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, bindings), "volume vertices") |> sdl_try
    SDL_DrawGPUPrimitives(pass_, count, 1u, 0u, 0u)
    return sdl_ok()
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var color, depth : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    let eye = settings.inside ? float3(0.0, 8.0, -12.0) : float3(3.0, 20.0, -58.0)
    let at = settings.inside ? float3(0.0, 12.0, 0.0) : float3(0.0, 5.0, 0.0)
    var projection : float4x4
    let q = 500.0 / 499.9
    projection[0] = float4(1.7320508 * float(height) / float(width), 0.0, 0.0, 0.0)
    projection[1] = float4(0.0, 1.7320508, 0.0, 0.0); projection[2] = float4(0.0, 0.0, q, 1.0); projection[3] = float4(0.0, 0.0, -0.1 * q, 0.0)
    let vp = projection * look_at_lh(eye, at, float3(0.0, 1.0, 0.0))
    let objects <- instances(time, settings)
    let light = scene_lights(time, eye, settings)
    var targets <- array(SDL_GPUColorTargetInfo(texture = color, load_op = SDL_GPULoadOp.LOADOP_CLEAR, store_op = SDL_GPUStoreOp.STOREOP_STORE, clear_color = SDL_FColor(a = 1.0)))
    var ds = stencil_attachment(depth, true)
    with_native_gpu_render_pass(command, targets, ds) $(var pass_ : SDL_GPURenderPass?&) {
        return draw_scene(command, pass_, r, r.ambient, objects, vp, light, settings)
    } |> sdl_try
    targets[0].load_op = SDL_GPULoadOp.LOADOP_LOAD
    ds = stencil_attachment(depth, false); ds.stencil_load_op = SDL_GPULoadOp.LOADOP_CLEAR
    for (i in 0 .. settings.lights) {
        var vertices : array<float>
        if (settings.shadows || settings.debug) {
            for (obj in objects) { append_volume(vertices, r.meshes[obj.mesh], obj.model, light.positions[i].xyz, settings.silhouette, 180.0) }
            upload_volume(device, command, r, vertices) |> sdl_try
        }
        with_native_gpu_render_pass(command, targets, ds) $(var pass_ : SDL_GPURenderPass?&) {
            SDL_SetGPUStencilReference(pass_, 0u)
            if (settings.shadows) { draw_volume(command, pass_, r, settings.zfail ? r.zfail : r.zpass, vp, uint(length(vertices) / 8)) |> sdl_try }
            var single = light; single.controls = float4(0.0, 1.0, float(i), 1.0)
            draw_scene(command, pass_, r, r.lit, objects, vp, single, settings) |> sdl_try
            if (settings.debug) { draw_volume(command, pass_, r, r.debug, vp, uint(length(vertices) / 8)) |> sdl_try }
            return sdl_ok()
        } |> sdl_try
    }
    ds.stencil_load_op = SDL_GPULoadOp.LOADOP_LOAD
    return with_native_gpu_render_pass(command, targets, ds) $(var pass_) {
        let forward = normalize(at - eye); let right = normalize(cross(float3(0.0, 1.0, 0.0), forward)); let up = cross(forward, right)
        for (i in 0 .. settings.lights) {
            var billboard = identity_matrix(); billboard[0] = float4(right, 0.0); billboard[1] = float4(forward, 0.0); billboard[2] = float4(up, 0.0); billboard[3] = float4(light.positions[i].xyz, 1.0)
            var flare = light; flare.material.y = 1.0; flare.color = light.colors[i]
            rich_object(command, pass_, r.flare, r.quad, billboard, vp, flare, r.flare_texture, r.sampler) |> sdl_try
        }
        return sdl_ok()
    }
}
def run(device : SDL_GPUDevice?; window : SDL_Window?) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var depth : SDL_GPUTexture?; var size = uint2(0u)
        defer() { if (depth != null) { SDL_ReleaseGPUTexture(device, depth) } }
        var settings = Settings(); var running = true; var paused = false; var time = 0.0; var previous = SDL_GetTicks()
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) { running = false }
                match (event) {
                    if (SdlEvent(key_down = $v(k))) {
                        if (!k.repeat) {
                            if (k.keycode == SDLK_TAB) { settings.second_scene = !settings.second_scene }
                            elif (k.keycode == SDLK_L) { settings.lights = settings.lights % 5 + 1 }
                            elif (k.keycode == SDLK_P) { settings.alternate_pattern = !settings.alternate_pattern }
                            elif (k.keycode == SDLK_M) { settings.cubes = !settings.cubes }
                            elif (k.keycode == SDLK_Z) { settings.zfail = !settings.zfail }
                            elif (k.keycode == SDLK_E) { settings.silhouette = !settings.silhouette }
                            elif (k.keycode == SDLK_C) { settings.inside = !settings.inside }
                            elif (k.keycode == SDLK_V) { settings.debug = !settings.debug }
                            elif (k.keycode == SDLK_S) { settings.shadows = !settings.shadows }
                            elif (k.keycode == SDLK_SPACE) { paused = !paused }
                            elif (k.keycode == SDLK_R) { time = 0.0 }
                        }
                    } if (_) {}
                }
            }
            if (!running) { break }
            let now = SDL_GetTicks(); if (!paused) { time += min(0.1, float(now - previous) * 0.001) }; previous = now
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var color : SDL_GPUTexture?; width, height : uint) {
                replace_stencil(device, depth, size, width, height, r.depth_format) |> sdl_try
                return draw(device, command, r, color, depth, width, height, time, settings)
            } |> sdl_try
            set_title(window, "Shadow volumes | scene {settings.second_scene?1:0} | {settings.lights} lights | {settings.zfail?"z-fail":"z-pass"} | Tab/L/P/M/Z/E/C/V/S/Space") |> sdl_try
            SDL_Delay(1u)
        }
        return sdl_ok()
    }
}
