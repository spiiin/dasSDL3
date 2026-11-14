options gen2
options gc
options persistent_heap
require ./gpu_port_bgfx/common/file_shader_support.das
require dassdl3/sdl3_render_surface_34_boost
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_scope
require math
require daslib/defer

// SDL Renderer drawing with a custom SDL GPU fragment shader.
// Shader binaries are shipped; no shader compiler is required at runtime.
var shader : SDL_GPUShader?
var state : SDL_GPURenderState?

def open_renderer(renderer : SDL_Renderer?) : SdlStatus {
    let device = SDL_GetGPURendererDevice(renderer) // Borrowed from the renderer.
    let backend = file_shader_backend(device)
    let info = SDL_GPUShaderCreateInfo(
        format = backend.format,
        stage = SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,
        num_uniform_buffers = 1u)
    shader = device |> load_native_gpu_shader(
        info,
        "{SDL_GetBasePath()}assets/shaders/render_state.frag.{backend.extension}",
        backend.entry) |> sdl_try
    var samplers : array<SDL_GPUTextureSamplerBinding>
    var textures : array<SDL_GPUTexture?>
    var buffers : array<SDL_GPUBuffer?>
    state = SDL_CreateGPURenderStateArrays(renderer, shader, samplers, textures, buffers, 0u)
    return sdl_status(state != null, "SDL_CreateGPURenderStateArrays")
}

def draw_renderer_frame(renderer : SDL_Renderer?) : SdlStatus {
    let phase = float(SDL_GetTicks()) / 1000.0
    var tint <- array<float>(0.5 + 0.5 * sin(phase), 0.4, 0.5 + 0.5 * cos(phase), 1.0)
    state |> set_gpu_render_state_fragment_uniforms(0u, tint) |> sdl_try
    renderer |> set_gpu_render_state(null) |> sdl_try
    renderer |> clear() |> sdl_try
    renderer |> set_gpu_render_state(state) |> sdl_try
    sdl_status(SDL_RenderFillRectRef(renderer, SDL_FRect(x = 80.0, y = 60.0, w = 480.0, h = 360.0)), "SDL_RenderFillRect") |> sdl_try
    return renderer |> present()
}

def report(result : SdlStatus) : bool {
    if (is_ok(result)) { return true }
    let error = unwrap_err(result)
    print("{error.operation}: {error.message}\n")
    return false
}

[export]
def renderer_open(renderer : SDL_Renderer?) : bool {
    return report(open_renderer(renderer))
}

[export]
def renderer_frame(renderer : SDL_Renderer?) : bool {
    return report(draw_renderer_frame(renderer))
}

[export]
def renderer_close(renderer : SDL_Renderer?) {
    if (state != null) {
        SDL_SetGPURenderState(renderer, null)
        SDL_DestroyGPURenderState(state)
        state = null
    }
    if (shader != null) {
        SDL_ReleaseGPUShader(SDL_GetGPURendererDevice(renderer), shader)
        shader = null
    }
}

def run(smoke : bool) : SdlStatus {
    return sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("SDL GPU Renderer - Escape to exit", 640, 480, 0ul) |> sdl_use
        let renderer : SDL_Renderer? = with_gpu_renderer(null, window) |> sdl_use
        {
            defer() { renderer_close(renderer) }
            open_renderer(renderer) |> sdl_try
            var running = true
            var frames = 0
            while (running) {
                for (event in poll_events()) {if (should_close(event)) {running = false; break}}
                if (!running) {break}
                draw_renderer_frame(renderer) |> sdl_try
                frames++
                if (smoke && frames >= 4) {break}
                SDL_Delay(16u)
            }
        }
        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    if (!report(run(smoke))) { return 1 }
    print("GPU Renderer: custom fragment uniforms; resources released.\n")
    return 0
}
