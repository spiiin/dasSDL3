options gen2
module lod_app shared public
require port_geometry public
require dassdl3/sdl3_shader_uniforms
require dassdl3/sdl3_gpu_sampler_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_window_boost
require ./shaders/lod_shaders.das as shaders
require daslib/defer
require daslib/match
struct LodState {
    current : int = 0
    target : int = 0
    frame : int = 0
    transitions : bool = true
}
def choose_lod(distance : float) : int {
    return distance > 5.0 ? 2 : (distance > 2.5 ? 1 : 0)
}
def update_lod(var state = LodState(); distance : float) {
    let wanted = choose_lod(distance)
    if (!state.transitions) {
        state.current = wanted
        state.target = wanted
        state.frame = 0
        return
    }
    if (state.current == state.target) {
        state.target = wanted
    }
    if (state.current != state.target) {
        state.frame++
        if (state.frame > 32) {
            state.current = state.target
            state.frame = 0
        }
    }
}
struct LodResources {
    meshes : array<GeometryBuffers>
    leaf, bark : SDL_GPUTexture?
    sampler : SDL_GPUSampler?
    pipeline : SDL_GPUGraphicsPipeline?
}
def release(device : SDL_GPUDevice?; var r : LodResources) {
    for (mesh in r.meshes) {
        release(device, mesh)
    }
    if (r.leaf != null) {
        SDL_ReleaseGPUTexture(device, r.leaf)
    }
    if (r.bark != null) {
        SDL_ReleaseGPUTexture(device, r.bark)
    }
    if (r.sampler != null) {
        SDL_ReleaseGPUSampler(device, r.sampler)
    }
    if (r.pipeline != null) {
        SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline)
    }
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : LodResources) : SdlStatus>) : SdlStatus {
    var r : LodResources
    defer() {
        release(device, r)
    }
    for (level in 0 .. 3) {
        for (part in 1 .. 3) {
            let geometry <- load_geometry("{SDL_GetBasePath()}assets/bgfx/tree1b_lod{level}_{part}.msh") |> sdl_try
            var mesh = upload_geometry(device, geometry) |> sdl_try
            push(r.meshes, mesh)
        }
    }
    var tex = texture(device, 1024u, 1024u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try
    r.leaf = tex
    tex = texture(device, 512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try
    r.bark = tex
    upload_texture(device, r.leaf, "leafs1.rgba8", 1024u, 1024u, 4u, 1u) |> sdl_try
    upload_texture(device, r.bark, "bark1.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR, SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT))
    if (r.sampler == null) {
        return err(sdl_error("SDL_CreateGPUSampler"), type<SdlUnit>)
    }
    let layout <- array(SDL_GPUVertexBufferDescription(pitch = 32u))
    let attributes <- array(SDL_GPUVertexAttribute(format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3), SDL_GPUVertexAttribute(location = 1u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3, offset = 12u), SDL_GPUVertexAttribute(location = 2u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2, offset = 24u))
    var pipeline = pipeline(device, shaders::lod_vertex, shaders::lod_vertex_reflect, shaders::lod_fragment, shaders::lod_fragment_reflect, format, true, layout, attributes) |> sdl_try
    r.pipeline = pipeline
    return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : LodResources; var color, depth : SDL_GPUTexture?; width, height : uint; distance : float; state : LodState) : SdlStatus {
    let transform = shaders::LodTransform(model = model_matrix(float3(0.0), float3(0.1)), view_projection = camera_matrix(width, height, float3(0.0, 2.0, -distance), float3(0.0, 1.0, 0.0)))
    push_gpu_dsl_vertex_uniform(command, 0u, transform) |> sdl_try
    let targets <- array(SDL_GPUColorTargetInfo(texture = color, load_op = SDL_GPULoadOp.LOADOP_CLEAR, store_op = SDL_GPUStoreOp.STOREOP_STORE, clear_color = SDL_FColor(r = 0.12, g = 0.16, b = 0.22, a = 1.0)))
    let depth_info = depth_attachment(depth)
    return with_native_gpu_render_pass(command, targets, depth_info) $(var pass_) {
        SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
        let transitioning = state.current != state.target && state.transitions
        let split = transitioning ? 1.0 - float(state.frame) / 32.0 : 1.0
        for (draw in 0 .. (transitioning ? 2 : 1)) {
            let level = draw == 0 ? state.current : state.target
            let fade = shaders::LodFade(stipple = float4(split, float(draw), 0.0, 0.0))
            push_gpu_dsl_fragment_uniform(command, 0u, fade) |> sdl_try
            for (part in fixed_array(1, 0)) {
                let textures <- array(SDL_GPUTextureSamplerBinding(texture = part == 0 ? r.leaf : r.bark, sampler = r.sampler))
                sdl_status(SDL_BindGPUFragmentSamplersArray(pass_, 0u, textures), "LOD texture") |> sdl_try
                draw_geometry(pass_, r.meshes[level * 2 + part]) |> sdl_try
            }
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
        var distance = 2.0
        var state = LodState()
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) {
                    running = false
                }
                match (event) {
                    if (SdlEvent(key_down = $v(k))) {
                        if (k.keycode == SDLK_UP) {
                            distance = max(1.0, distance - 0.2)
                        } elif (k.keycode == SDLK_DOWN) {
                            distance = min(12.0, distance + 0.2)
                        } elif (k.keycode == SDLK_T && !k.repeat) {
                            state.transitions = !state.transitions
                        } elif (k.keycode == SDLK_R) {
                            distance = 2.0
                            state = LodState()
                        }
                    } if (_) {
                    }
                }
            }
            if (!running) {
                break
            }
            update_lod(state, distance)
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var color : SDL_GPUTexture?; width, height : uint) {
                replace_depth(device, depth, size, width, height) |> sdl_try
                return draw(device, command, r, color, depth, width, height, distance, state)
            }  |> sdl_try
            set_title(window, "LOD {state.current} -> {state.target}, transition {state.frame}/32 | distance {distance} | Up/Down, T: transition, R/Esc") |> sdl_try
            SDL_Delay(16u)
        }
        return sdl_ok()
    }
}
