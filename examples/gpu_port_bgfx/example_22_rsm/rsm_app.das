// Adapted from bgfx 31-rsm; see the example README and group LICENSE-bgfx.txt.
options gen2
module rsm_app shared public
require ../common/multipass_support.das public
require ./shaders/rsm_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { mode : int; paused : bool; reset : bool; bounce : float = 0.25; radius : float = 3.0; azimuth : float = 215.0; elevation : float = 35.0 }
struct Resources { cube : GeometryBuffers; gbuffer, reflective, combine : SDL_GPUGraphicsPipeline ?; gpos, gnormal, albedo, depth, rpos, rnormal, flux, shadow : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; size : uint2; angle : float }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() {
        release(device, r.cube)
        for (resource in fixed_array(r.gbuffer, r.reflective, r.combine)) { if (resource != null) { SDL_ReleaseGPUGraphicsPipeline(device, resource) } }
        for (resource in fixed_array(r.gpos, r.gnormal, r.albedo, r.depth, r.rpos, r.rnormal, r.flux, r.shadow)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }
        if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
    }
    let cube <- cube_geometry(); var g = upload_geometry(device, cube) |> sdl_try; r.cube = g
    let usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER
    var t = texture(device, 256u, 256u, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.rpos = t
    t = texture(device, 256u, 256u, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.rnormal = t
    t = texture(device, 256u, 256u, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.flux = t
    t = texture(device, 256u, 256u, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.shadow = t
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_NEAREST))
    if (r.sampler == null) { return err(sdl_error("RSM sampler"), type<SdlUnit>) }
    let mrt <- array(gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT), gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT), gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT))
    var p = pass_pipeline(device, shaders::rsm_vertex, shaders::rsm_vertex_reflect, shaders::rsm_gbuffer, shaders::rsm_gbuffer_reflect, mrt) |> sdl_try; r.gbuffer = p
    p = pass_pipeline(device, shaders::rsm_vertex, shaders::rsm_vertex_reflect, shaders::rsm_reflective, shaders::rsm_reflective_reflect, mrt) |> sdl_try; r.reflective = p
    let final <- array(gpu_color_target(format)); p = pass_pipeline(device, shaders::rsm_screen, shaders::rsm_screen_reflect, shaders::rsm_combine, shaders::rsm_combine_reflect, final, false, false) |> sdl_try; r.combine = p
    return body(r)
}
def scene(command : SDL_GPUCommandBuffer?; pass_ : SDL_GPURenderPass?; var r : Resources; vp : float4x4; light : float3) : SdlStatus {
    let positions = fixed_array(float3(0.0, -3.0, 2.0), float3(-7.0, 1.0, 2.0), float3(7.0, 1.0, 2.0), float3(0.0, 1.0, 10.0), float3(-2.5, -1.0, 2.0), float3(2.5, -1.7, 0.0))
    let scales = fixed_array(float3(7.0, 0.2, 8.0), float3(0.2, 4.0, 8.0), float3(0.2, 4.0, 8.0), float3(7.0, 4.0, 0.2), float3(1.3, 2.0, 1.3), float3(1.2))
    let colors = fixed_array(float3(0.8), float3(0.9, 0.08, 0.04), float3(0.06, 0.85, 0.15), float3(0.7), float3(0.9), float3(0.8))
    for (i in 0..6) {
        push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model_matrix(positions[i], scales[i], i >= 4 ? r.angle : 0.0), vp = vp)) |> sdl_try
        push_gpu_dsl_fragment_uniform(command, 0u, shaders::Surface(tint = float4(colors[i], 1.0), light = float4(light, 1.0))) |> sdl_try
        draw_geometry(pass_, r.cube) |> sdl_try
    }
    return sdl_ok()
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    if (r.size != uint2(width, height)) {
        for (resource in fixed_array(r.gpos, r.gnormal, r.albedo, r.depth)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }
        r.gpos = null; r.gnormal = null; r.albedo = null; r.depth = null; r.size = uint2(0u)
        let usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER
        var t = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.gpos = t
        t = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.gnormal = t
        t = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, usage) |> sdl_try; r.albedo = t
        t = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET) |> sdl_try; r.depth = t; r.size = uint2(width, height)
    }
    if (!settings.paused) { r.angle = time * 0.2 }; if (settings.reset) { r.angle = 0.0 }
    let el=settings.elevation*0.01745329252;let az=settings.azimuth*0.01745329252
    let light=float3(cos(el)*cos(az),sin(el),cos(el)*sin(az))*10.0; let light_vp = ortho(12.0, 0.1, 40.0) * look_at_lh(light, float3(0.0, 0.0, 3.0), float3(0.0, 1.0, 0.0))
    let reflective <- array(attachment(r.rpos), attachment(r.rnormal), attachment(r.flux)); var depth = depth_attachment(r.shadow); depth.store_op = SDL_GPUStoreOp.STOREOP_STORE
    with_native_gpu_render_pass(command, reflective, depth) $(var pass_ : SDL_GPURenderPass?&) { SDL_BindGPUGraphicsPipeline(pass_, r.reflective); return scene(command, pass_, r, light_vp, light) } |> sdl_try
    let geometry <- array(attachment(r.gpos), attachment(r.gnormal), attachment(r.albedo)); depth = depth_attachment(r.depth)
    with_native_gpu_render_pass(command, geometry, depth) $(var pass_ : SDL_GPURenderPass?&) { SDL_BindGPUGraphicsPipeline(pass_, r.gbuffer); return scene(command, pass_, r, camera_matrix(width, height, float3(0.0, 3.0, -22.0), float3(0.0, 0.0, 3.0)), light) } |> sdl_try
    push_gpu_dsl_fragment_uniform(command, 0u, shaders::Resolve(light_vp = light_vp, light = float4(light, 1.0), config = float4(float(settings.mode), settings.bounce, settings.radius, 0.0))) |> sdl_try
    var images <- array(r.gpos, r.gnormal, r.albedo, r.rpos, r.rnormal, r.flux, r.shadow)
    return fullscreen(command, r.combine, output, images, r.sampler)
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var settings = Settings(); var running = true; var frames = 0; var start = SDL_GetTicks()
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
            if (settings.reset) { start = SDL_GetTicks() }
            let time = float(SDL_GetTicks() - start) * 0.001
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            settings.reset = false
            set_title(window, "Reflective shadow maps | M: bounce/direct/flux | M: mode {settings.mode} | Space: pause | R: reset") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
