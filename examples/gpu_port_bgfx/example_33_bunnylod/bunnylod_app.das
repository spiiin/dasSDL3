options gen2
module bunnylod_app shared public
require ../common/imgui_gpu.das public
require ../common/mesh_data.das
require ./shaders/bunnylod_shaders.das as shaders
require daslib/defer
struct Settings { lod : float = 1.0 }
struct Resources { mesh : Geometry; collapse : array<uint>; buffers : GeometryBuffers; pipeline : SDL_GPUGraphicsPipeline ?; depth : SDL_GPUTexture ?; size : uint2; last_lod : float = -1.0; vertex_count : uint }

def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() { release(device, r.buffers); if (r.pipeline != null) { SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline) }; if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth) } }
    var mesh <- load_geometry("{SDL_GetBasePath()}assets/bgfx/bunnylod.msh") |> sdl_try
    r.mesh <- mesh
    // The original vertex shader uses the packed UNORM normal as RGB.
    for (i in range(length(r.mesh.vertices) / 8)) { for (c in range(3)) { r.mesh.vertices[i * 8 + 3 + c] = r.mesh.vertices[i * 8 + 3 + c] * 0.5 + 0.5 } }
    let data <- load_file("{SDL_GetBasePath()}assets/bgfx/bunnylod-collapse.bin") |> sdl_try
    let count = uint(length(r.mesh.vertices) / 8)
    if (length(data) != int(4u + count * 8u) || mesh_u32(data, 0) != count) { return err(SdlError(operation = "bunnylod", message = "Invalid collapse map"), type<SdlUnit>) }
    for (i in range(int(count))) { let to = mesh_u32(data, 4 + i * 4); if (i > 0 && to >= uint(i)) { return err(SdlError(operation = "bunnylod", message = "Non-decreasing collapse map"), type<SdlUnit>) }; push(r.collapse, to) }
    var buffers = upload_geometry(device, r.mesh) |> sdl_try; r.buffers = buffers
    let colors <- array(SDL_GPUColorTargetDescription(format = format))
    var pipeline = pass_pipeline(device, shaders::bunnylod_vertex, shaders::bunnylod_vertex_reflect, shaders::bunnylod_fragment, shaders::bunnylod_fragment_reflect, colors) |> sdl_try; r.pipeline = pipeline
    return body(r)
}

def update_lod(device : SDL_GPUDevice?; var r : Resources; lod : float) : SdlStatus {
    let value = clamp(lod, 0.05, 1.0)
    if (r.last_lod == value) { return sdl_ok() }
    r.vertex_count = max(1u, uint(value * value * float(length(r.collapse))))
    var bytes : array<uint8>
    for (i in range(length(r.mesh.indices) / 3)) {
        var ids : uint[3]
        for (c in range(3)) { var index = r.mesh.indices[i * 3 + c]; while (index >= r.vertex_count) { index = r.collapse[index] }; ids[c] = index }
        if (ids[0] == ids[1] || ids[0] == ids[2] || ids[1] == ids[2]) { continue }
        for (index in ids) { for (shift in fixed_array(0u, 8u, 16u, 24u)) { push(bytes, uint8((index >> shift) & 255u)) } }
    }
    if (length(bytes) > 0) { upload_bytes(device, r.buffers.ib, bytes) |> sdl_try }
    r.buffers.count = uint(length(bytes) / 4); r.last_lod = value
    return sdl_ok()
}

def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float) : SdlStatus {
    if (r.size != uint2(width, height)) {
        if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth); r.depth = null }
        var depth = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) |> sdl_try; r.depth = depth; r.size = uint2(width, height)
    }
    let transform = shaders::Transform(model = model_matrix(float3(0.0), float3(1.0), time * 0.37), vp = camera_matrix(width, height, float3(0.0, 1.0, -2.5), float3(0.0, 1.0, 0.0)))
    push_gpu_dsl_vertex_uniform(command, 0u, transform) |> sdl_try
    let targets <- array(attachment(output, float4(48.0 / 255.0, 48.0 / 255.0, 48.0 / 255.0, 1.0)))
    return with_native_gpu_render_pass(command, targets, depth_attachment(r.depth)) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
        return draw_geometry(pass_, r.buffers)
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_imgui_gpu(window, device) {
        DisableIniPersistence(); StyleColorsDark()
        return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
            var settings = Settings(); var event = SDL_MakeEvent(); var running = true; var frames = 0; let start = SDL_GetTicks()
            while (running) {
                while (is_some(poll_event(event))) { ImGui_SDL3_ProcessEvent(event); let owned = decode_event(event); if (should_close(owned, window) && (!(owned is key_down) || !ImGui_SDL3_WantCaptureKeyboard())) { running = false } }
                if (!running) { break }
                begin_gui()
                SetNextWindowPos(ImVec2(650.0, 10.0), ImGuiCond.FirstUseEver)
                SetNextWindowSize(ImVec2(300.0, 170.0), ImGuiCond.FirstUseEver)
                if (Begin("Settings")) { Text("Vertices: {int(r.vertex_count)}"); Text("Triangles: {int(r.buffers.count / 3u)}"); SliderFloat("LOD Level", unsafe(addr(settings.lod)), 0.05, 1.0) }
                End(); Render()
                update_lod(device, r, settings.lod) |> sdl_try
                with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) {
                    draw(device, command, r, output, width, height, float(SDL_GetTicks() - start) * 0.001) |> sdl_try
                    return draw_gui(command, output)
                } |> sdl_try
                frames++; if (smoke && frames >= 3) { break }
            }
            return sdl_ok()
        }
    }
}
