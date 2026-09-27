options gen2
module shadowvolumes_app shared public
require stencil_support public
require ./shaders/stencil_shaders.das as shaders
require dassdl3/sdl3_shader_uniforms
require shadowvolumes_geometry public
require dassdl3/sdl3_events
require dassdl3/sdl3_window_boost
require daslib/defer
require daslib/match
let VOLUME_CAPACITY = 65536u
struct VolumeResources {
    cube, plane, volume : GeometryBuffers
    mesh : Geometry
    transfer : SDL_GPUTransferBuffer?
    ambient, lit, zpass, zfail, debug : SDL_GPUGraphicsPipeline?
    depth_format : SDL_GPUTextureFormat
}
def release(device : SDL_GPUDevice?; var r : VolumeResources) {
    release(device, r.cube)
    release(device, r.plane)
    release(device, r.volume)
    if (r.transfer != null) {
        SDL_ReleaseGPUTransferBuffer(device, r.transfer)
    }
    for (p in fixed_array(r.ambient, r.lit, r.zpass, r.zfail, r.debug)) {
        if (p != null) {
            SDL_ReleaseGPUGraphicsPipeline(device, p)
        }
    }
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : VolumeResources) : SdlStatus>) : SdlStatus {
    var r : VolumeResources
    defer() {
        release(device, r)
    }
    var loaded_depth_format = stencil_format(device) |> sdl_try
    r.depth_format = loaded_depth_format
    r.mesh <- cube_geometry()
    let plane <- plane_geometry(6.0)
    var loaded_cube = upload_geometry(device, r.mesh) |> sdl_try
    r.cube = loaded_cube
    var loaded_plane = upload_geometry(device, plane) |> sdl_try
    r.plane = loaded_plane
    var vb = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_VERTEX, size = VOLUME_CAPACITY)) |> sdl_try
    r.volume.vb = vb
    var transfer = create_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = VOLUME_CAPACITY)) |> sdl_try
    r.transfer = transfer
    var state = SDL_GPUDepthStencilState(enable_depth_test = true, enable_depth_write = true, compare_op = SDL_GPUCompareOp.COMPAREOP_LESS)
    var p = scene_pipeline(device, format, r.depth_format, state) |> sdl_try
    r.ambient = p
    state.enable_depth_write = false
    state.compare_op = SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL
    p = scene_pipeline(device, format, r.depth_format, state, 1) |> sdl_try
    r.debug = p
    state.enable_stencil_test = true
    state.compare_mask = 255u8
    state.write_mask = 0u8
    state.front_stencil_state = keep_stencil(SDL_GPUCompareOp.COMPAREOP_EQUAL)
    state.back_stencil_state = state.front_stencil_state
    p = scene_pipeline(device, format, r.depth_format, state, 2) |> sdl_try
    r.lit = p
    // A cap coincident with the receiver must not count as entering the volume.
    state.compare_op = SDL_GPUCompareOp.COMPAREOP_LESS
    state.write_mask = 255u8
    state.front_stencil_state = keep_stencil()
    state.back_stencil_state = keep_stencil()
    state.front_stencil_state.pass_op = SDL_GPUStencilOp.STENCILOP_INCREMENT_AND_WRAP
    state.back_stencil_state.pass_op = SDL_GPUStencilOp.STENCILOP_DECREMENT_AND_WRAP
    p = scene_pipeline(device, format, r.depth_format, state, 0, false) |> sdl_try
    r.zpass = p
    state.front_stencil_state = keep_stencil()
    state.back_stencil_state = keep_stencil()
    state.front_stencil_state.depth_fail_op = SDL_GPUStencilOp.STENCILOP_DECREMENT_AND_WRAP
    state.back_stencil_state.depth_fail_op = SDL_GPUStencilOp.STENCILOP_INCREMENT_AND_WRAP
    p = scene_pipeline(device, format, r.depth_format, state, 0, false) |> sdl_try
    r.zfail = p
    return body(r)
}
def scene(command : SDL_GPUCommandBuffer?; pass_ : SDL_GPURenderPass?; var r : VolumeResources; pipeline : SDL_GPUGraphicsPipeline?; model, vp : float4x4; light : float3; ambient, diffuse : float) : SdlStatus {
    object(command, pass_, pipeline, r.plane, identity_matrix(), vp, float4(0.6, 0.65, 0.7, 1.0), light, ambient, diffuse) |> sdl_try
    return object(command, pass_, pipeline, r.cube, model, vp, float4(0.95, 0.3, 0.1, 1.0), light, ambient, diffuse)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : VolumeResources; var color, depth : SDL_GPUTexture?; width, height : uint; time : float; zfail : bool = true; edges : bool = true; inside : bool = false; debug : bool = false; effect : bool = true) : SdlStatus {
    let light = float3(-3.0 + sin(time), 6.0, -2.0)
    let model = model_matrix(float3(0.0, 1.05, 0.0), float3(0.8), time * 0.4)
    let vp = camera_matrix(width, height, inside ? float3(1.2, 0.25, 0.8) : float3(5.0, 4.5, -7.0), float3(0.0, 0.6, 0.0))
    let volume <- shadow_volume(r.mesh, model, light, edges)
    if (uint(length(volume.vertices)) * 4u > VOLUME_CAPACITY) {
        return err(SdlError(operation = "shadow volume", message = "Volume exceeds upload capacity"), type<SdlUnit>)
    }
    upload_floats(device, command, r.volume.vb, r.transfer, VOLUME_CAPACITY, volume.vertices) |> sdl_try
    r.volume.count = uint(length(volume.vertices) / 8)
    let targets <- array(SDL_GPUColorTargetInfo(texture = color, load_op = SDL_GPULoadOp.LOADOP_CLEAR, store_op = SDL_GPUStoreOp.STOREOP_STORE, clear_color = SDL_FColor(r = 0.08, g = 0.1, b = 0.15, a = 1.0)))
    return with_native_gpu_render_pass(command, targets, stencil_attachment(depth, true)) $(var pass_) {
        scene(command, pass_, r, r.ambient, model, vp, light, 0.2, 0.0) |> sdl_try
        SDL_SetGPUStencilReference(pass_, 0u)
        if (effect) {
            let transform = shaders::SceneTransform(model = identity_matrix(), view_projection = vp)
            let lighting = shaders::SceneLighting(color = float4(0.1, 0.8, 0.2, 0.15), light = float4(light, 1.0), shade = float4(1.0, 0.0, 0.0, 0.0))
            push_gpu_dsl_vertex_uniform(command, 0u, transform) |> sdl_try
            push_gpu_dsl_fragment_uniform(command, 0u, lighting) |> sdl_try
            SDL_BindGPUGraphicsPipeline(pass_, zfail ? r.zfail : r.zpass)
            let buffers <- array(SDL_GPUBufferBinding(buffer = r.volume.vb))
            sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, buffers), "SDL_BindGPUVertexBuffersArray") |> sdl_try
            SDL_DrawGPUPrimitives(pass_, r.volume.count, 1u, 0u, 0u)
        }
        scene(command, pass_, r, r.lit, model, vp, light, 0.0, 0.8) |> sdl_try
        if (debug) {
            let transform = shaders::SceneTransform(model = identity_matrix(), view_projection = vp)
            let lighting = shaders::SceneLighting(color = float4(0.1, 0.8, 0.2, 0.15), light = float4(light, 1.0), shade = float4(1.0, 0.0, 0.0, 0.0))
            push_gpu_dsl_vertex_uniform(command, 0u, transform) |> sdl_try
            push_gpu_dsl_fragment_uniform(command, 0u, lighting) |> sdl_try
            SDL_BindGPUGraphicsPipeline(pass_, r.debug)
            let buffers <- array(SDL_GPUBufferBinding(buffer = r.volume.vb))
            sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, buffers), "SDL_BindGPUVertexBuffersArray") |> sdl_try
            SDL_DrawGPUPrimitives(pass_, r.volume.count, 1u, 0u, 0u)
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
        var zfail = true
        var edges = true
        var inside = false
        var debug = false
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
                            if (k.keycode == SDLK_Z) {
                                zfail = !zfail
                            } elif (k.keycode == SDLK_E) {
                                edges = !edges
                            } elif (k.keycode == SDLK_C) {
                                inside = !inside
                            } elif (k.keycode == SDLK_V) {
                                debug = !debug
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
                return draw(device, command, r, color, depth, width, height, time, zfail, edges, inside, debug)
            }  |> sdl_try
            let method = zfail ? "depth-fail" : "depth-pass"
            let construction = edges ? "silhouette" : "face prisms"
            set_title(window, "Shadow volumes: {method}, {construction} | Z/E: algorithm | C: camera | V: volumes | Space/R/Esc") |> sdl_try
            SDL_Delay(16u)
        }
        return sdl_ok()
    }
}
