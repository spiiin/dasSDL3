options gen2
// Adapted from bgfx 24-nbody. Copyright 2014 Stanlo Slasinski.
// BSD-2-Clause: examples/gpu_port_bgfx/LICENSE-bgfx.txt.
module nbody_app shared public
require ../common/compute_support.das public
require ./shaders/nbody_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool }
struct Resources { previous, current, next_previous, next_current : SDL_GPUBuffer ?; init, update : SDL_GPUComputePipeline ?; pipeline : SDL_GPUGraphicsPipeline ?; initialized : bool; shape : int = -1; count : uint = 4096u }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() {
        for (buffer in fixed_array(r.previous, r.current, r.next_previous, r.next_current)) { if (buffer != null) { SDL_ReleaseGPUBuffer(device, buffer) } }
        for (p in fixed_array(r.init, r.update)) { if (p != null) { SDL_ReleaseGPUComputePipeline(device, p) } }
        if (r.pipeline != null) { SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline) }
    }
    let info = SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE | SDL_GPU_BUFFERUSAGE_VERTEX, size = r.count * 16u)
    var acquired_previous = create_native_gpu_buffer(device, info) |> sdl_try; r.previous = acquired_previous; var acquired_current = create_native_gpu_buffer(device, info) |> sdl_try; r.current = acquired_current
    var acquired_next_previous = create_native_gpu_buffer(device, info) |> sdl_try; r.next_previous = acquired_next_previous; var acquired_next_current = create_native_gpu_buffer(device, info) |> sdl_try; r.next_current = acquired_next_current
    var acquired_init = compute_pipeline(device, shaders::nbody_init, shaders::nbody_init_reflect, shaders::nbody_init_access) |> sdl_try; r.init = acquired_init
    var acquired_update = compute_pipeline(device, shaders::nbody_update, shaders::nbody_update_reflect, shaders::nbody_update_access) |> sdl_try; r.update = acquired_update
    var acquired_pipeline = sdl_scope() {
        var vs : SDL_GPUShader? = with_example_shader(device, shaders::nbody_vertex, shaders::nbody_vertex_reflect) |> sdl_use
        var fs : SDL_GPUShader? = with_example_shader(device, shaders::nbody_fragment, shaders::nbody_fragment_reflect) |> sdl_use
        let pi = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vs, fragment_shader = fs, rasterizer_state = SDL_GPURasterizerState(enable_depth_clip = true))
        var color = gpu_color_target(format); color.blend_state.enable_blend = true; color.blend_state.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
        let targets <- array(color)
        let layout <- array(SDL_GPUVertexBufferDescription(pitch = 16u, input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE))
        let attrs <- array(SDL_GPUVertexAttribute(format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4))
        return create_native_gpu_graphics_pipeline(device, pi, layout, attrs, targets)
    } |> sdl_try
    r.pipeline = acquired_pipeline
    return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    let reset = !r.initialized || settings.reset || r.shape != settings.mode
    push_gpu_dsl_compute_uniform(command, 0u, shaders::Simulation(count = r.count, shape = uint(settings.mode), seed = 7u, params = float4(0.1, 0.1, 10.0, 0.01))) |> sdl_try
    var textures : array<SDL_GPUStorageTextureReadWriteBinding>
    if (reset) {
        let buffers <- array(SDL_GPUStorageBufferReadWriteBinding(buffer = r.previous), SDL_GPUStorageBufferReadWriteBinding(buffer = r.current))
        with_native_gpu_compute_pass(command, textures, buffers) $(var pass_ : SDL_GPUComputePass?&) {
            SDL_BindGPUComputePipeline(pass_, r.init); SDL_DispatchGPUCompute(pass_, r.count / 512u, 1u, 1u); return sdl_ok()
        } |> sdl_try
        r.initialized = true; r.shape = settings.mode
    }
    if (!settings.paused) {
        let buffers <- array(SDL_GPUStorageBufferReadWriteBinding(buffer = r.previous), SDL_GPUStorageBufferReadWriteBinding(buffer = r.current), SDL_GPUStorageBufferReadWriteBinding(buffer = r.next_previous), SDL_GPUStorageBufferReadWriteBinding(buffer = r.next_current))
        with_native_gpu_compute_pass(command, textures, buffers) $(var pass_ : SDL_GPUComputePass?&) {
            SDL_BindGPUComputePipeline(pass_, r.update); SDL_DispatchGPUCompute(pass_, r.count / 512u, 1u, 1u); return sdl_ok()
        } |> sdl_try
        var tmp = r.current; r.current = r.next_current; r.next_current = tmp
        tmp = r.previous; r.previous = r.next_previous; r.next_previous = tmp
    }
    let targets <- array(attachment(output, float4(0.005, 0.005, 0.015, 1.0)))
    return with_native_gpu_render_pass(command, targets) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
        push_gpu_dsl_vertex_uniform(command, 0u, shaders::Camera(vp = camera_matrix(width, height, float3(0.0, 0.0, -65.0), float3(0.0)), right = float4(1.0, 0.0, 0.0, 0.0), up = float4(0.0, 1.0, 0.0, 0.0))) |> sdl_try
        let buffers <- array(SDL_GPUBufferBinding(buffer = r.current))
        sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, buffers), "Particle buffer") |> sdl_try
        SDL_DrawGPUPrimitives(pass_, 6u, r.count, 0u, 0u)
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
                    if (k.keycode == SDLK_M) { settings.mode = (settings.mode + 1) % 3 }
                    elif (k.keycode == SDLK_SPACE) { settings.paused = !settings.paused }
                    elif (k.keycode == SDLK_R) { settings.reset = true }
                } } if (_) {} }
            }
            if (!running) { break }
            let time = float(SDL_GetTicks() - start) * 0.001
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            settings.reset = false
            set_title(window, "N-body: 4096 particles, GPU Verlet | M: mode {settings.mode} | Space: pause | R: reset") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
