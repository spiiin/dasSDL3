options gen2
module tess_app shared public
require ../common/imgui_gpu.das public
require ../common/compute_support.das
require ../common/post_scene/scene.das as scene
require ./shaders/tess_shaders.das as shaders
require daslib/defer
struct Settings { wireframe : bool; cull : bool = true; freeze : bool; pixels : float = 7.0; patch : int = 3; normals : bool }
struct Resources { nodes : array<SDL_GPUBuffer?>; visible, counters, indirect, vb, ib : SDL_GPUBuffer ?; update, commands : SDL_GPUComputePipeline ?; pipelines : array<SDL_GPUGraphicsPipeline?>; heightmap, depth : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; ping : int; patch : int = -1; indices : uint; size : uint2 }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() { for (resource in r.nodes) { SDL_ReleaseGPUBuffer(device, resource) }; for (resource in fixed_array(r.visible, r.counters, r.indirect, r.vb, r.ib)) { if (resource != null) { SDL_ReleaseGPUBuffer(device, resource) } }; for (p in r.pipelines) { SDL_ReleaseGPUGraphicsPipeline(device, p) }; for (p in fixed_array(r.update, r.commands)) { if (p != null) { SDL_ReleaseGPUComputePipeline(device, p) } }; for (image in fixed_array(r.heightmap, r.depth)) { if (image != null) { SDL_ReleaseGPUTexture(device, image) } }; if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) } }
    let usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_READ | SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE
    for (i in range(2)) { var b = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = usage, size = 8388608u)) |> sdl_try; push(r.nodes, b) }
    var b = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = usage | SDL_GPU_BUFFERUSAGE_VERTEX, size = 8388608u)) |> sdl_try; r.visible = b
    b = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = usage | SDL_GPU_BUFFERUSAGE_INDIRECT, size = 32u)) |> sdl_try; r.counters = b
    b = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = usage | SDL_GPU_BUFFERUSAGE_INDIRECT, size = 12u)) |> sdl_try; r.indirect = b
    b = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_VERTEX, size = 360u)) |> sdl_try; r.vb = b
    b = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_INDEX, size = 768u)) |> sdl_try; r.ib = b
    var t = texture(device, 4096u, 4096u, SDL_GPUTextureFormat.TEXTUREFORMAT_R16_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.heightmap = t
    upload_texture(device, r.heightmap, "tess-height.raw", 4096u, 4096u, 2u, 1u) |> sdl_try
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR)); if (r.sampler == null) { return err(sdl_error("Terrain sampler"), type<SdlUnit>) }
    var cp = compute_pipeline(device, shaders::tess_lod, shaders::tess_lod_reflect, shaders::tess_lod_access) |> sdl_try; r.update = cp
    cp = compute_pipeline(device, shaders::tess_commands, shaders::tess_commands_reflect, shaders::tess_commands_access) |> sdl_try; r.commands = cp
    for (i in range(2)) {
        var p = sdl_scope() {
            var vs : SDL_GPUShader? = with_example_shader(device, shaders::tess_vertex, shaders::tess_vertex_reflect) |> sdl_use
            var fs : SDL_GPUShader? = with_example_shader(device, shaders::tess_fragment, shaders::tess_fragment_reflect) |> sdl_use
            var info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vs, fragment_shader = fs, rasterizer_state = SDL_GPURasterizerState(enable_depth_clip = true, fill_mode = i == 0 ? SDL_GPUFillMode.FILLMODE_FILL : SDL_GPUFillMode.FILLMODE_LINE))
            info <- info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT) |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS_OR_EQUAL) |> depth_write(true)
            let layout <- array(SDL_GPUVertexBufferDescription(pitch = 8u), SDL_GPUVertexBufferDescription(slot = 1u, pitch = 8u, input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE))
            let attrs <- array(SDL_GPUVertexAttribute(format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2), SDL_GPUVertexAttribute(location = 1u, buffer_slot = 1u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_UINT2))
            let colors <- array(gpu_color_target(format)); return create_native_gpu_graphics_pipeline(device, info, layout, attrs, colors)
        } |> sdl_try; push(r.pipelines, p)
    }; return body(r)
}
def uint_bytes(values : array<uint>) : array<uint8> { var bytes : array<uint8>; for (v in values) { for (shift in fixed_array(0u, 8u, 16u, 24u)) { push(bytes, uint8((v >> shift) & 255u)) } }; return <- bytes }
def float_bytes(values : array<float>) : array<uint8> { var words : array<uint>; for (v in values) { push(words, float_bits_to_uint(v)) }; return <- uint_bytes(words) }
def reset(device : SDL_GPUDevice?; var r : Resources; patch : int) : SdlStatus {
    let n = 1 << patch; var vertices : array<float>; var indices : array<uint>
    for (y in range(n + 1)) { for (x in range(n - y + 1)) { push(vertices, float(x) / float(n)); push(vertices, float(y) / float(n)) } }
    var row = 0
    for (y in range(n)) { let next = row + n - y + 1
        for (x in range(n - y)) { for (i in fixed_array(row + x, row + x + 1, next + x)) { push(indices, uint(i)) }; if (x < n - y - 1) { for (i in fixed_array(row + x + 1, next + x + 1, next + x)) { push(indices, uint(i)) } } }; row = next
    }
    let vb <- float_bytes(vertices); let ib <- uint_bytes(indices); upload_bytes(device, r.vb, vb) |> sdl_try; upload_bytes(device, r.ib, ib) |> sdl_try
    let roots <- uint_bytes(array<uint>(0u, 1u, 1u, 1u)); upload_bytes(device, r.nodes[0], roots) |> sdl_try
    let counts <- uint_bytes(array<uint>(0u, 0u, 2u, uint(length(indices)), 0u, 0u, 0u, 0u)); upload_bytes(device, r.counters, counts) |> sdl_try
    let dispatch <- uint_bytes(array<uint>(1u, 1u, 1u)); upload_bytes(device, r.indirect, dispatch) |> sdl_try
    r.patch = patch; r.ping = 0; r.indices = uint(length(indices)); return sdl_ok()
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; s : Settings; camera : scene::Camera) : SdlStatus {
    if (r.size != uint2(width, height)) { if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth); r.depth = null }; var t = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) |> sdl_try; r.depth = t; r.size = uint2(width, height) }
    let direction = float3(cos(camera.pitch) * sin(camera.yaw), sin(camera.pitch), cos(camera.pitch) * cos(camera.yaw))
    let vp = perspective(float(width) / float(height), 1.7320508, 0.0001, 2000.0) * look_at_lh(camera.eye, camera.eye + direction, float3(0.0, 1.0, 0.0))
    let config = shaders::Config(vp = vp, eye = float4(camera.eye, 1.0), settings = float4(1.1547005 / float(width) * float(1 << s.patch) * s.pixels, float(r.indices), 0.0, 0.0), flags = float4(s.freeze ? 1.0 : 0.0, s.cull ? 1.0 : 0.0, s.normals ? 1.0 : 0.0, 0.0))
    push_gpu_dsl_compute_uniform(command, 0u, config) |> sdl_try
    var textures : array<SDL_GPUStorageTextureReadWriteBinding>
    // Read-only node input occupies compute set 0 after the height sampler.
    let rw <- array(SDL_GPUStorageBufferReadWriteBinding(buffer = r.nodes[1 - r.ping]), SDL_GPUStorageBufferReadWriteBinding(buffer = r.visible), SDL_GPUStorageBufferReadWriteBinding(buffer = r.counters))
    with_native_gpu_compute_pass(command, textures, rw) $(var pass_ : SDL_GPUComputePass?&) {
        SDL_BindGPUComputePipeline(pass_, r.update)
        let samplers <- array(SDL_GPUTextureSamplerBinding(texture = r.heightmap, sampler = r.sampler)); sdl_status(SDL_BindGPUComputeSamplersArray(pass_, 0u, samplers), "Terrain height") |> sdl_try
        var input <- array(r.nodes[r.ping]); sdl_status(SDL_BindGPUComputeStorageBuffersArray(pass_, 0u, input), "Terrain nodes") |> sdl_try
        SDL_DispatchGPUComputeIndirect(pass_, r.indirect, 0u); return sdl_ok()
    } |> sdl_try
    let counter <- array(SDL_GPUStorageBufferReadWriteBinding(buffer = r.counters), SDL_GPUStorageBufferReadWriteBinding(buffer = r.indirect))
    with_native_gpu_compute_pass(command, textures, counter) $(var pass_ : SDL_GPUComputePass?&) { SDL_BindGPUComputePipeline(pass_, r.commands); SDL_DispatchGPUCompute(pass_, 1u, 1u, 1u); return sdl_ok() } |> sdl_try
    r.ping = 1 - r.ping
    push_gpu_dsl_vertex_uniform(command, 0u, config) |> sdl_try; push_gpu_dsl_fragment_uniform(command, 0u, config) |> sdl_try
    let colors <- array(attachment(output, float4(0.188, 0.188, 0.188, 1.0)))
    return with_native_gpu_render_pass(command, colors, depth_attachment(r.depth)) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.pipelines[s.wireframe ? 1 : 0]); let vbs <- array(SDL_GPUBufferBinding(buffer = r.vb), SDL_GPUBufferBinding(buffer = r.visible)); sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, vbs), "Terrain vertices") |> sdl_try
        let samplers <- array(SDL_GPUTextureSamplerBinding(texture = r.heightmap, sampler = r.sampler)); sdl_status(SDL_BindGPUVertexSamplersArray(pass_, 0u, samplers), "Terrain displacement") |> sdl_try; sdl_status(SDL_BindGPUFragmentSamplersArray(pass_, 0u, samplers), "Terrain slopes") |> sdl_try
        SDL_BindGPUIndexBufferRef(pass_, SDL_GPUBufferBinding(buffer = r.ib), SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT); SDL_DrawGPUIndexedPrimitivesIndirect(pass_, r.counters, 12u, 1u); return sdl_ok()
    }
}
def panel(var s : Settings) { SetNextWindowPos(ImVec2(600.0, 10.0), ImGuiCond.FirstUseEver); if (Begin("Settings")) { Checkbox("Debug wireframe", unsafe(addr(s.wireframe))); Checkbox("Cull", unsafe(addr(s.cull))); Checkbox("Freeze subdividing", unsafe(addr(s.freeze))); SliderFloat("Pixels per edge", unsafe(addr(s.pixels)), 1.0, 20.0); SliderInt("Triangle Patch level", unsafe(addr(s.patch)), 0, 3); Checkbox("Display normals", unsafe(addr(s.normals))); Text("WASD: move | Arrows: look") }; End() }
def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_imgui_gpu(window, device) { DisableIniPersistence(); StyleColorsDark()
        return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
            var settings = Settings(); var camera = scene::Camera(eye = float3(0.0, 0.5, 0.0), pitch = 0.0); var raw = SDL_MakeEvent(); var running = true; var frames = 0u
            while (running) {
                while (is_some(poll_event(raw))) { ImGui_SDL3_ProcessEvent(raw); let e = decode_event(raw); if (should_close(e, window) && (!(e is key_down) || !ImGui_SDL3_WantCaptureKeyboard())) { running = false }; if (!ImGui_SDL3_WantCaptureKeyboard()) { scene::camera_event(e, camera) } }
                if (!running) { break }; begin_gui(); panel(settings); Render()
                if (r.patch != settings.patch) { reset(device, r, settings.patch) |> sdl_try }
                with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { draw(device, command, r, output, width, height, settings, camera) |> sdl_try; return draw_gui(command, output) } |> sdl_try
                frames++; if (smoke && frames >= 20u) { break }
            }; return sdl_ok()
        }
    }
}
