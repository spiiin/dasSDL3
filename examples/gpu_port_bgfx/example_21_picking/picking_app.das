// Adapted from bgfx 30-picking; see the example README and group LICENSE-bgfx.txt.
options gen2
module picking_app shared public
require ../common/multipass_support.das public
require ./shaders/picking_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool }
struct Resources { cube : GeometryBuffers; shaded, ids : SDL_GPUGraphicsPipeline ?; idmap, depth : SDL_GPUTexture ?; download : SDL_GPUTransferBuffer ?; fence : SDL_GPUFence ?; size : uint2; selected : uint; angle : float }
def object_position(id : int) : float3 { return float3(float((id - 1) % 4) * 3.0 - 4.5, float((id - 1) / 4) * 3.0 - 3.0, 0.0) }
def camera(width, height : uint) : float4x4 { return camera_matrix(width, height, float3(0.0, 0.0, -18.0), float3(0.0)) }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() {
        if (r.fence != null) { SDL_ReleaseGPUFence(device, r.fence) }
        if (r.download != null) { SDL_ReleaseGPUTransferBuffer(device, r.download) }
        release(device, r.cube)
        for (resource in fixed_array(r.shaded, r.ids)) { if (resource != null) { SDL_ReleaseGPUGraphicsPipeline(device, resource) } }
        for (resource in fixed_array(r.idmap, r.depth)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }
    }
    let cube <- cube_geometry(); var g = upload_geometry(device, cube) |> sdl_try; r.cube = g
    let targets <- array(gpu_color_target(format)); let ids <- array(gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
    var p = pass_pipeline(device, shaders::picking_vertex, shaders::picking_vertex_reflect, shaders::picking_shaded, shaders::picking_shaded_reflect, targets) |> sdl_try; r.shaded = p
    p = pass_pipeline(device, shaders::picking_id_vertex, shaders::picking_id_vertex_reflect, shaders::picking_id, shaders::picking_id_reflect, ids) |> sdl_try; r.ids = p
    r.download = SDL_CreateGPUTransferBufferRef(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD, size = 256u))
    if (r.download == null) { return err(sdl_error("Picking transfer"), type<SdlUnit>) }
    return body(r)
}
// One in-flight request. Interactive code polls; it never waits for the GPU.
def poll_pick(device : SDL_GPUDevice?; var r : Resources) : SdlStatus {
    if (r.fence != null && SDL_QueryGPUFence(device, r.fence)) {
        var bytes : array<uint8>; resize(bytes, 4)
        sdl_status(SDL_ReadGPUTransferBufferBytes(device, r.download, 256u, 0u, bytes), "Picking readback") |> sdl_try
        r.selected = uint(bytes[0]); SDL_ReleaseGPUFence(device, r.fence); r.fence = null
    }
    return sdl_ok()
}
def request_pick(device : SDL_GPUDevice?; var r : Resources; pixel : int2) : SdlStatus {
    if (r.fence != null || r.size.x == 0u) { return sdl_ok() }
    return sdl_scope() {
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        with_native_gpu_copy_pass(command) $(var pass_ : SDL_GPUCopyPass?&) {
            let source = SDL_GPUTextureRegion(texture = r.idmap, x = uint(clamp(pixel.x, 0, int(r.size.x) - 1)), y = uint(clamp(pixel.y, 0, int(r.size.y) - 1)), w = 1u, h = 1u, d = 1u)
            SDL_DownloadFromGPUTextureRef(pass_, source, SDL_GPUTextureTransferInfo(transfer_buffer = r.download, pixels_per_row = 64u, rows_per_layer = 1u))
            return sdl_ok()
        } |> sdl_try
        var fence = native_gpu_submit_fence(command) |> sdl_try; r.fence = fence
        return sdl_ok()
    }
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    if (r.size != uint2(width, height)) {
        for (resource in fixed_array(r.idmap, r.depth)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }
        r.idmap = null; r.depth = null; r.size = uint2(0u)
        var tex = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) |> sdl_try; r.idmap = tex
        tex = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) |> sdl_try; r.depth = tex; r.size = uint2(width, height)
    }
    if (!settings.paused) { r.angle = time * 0.3 }; if (settings.reset) { r.selected = 0u }
    for (stage in 0..2) {
        var target = stage == 0 ? r.idmap : output
        let targets <- array(attachment(target, stage == 0 ? float4(0.0) : float4(0.03, 0.04, 0.055, 1.0))); let depth = depth_attachment(r.depth)
        with_native_gpu_render_pass(command, targets, depth) $(var pass_ : SDL_GPURenderPass?&) {
            SDL_BindGPUGraphicsPipeline(pass_, stage == 0 ? r.ids : r.shaded)
            for (id in 1..13) {
                push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model_matrix(object_position(id), float3(0.8), r.angle + float(id) * 0.17), vp = camera(width, height), object = float4(float(id), r.selected == uint(id) ? 1.0 : 0.0, 0.0, 0.0))) |> sdl_try
                draw_geometry(pass_, r.cube) |> sdl_try
            }
            return sdl_ok()
        } |> sdl_try
    }
    return sdl_ok()
}
def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var settings = Settings(); var running = true; var frames = 0; let start = SDL_GetTicks(); var requested = false; var cursor = float2(0.5)
        while (running) {
            poll_pick(device, r) |> sdl_try
            for (event in poll_events()) {
                if (should_close(event, window)) { running = false }
                match (event) {
                    if (SdlEvent(mouse_button_down = $v(m))) { let size = window_size(window) |> sdl_try; cursor = m.position / float2(float(size.x), float(size.y)); requested = true }
                    if (SdlEvent(key_down = $v(k))) { if (!k.repeat && k.keycode == SDLK_SPACE) { settings.paused = !settings.paused } }
                    if (_) {}
                }
            }
            if (!running) { break }
            let time = float(SDL_GetTicks() - start) * 0.001
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            if (requested && r.fence == null) { request_pick(device, r, int2(int(cursor.x * float(r.size.x)), int(cursor.y * float(r.size.y)))) |> sdl_try; requested = false }
            set_title(window, "Picking | click an object | selected: {r.selected} | Space: pause") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
