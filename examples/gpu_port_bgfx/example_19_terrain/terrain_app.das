options gen2
// Adapted from bgfx 27-terrain. Copyright 2015 Andrew Mac.
// BSD-2-Clause: examples/gpu_port_bgfx/LICENSE-bgfx.txt.
module terrain_app shared public
require ../common/multipass_support.das public
require ./shaders/terrain_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool; brush : float2 = float2(0.5); painting : bool; lower : bool }
struct Resources { grid : GeometryBuffers; geometry : Geometry; heights : array<uint8>; map, depth : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; transfer, vertex_transfer : SDL_GPUTransferBuffer ?; pipeline : SDL_GPUGraphicsPipeline ?; size : uint2; mode : int = -1 }
// Editing is on the CPU, like bgfx 27-terrain; default displacement is a vertex texture fetch.
def brush(var heights : array<uint8>; center : float2; lower : bool) {
    let c = center * 127.0
    for (y in max(0, int(c.y) - 9)..min(128, int(c.y) + 10)) { for (x in max(0, int(c.x) - 9)..min(128, int(c.x) + 10)) {
        let distance = length(float2(float(x), float(y)) - c)
        if (distance < 9.0) { let i = y * 128 + x; heights[i] = uint8(clamp(int(heights[i]) + (lower ? -1 : 1) * int((9.0 - distance) * 0.8 + 1.0), 0, 255)) }
    } }
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() {
        release(device, r.grid)
        for (t in fixed_array(r.map, r.depth)) { if (t != null) { SDL_ReleaseGPUTexture(device, t) } }
        if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
        if (r.vertex_transfer != null) { SDL_ReleaseGPUTransferBuffer(device, r.vertex_transfer) }
        if (r.transfer != null) { SDL_ReleaseGPUTransferBuffer(device, r.transfer) }
        if (r.pipeline != null) { SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline) }
    }
    resize(r.heights, 128 * 128)
    for (y in 0..128) { for (x in 0..128) {
        vertex(r.geometry, float3(float(x) - 63.5, 0.0, float(y) - 63.5) * 0.25, float3(0.0, 1.0, 0.0), (float2(float(x), float(y)) + float2(0.5)) / 128.0)
    } }
    for (y in 0..127) { for (x in 0..127) {
        let a = uint(y * 128 + x); for (i in fixed_array(a, a + 128u, a + 129u, a, a + 129u, a + 1u)) { push(r.geometry.indices, i) }
    } }
    var acquired_grid = upload_geometry(device, r.geometry) |> sdl_try; r.grid = acquired_grid
    var acquired_map = texture(device, 128u, 128u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.map = acquired_map
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_NEAREST))
    if (r.sampler == null) { return err(sdl_error("Terrain sampler"), type<SdlUnit>) }
    r.transfer = SDL_CreateGPUTransferBufferRef(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = 16384u))
    if (r.transfer == null) { return err(sdl_error("Terrain upload"), type<SdlUnit>) }
    r.vertex_transfer = SDL_CreateGPUTransferBufferRef(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = 524288u))
    if (r.vertex_transfer == null) { return err(sdl_error("Terrain vertex upload"), type<SdlUnit>) }
    let targets <- array(gpu_color_target(format))
    var acquired_pipeline = pass_pipeline(device, shaders::terrain_vertex, shaders::terrain_vertex_reflect, shaders::terrain_fragment, shaders::terrain_fragment_reflect, targets) |> sdl_try; r.pipeline = acquired_pipeline
    return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    replace_depth(device, r.depth, r.size, width, height) |> sdl_try
    let dirty = r.mode != settings.mode || settings.reset || settings.painting
    if (settings.reset) { for (v in r.heights) { v = uint8(0) } }
    if (settings.painting && !settings.paused) { brush(r.heights, settings.brush, settings.lower) }
    if (dirty) {
        sdl_status(SDL_WriteGPUTransferBufferBytes(device, r.transfer, 16384u, 0u, r.heights, true), "Terrain height upload") |> sdl_try
        with_native_gpu_copy_pass(command) $(var pass_ : SDL_GPUCopyPass?&) {
            SDL_UploadToGPUTextureRef(pass_, SDL_GPUTextureTransferInfo(transfer_buffer = r.transfer, pixels_per_row = 128u, rows_per_layer = 128u), SDL_GPUTextureRegion(texture = r.map, w = 128u, h = 128u, d = 1u), true)
            return sdl_ok()
        } |> sdl_try
        if (settings.mode != 0) {
            for (i in 0..16384) { r.geometry.vertices[i * 8 + 1] = float(r.heights[i]) * 24.0 / 255.0 }
            upload_floats(device, command, r.grid.vb, r.vertex_transfer, 524288u, r.geometry.vertices) |> sdl_try
        }
        r.mode = settings.mode
    }
    let targets <- array(attachment(output, float4(0.05, 0.065, 0.08, 1.0)))
    let depth = depth_attachment(r.depth)
    return with_native_gpu_render_pass(command, targets, depth) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
        let bindings <- array(SDL_GPUTextureSamplerBinding(texture = r.map, sampler = r.sampler))
        sdl_status(SDL_BindGPUVertexSamplersArray(pass_, 0u, bindings), "Terrain sampler") |> sdl_try
        push_gpu_dsl_vertex_uniform(command, 0u, shaders::Camera(vp = camera_matrix(width, height, float3(28.0, 32.0, -38.0), float3(0.0)), config = float4(float(settings.mode), 0.0, 0.0, 0.0))) |> sdl_try
        return draw_geometry(pass_, r.grid)
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var settings = Settings(); var running = true; var frames = 0; let start = SDL_GetTicks()
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) { running = false }
                match (event) {
                    if (SdlEvent(mouse_motion = $v(m))) {
                        let size = window_size(window) |> sdl_try
                        // Intersect the camera ray with the base plane for brush placement.
                        let inv = inverse(camera_matrix(uint(size.x), uint(size.y), float3(28.0, 32.0, -38.0), float3(0.0)))
                        let ndc = float2(m.position.x / float(size.x) * 2.0 - 1.0, 1.0 - m.position.y / float(size.y) * 2.0)
                        let a = inv * float4(ndc, 0.0, 1.0); let b = inv * float4(ndc, 1.0, 1.0)
                        let origin = a.xyz / a.w; let dir = b.xyz / b.w - origin
                        if (abs(dir.y) > 0.0001) { let hit = origin - dir * (origin.y / dir.y); settings.brush = clamp(hit.xz / 31.75 + float2(0.5), float2(0.0), float2(1.0)) }
                    }
                    if (SdlEvent(mouse_button_down = $v(m))) { settings.painting = true; settings.lower = m.button == 3u }
                    if (SdlEvent(mouse_button_up = _)) { settings.painting = false }
                     if (SdlEvent(key_down = $v(k))) { if (!k.repeat) {
                    if (k.keycode == SDLK_M) { settings.mode = (settings.mode + 1) % 2 }
                    elif (k.keycode == SDLK_SPACE) { settings.paused = !settings.paused }
                    elif (k.keycode == SDLK_R) { settings.reset = true }
                } } if (_) {} }
            }
            if (!running) { break }
            let time = float(SDL_GetTicks() - start) * 0.001
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            settings.reset = false
            set_title(window, "Terrain | mouse: paint, right: lower | M: mode {settings.mode} | Space: pause | R: reset") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
