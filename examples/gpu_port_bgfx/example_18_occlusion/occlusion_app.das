options gen2
// Adapted from bgfx 26-occlusion. Copyright 2011-2026 Branimir Karadzic.
// BSD-2-Clause: examples/gpu_port_bgfx/LICENSE-bgfx.txt.
module occlusion_app shared public
require ../common/compute_support.das public
require ./shaders/occlusion_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool }
struct Resources { cube : GeometryBuffers; pipeline : SDL_GPUGraphicsPipeline ?; query : SDL_GPUComputePipeline ?; commands : SDL_GPUBuffer ?; depth : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; size : uint2; angle : float }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() {
        release(device, r.cube)
        if (r.pipeline != null) { SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline) }
        if (r.query != null) { SDL_ReleaseGPUComputePipeline(device, r.query) }
        if (r.commands != null) { SDL_ReleaseGPUBuffer(device, r.commands) }
        if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth) }
        if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
    }
    let cube <- cube_geometry(); var acquired_cube = upload_geometry(device, cube) |> sdl_try; r.cube = acquired_cube
    var acquired_commands = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE | SDL_GPU_BUFFERUSAGE_INDIRECT, size = 121u * 20u)) |> sdl_try; r.commands = acquired_commands
    var acquired_query = compute_pipeline(device, shaders::occlusion_query, shaders::occlusion_query_reflect, shaders::occlusion_query_access) |> sdl_try; r.query = acquired_query
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_NEAREST))
    if (r.sampler == null) { return err(sdl_error("Occlusion sampler"), type<SdlUnit>) }
    let colors <- array(gpu_color_target(format))
    var acquired_pipeline = pass_pipeline(device, shaders::occlusion_vertex, shaders::occlusion_vertex_reflect, shaders::occlusion_fragment, shaders::occlusion_fragment_reflect, colors) |> sdl_try; r.pipeline = acquired_pipeline
    return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    if (r.size != uint2(width, height)) {
        if (r.depth != null) { SDL_ReleaseGPUTexture(device, r.depth); r.depth = null }
        var acquired_depth = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.depth = acquired_depth
        r.size = uint2(width, height)
    }
    if (!settings.paused) { r.angle = time * 0.25 }; if (settings.reset) { r.angle = 0.0 }
    let eye = float3(sin(r.angle) * 20.0, 4.0, -38.0); let vp = camera_matrix(width, height, eye, float3(0.0))
    let colors <- array(attachment(output, float4(0.025, 0.035, 0.05, 1.0)))
    var depth = depth_attachment(r.depth); depth.store_op = SDL_GPUStoreOp.STOREOP_STORE
    with_native_gpu_render_pass(command, colors, depth) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
        push_gpu_dsl_vertex_uniform(command, 0u, shaders::Camera(vp = vp, config = float4(1.0))) |> sdl_try
        return draw_geometry(pass_, r.cube)
    } |> sdl_try
    push_gpu_dsl_compute_uniform(command, 0u, shaders::Camera(vp = vp, config = float4(float(width), float(height), settings.mode == 1 ? 1.0 : 0.0, 0.0))) |> sdl_try
    var textures : array<SDL_GPUStorageTextureReadWriteBinding>
    let buffers <- array(SDL_GPUStorageBufferReadWriteBinding(buffer = r.commands))
    with_native_gpu_compute_pass(command, textures, buffers) $(var pass_ : SDL_GPUComputePass?&) {
        SDL_BindGPUComputePipeline(pass_, r.query)
        let samplers <- array(SDL_GPUTextureSamplerBinding(texture = r.depth, sampler = r.sampler))
        sdl_status(SDL_BindGPUComputeSamplersArray(pass_, 0u, samplers), "Occlusion depth") |> sdl_try
        SDL_DispatchGPUCompute(pass_, 2u, 1u, 1u); return sdl_ok()
    } |> sdl_try
    let load <- array(attachment(output, float4(0.0), true)); depth.load_op = SDL_GPULoadOp.LOADOP_LOAD
    return with_native_gpu_render_pass(command, load, depth) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
        push_gpu_dsl_vertex_uniform(command, 0u, shaders::Camera(vp = vp)) |> sdl_try
        let bindings <- array(SDL_GPUBufferBinding(buffer = r.cube.vb))
        sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, bindings), "Cube vertices") |> sdl_try
        SDL_BindGPUIndexBufferRef(pass_, SDL_GPUBufferBinding(buffer = r.cube.ib), SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
        SDL_DrawGPUIndexedPrimitivesIndirect(pass_, r.commands, 0u, 121u)
        return sdl_ok()
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var settings = Settings(); var running = true; var frames = 0; let start = SDL_GetTicks()
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) { running = false }
                match (event) { if (SdlEvent(key_down = $v(k))) { if (!k.repeat) {
                    if (k.keycode == SDLK_M) { settings.mode = (settings.mode + 1) % 2 }
                    elif (k.keycode == SDLK_SPACE) { settings.paused = !settings.paused }
                    elif (k.keycode == SDLK_R) { settings.reset = true }
                } } if (_) {} }
            }
            if (!running) { break }
            let time = float(SDL_GetTicks() - start) * 0.001
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            settings.reset = false
            set_title(window, "Occlusion: depth test + GPU indirect | 0: culled 1: all | M: mode {settings.mode} | Space: pause | R: reset") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
