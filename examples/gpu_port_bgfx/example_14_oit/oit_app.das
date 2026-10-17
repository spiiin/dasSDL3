options gen2
module oit_app shared public
require ../common/multipass_support.das public
require ./shaders/oit_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int = 1; reverse : bool = false; alpha : float = 0.35 }
struct Resources { cube : GeometryBuffers; weighted, separate, alpha, resolve : SDL_GPUGraphicsPipeline ?; accum, reveal, depth : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; size : uint2 }
def release(device : SDL_GPUDevice?; var r : Resources) {
    release(device, r.cube)
    for (p in fixed_array(r.weighted, r.separate, r.alpha, r.resolve)) { if (p != null) { SDL_ReleaseGPUGraphicsPipeline(device, p) } }
    for (t in fixed_array(r.accum, r.reveal, r.depth)) { if (t != null) { SDL_ReleaseGPUTexture(device, t) } }
    if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r : Resources; defer() { release(device, r) }
    let cube <- cube_geometry(); var g = upload_geometry(device, cube) |> sdl_try; r.cube = g
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_NEAREST))
    if (r.sampler == null) { return err(sdl_error("SDL_CreateGPUSampler"), type<SdlUnit>) }
    var a = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT)
    a.blend_state.enable_blend = true
    a.blend_state.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
    a.blend_state.dst_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
    var b = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16_FLOAT)
    b.blend_state.enable_blend = true; b.blend_state.src_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ZERO
    b.blend_state.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_COLOR
    let colors <- array(a, b)
    var p = pass_pipeline(device, shaders::oit_vertex, shaders::oit_vertex_reflect, shaders::oit_weighted, shaders::oit_weighted_reflect, colors, true, true, false) |> sdl_try; r.weighted = p
    a.blend_state.src_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ZERO
    a.blend_state.dst_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA
    b.blend_state.src_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
    b.blend_state.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
    let separate <- array(a, b)
    p = pass_pipeline(device, shaders::oit_vertex, shaders::oit_vertex_reflect, shaders::oit_separate, shaders::oit_separate_reflect, separate, true, true, false) |> sdl_try; r.separate = p
    var alpha = gpu_color_target(format)
    alpha.blend_state.enable_blend = true; alpha.blend_state.src_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_SRC_ALPHA
    alpha.blend_state.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA
    let alpha_colors <- array(alpha)
    p = pass_pipeline(device, shaders::oit_vertex, shaders::oit_vertex_reflect, shaders::oit_alpha, shaders::oit_alpha_reflect, alpha_colors, true, true, false) |> sdl_try; r.alpha = p
    let output <- array(gpu_color_target(format))
    p = pass_pipeline(device, shaders::oit_fullscreen, shaders::oit_fullscreen_reflect, shaders::oit_resolve, shaders::oit_resolve_reflect, output, false, false) |> sdl_try; r.resolve = p
    return body(r)
}
def resize_targets(device : SDL_GPUDevice?; var r : Resources; width, height : uint) : SdlStatus {
    if (r.size == uint2(width, height)) { return sdl_ok() }
    var depth_size = r.size
    replace_depth(device, r.depth, depth_size, width, height) |> sdl_try
    r.size = uint2(0u)
    for (t in fixed_array(r.accum, r.reveal)) { if (t != null) { SDL_ReleaseGPUTexture(device, t) } }
    r.accum = null; r.reveal = null
    let usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER
    var t = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.accum = t
    t = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16_FLOAT, usage) |> sdl_try; r.reveal = t
    r.size = uint2(width, height)
    return sdl_ok()
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    resize_targets(device, r, width, height) |> sdl_try
    let vp = camera_matrix(width, height, float3(0.0, 3.0, -15.0), float3(0.0))
    var targets : array<SDL_GPUColorTargetInfo>
    if (settings.mode == 0) { targets <- array(attachment(output, float4(0.08, 0.1, 0.15, 1.0))) }
    else { targets <- array(attachment(r.accum, float4(0.0, 0.0, 0.0, settings.mode == 2 ? 1.0 : 0.0)), attachment(r.reveal, float4(settings.mode == 2 ? 0.0 : 1.0))) }
    let depth = depth_attachment(r.depth)
    with_native_gpu_render_pass(command, targets, depth) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, settings.mode == 0 ? r.alpha : (settings.mode == 1 ? r.weighted : r.separate))
        for (order in 0..27) {
            let i = settings.reverse ? 26 - order : order
            let x = i % 3; let y = (i / 3) % 3; let z = i / 9
            let model = model_matrix(float3(float(x - 1) * 2.0, float(y - 1) * 2.0, float(z - 1) * 2.0), float3(1.15), time * 0.25 + float(i) * 0.1)
            push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model, vp = vp)) |> sdl_try
            push_gpu_dsl_fragment_uniform(command, 0u, shaders::Material(color = float4(float(x + 1) / 3.0, float(y + 1) / 3.0, float(z + 1) / 3.0, settings.alpha))) |> sdl_try
            draw_geometry(pass_, r.cube) |> sdl_try
        }
        return sdl_ok()
    } |> sdl_try
    if (settings.mode != 0) {
        push_gpu_dsl_fragment_uniform(command, 0u, shaders::Material(mode = float4(settings.mode == 2 ? 1.0 : 0.0))) |> sdl_try
        var sources <- array(r.accum, r.reveal)
        fullscreen(command, r.resolve, output, sources, r.sampler) |> sdl_try
    }
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
                    elif (k.keycode == SDLK_R) { settings.reverse = !settings.reverse }
                } } if (_) {} }
            }
            if (!running) { break }
            let time = float(SDL_GetTicks() - start) * 0.001
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            set_title(window, "OIT | M: alpha/weighted/separate ({settings.mode}) | R: reverse draw order ({settings.reverse})") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
