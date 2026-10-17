options gen2
// Adapted from bgfx 23-vectordisplay. Copyright 2014 Kai Jourdan.
// BSD-2-Clause: examples/gpu_port_bgfx/LICENSE-bgfx.txt.
module vectordisplay_app shared public
require ../common/multipass_support.das public
require ./shaders/vectordisplay_shaders.das as shaders
require ./simplex_font.das
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool }
struct Resources { lines : GeometryBuffers; line, blur, persist, compose : SDL_GPUGraphicsPipeline ?; image, ping, pong, history_a, history_b : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; size : uint2; first : bool = true; angle : float }
def line(var g : Geometry; a, b : float2; rgb : float3; moving : bool = false) {
    let d = b - a; if (length(d) < 0.01) { return }; let n = normalize(float2(-d.y, d.x)) * 3.0
    let points = fixed_array(a - n, b - n, b + n, a - n, b + n, a + n)
    let sides = fixed_array(-1.0, -1.0, 1.0, -1.0, 1.0, 1.0)
    for (i in 0..6) { push(g.indices, uint(length(g.vertices) / 8)); vertex(g, float3(points[i], moving ? 1.0 : 0.0), rgb, float2(0.0, sides[i])) }
}
def text_lines(var g : Geometry; text : string; origin : float2; rgb : float3) {
    var x = origin.x
    for (c in text) {
        if (c < 32 || c > 126) { continue }
        let start = font_offsets[int(c) - 32]; let count = font_data[start]; var drawing = false; var previous = float2(0.0)
        for (i in 0..count) {
            let a = font_data[start + 2 + i * 2]; let b = font_data[start + 3 + i * 2]
            if (a == -1 && b == -1) { drawing = false }
            else { let p = float2(x + float(a) * 1.5, origin.y - float(b) * 1.5); if (drawing) { line(g, previous, p, rgb) }; previous = p; drawing = true }
        }
        x += float(font_data[start + 1]) * 1.5
    }
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() {
        release(device, r.lines)
        for (p in fixed_array(r.line, r.blur, r.persist, r.compose)) { if (p != null) { SDL_ReleaseGPUGraphicsPipeline(device, p) } }
        for (t in fixed_array(r.image, r.ping, r.pong, r.history_a, r.history_b)) { if (t != null) { SDL_ReleaseGPUTexture(device, t) } }
        if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
    }
    var g : Geometry
    text_lines(g, "ABCDEFGHIJKLMNOPQRSTUVWXYZ", float2(50.0, 80.0), float3(0.7, 0.7, 1.0))
    text_lines(g, "abcdefghijklmnopqrstuvwxyz", float2(50.0, 140.0), float3(0.7, 0.7, 1.0))
    text_lines(g, "0123456789 !@#$%^&*() +-*/", float2(50.0, 200.0), float3(1.0, 0.7, 0.7))
    for (j in 0..4) { for (k in 0..j + 1) { line(g, float2(50.0, 350.0 + float(j) * 40.0), float2(200.0, 350.0 + float(j) * 40.0), float3(1.0, 0.5, 0.4)) } }
    for (j in 0..4) { let radius = 10.0 + float(j) * 23.0; let center = float2(260.0 + float(j) * 100.0, 450.0)
        for (i in 0..64) { let a = float(i) * 2.0 * PI / 64.0; let b = float(i + 1) * 2.0 * PI / 64.0; line(g, center + float2(cos(a), sin(a)) * radius, center + float2(cos(b), sin(b)) * radius, float3(0.6, 0.7, 1.0)) }
        let p = float2(260.0 + float(j) * 100.0, 600.0); let points = fixed_array(p, p + float2(radius, 0.0), p + float2(radius, radius), p + float2(0.0, radius))
        for (i in 0..4) { line(g, points[i], points[(i + 1) % 4], float3(0.6, 1.0, 0.6)) }
    }
    for (i in 0..12) { let a = float(i) * PI / 6.0; line(g, float2(880.0, 480.0), float2(880.0 + cos(a) * 130.0, 480.0 + sin(a) * 130.0), float3(1.0, 0.5, 1.0), true) }
    text_lines(g, "SDL GPU / VECTOR DISPLAY", float2(100.0, 850.0), float3(0.4, 1.0, 0.6))
    var acquired_lines = upload_geometry(device, g) |> sdl_try; r.lines = acquired_lines
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR))
    if (r.sampler == null) { return err(sdl_error("Vector sampler"), type<SdlUnit>) }
    var target = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT); target.blend_state.enable_blend = true; target.blend_state.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
    let additive <- array(target); let intermediate <- array(gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT)); let final <- array(gpu_color_target(format))
    var acquired_line = pass_pipeline(device, shaders::vectordisplay_vertex, shaders::vectordisplay_vertex_reflect, shaders::vectordisplay_line, shaders::vectordisplay_line_reflect, additive, true, false) |> sdl_try; r.line = acquired_line
    var acquired_blur = pass_pipeline(device, shaders::vectordisplay_screen, shaders::vectordisplay_screen_reflect, shaders::vectordisplay_blur, shaders::vectordisplay_blur_reflect, intermediate, false, false) |> sdl_try; r.blur = acquired_blur
    var acquired_persist = pass_pipeline(device, shaders::vectordisplay_screen, shaders::vectordisplay_screen_reflect, shaders::vectordisplay_persist, shaders::vectordisplay_persist_reflect, intermediate, false, false) |> sdl_try; r.persist = acquired_persist
    var acquired_compose = pass_pipeline(device, shaders::vectordisplay_screen, shaders::vectordisplay_screen_reflect, shaders::vectordisplay_compose, shaders::vectordisplay_compose_reflect, final, false, false) |> sdl_try; r.compose = acquired_compose
    return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    if (r.size != uint2(width, height)) {
        for (t in fixed_array(r.image, r.ping, r.pong, r.history_a, r.history_b)) { if (t != null) { SDL_ReleaseGPUTexture(device, t) } }
        r.image = null; r.ping = null; r.pong = null; r.history_a = null; r.history_b = null; r.first = true; r.size = uint2(0u)
        let usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER
        var acquired_image = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.image = acquired_image
        var acquired_ping = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.ping = acquired_ping
        var acquired_pong = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.pong = acquired_pong
        var acquired_history_a = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.history_a = acquired_history_a
        var acquired_history_b = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.history_b = acquired_history_b
        r.size = uint2(width, height)
    }
    if (r.first || settings.reset) {
        let clear <- array(attachment(r.history_a))
        with_native_gpu_render_pass(command, clear) $(var pass_ : SDL_GPURenderPass?&) { return sdl_ok() } |> sdl_try
        r.first = false
    }
    if (!settings.paused) { r.angle = time }
    let targets <- array(attachment(r.image))
    with_native_gpu_render_pass(command, targets) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.line)
        push_gpu_dsl_vertex_uniform(command, 0u, shaders::Params(values = float4(r.angle, 0.0, 0.0, 0.0))) |> sdl_try
        return draw_geometry(pass_, r.lines)
    } |> sdl_try
    push_gpu_dsl_fragment_uniform(command, 0u, shaders::Params(values = float4(1.0 / float(width), 0.0, 0.0, 0.0))) |> sdl_try
    var images <- array(r.image); fullscreen(command, r.blur, r.ping, images, r.sampler) |> sdl_try
    push_gpu_dsl_fragment_uniform(command, 0u, shaders::Params(values = float4(0.0, 1.0 / float(height), 0.0, 0.0))) |> sdl_try
    images[0] = r.ping; fullscreen(command, r.blur, r.pong, images, r.sampler) |> sdl_try
    push_gpu_dsl_fragment_uniform(command, 0u, shaders::Params(values = float4(0.0, 0.0, settings.mode == 2 ? 0.0 : 0.85, 0.0))) |> sdl_try
    images <- array(r.pong, r.history_a); fullscreen(command, r.persist, r.history_b, images, r.sampler) |> sdl_try
    push_gpu_dsl_fragment_uniform(command, 0u, shaders::Params(values = float4(0.0, 0.0, 0.0, settings.mode == 1 ? 0.0 : 0.5))) |> sdl_try
    images <- array(r.image, r.history_b); fullscreen(command, r.compose, output, images, r.sampler) |> sdl_try
    var tmp = r.history_a; r.history_a = r.history_b; r.history_b = tmp
    return sdl_ok()
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
            set_title(window, "Vector display: glow / phosphor persistence | M: mode {settings.mode} | Space: pause | R: reset") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
