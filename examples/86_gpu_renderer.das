options gen2
require dassdl3/sdl3_render_surface_34_boost
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_scope
require math

// SDL Renderer drawing with a custom SDL GPU fragment shader.
// Shader binaries are shipped; no shader compiler is required at runtime.
def run(smoke : bool) : SdlStatus {
    return sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window? = with_window("SDL GPU Renderer - Escape to exit", 640, 480, 0ul) |> sdl_use
        let renderer : SDL_Renderer? = with_gpu_renderer(null, window) |> sdl_use
        let device = SDL_GetGPURendererDevice(renderer)// Borrowed; renderer owns this device.
        let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
        let extension = spirv ? "spv" : "dxil"
        let info = SDL_GPUShaderCreateInfo(
            format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL,
            stage = SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT,
            num_uniform_buffers = 1u)
        var shader : SDL_GPUShader? = device |> with_native_gpu_shader_file(
            info,
            "{SDL_GetBasePath()}assets/shaders/render_state.frag.{extension}",
            "main") |> sdl_use
        var samplers : array<SDL_GPUTextureSamplerBinding>
        var textures : array<SDL_GPUTexture?>; var buffers : array<SDL_GPUBuffer?>
        let state : SDL_GPURenderState? = renderer |> with_gpu_render_state(shader, samplers, textures, buffers, 0u) |> sdl_use
        var running = true; var frames = 0
        while (running) {
            for (event in poll_events()) {if (should_close(event)) {running = false; break}}
            if (!running) {break}
            let phase = float(SDL_GetTicks()) / 1000.0
            var tint <- array<float>(0.5 + 0.5 * sin(phase), 0.4, 0.5 + 0.5 * cos(phase), 1.0)
            state |> set_gpu_render_state_fragment_uniforms(0u, tint) |> sdl_try
            renderer |> set_gpu_render_state(null) |> sdl_try
            renderer |> clear() |> sdl_try
            renderer |> set_gpu_render_state(state) |> sdl_try
            sdl_status(SDL_RenderFillRectRef(renderer, SDL_FRect(x = 80.0, y = 60.0, w = 480.0, h = 360.0)), "SDL_RenderFillRect") |> sdl_try
            renderer |> present() |> sdl_try
            frames++
            if (smoke && frames >= 4) {break}
            SDL_Delay(16u)
        }
        return sdl_ok()
    }
}
[export]
def main(smoke : bool) : int {
    let result = run(smoke)
    if (is_err(result)) { let error = unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1 }
    print("GPU Renderer: custom fragment uniforms; resources released.\n")
    return 0
}
