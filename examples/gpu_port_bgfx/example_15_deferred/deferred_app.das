options gen2
module deferred_app shared public
require ../common/multipass_support.das public
require ./shaders/deferred_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { lights : int = 512; debug : int = 0; scissor : bool = true }
struct Resources {
    cube : GeometryBuffers
    geometry, lighting, resolve, preview : SDL_GPUGraphicsPipeline?
    albedo, normal, depth, lightmap, stone, bump : SDL_GPUTexture?
    sampler, material_sampler : SDL_GPUSampler?
    size : uint2
}
def release(device : SDL_GPUDevice?; var r : Resources) {
    release(device, r.cube)
    for (p in fixed_array(r.geometry, r.lighting, r.resolve, r.preview)) { if (p != null) { SDL_ReleaseGPUGraphicsPipeline(device, p) } }
    for (t in fixed_array(r.albedo, r.normal, r.depth, r.lightmap, r.stone, r.bump)) { if (t != null) { SDL_ReleaseGPUTexture(device, t) } }
    if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
    if (r.material_sampler != null) { SDL_ReleaseGPUSampler(device, r.material_sampler) }
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r : Resources; defer() { release(device, r) }
    var cube <- cube_geometry()
    let uv = fixed_array(float2(0.0, 0.0), float2(0.0, 1.0), float2(1.0, 1.0), float2(0.0, 0.0), float2(1.0, 1.0), float2(1.0, 0.0))
    for (i in 0..36) { cube.vertices[i * 8 + 6] = uv[i % 6].x; cube.vertices[i * 8 + 7] = uv[i % 6].y }
    var g = upload_geometry(device, cube) |> sdl_try; r.cube = g
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_NEAREST))
    if (r.sampler == null) { return err(sdl_error("Deferred sampler"), type<SdlUnit>) }
    let info = gpu_texture(512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) |> mip_levels(10u)
    r.stone = SDL_CreateGPUTextureRef(device, info)
    if (r.stone == null) { return err(sdl_error("Deferred albedo texture"), type<SdlUnit>) }
    r.bump = SDL_CreateGPUTextureRef(device, info)
    if (r.bump == null) { return err(sdl_error("Deferred normal texture"), type<SdlUnit>) }
    var sampling = gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR)
    sampling.mipmap_mode = SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR; sampling.max_lod = 9.0
    r.material_sampler = SDL_CreateGPUSamplerRef(device, sampling)
    if (r.material_sampler == null) { return err(sdl_error("Deferred material sampler"), type<SdlUnit>) }
    upload_texture(device, r.stone, "fieldstone-rgba.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
    upload_texture(device, r.bump, "fieldstone-n.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
    sdl_scope() {
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        SDL_GenerateMipmapsForGPUTexture(command, r.stone); SDL_GenerateMipmapsForGPUTexture(command, r.bump)
        return native_gpu_submit(command)
    } |> sdl_try
    let gb <- array(gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM), gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
    var p = pass_pipeline(device, shaders::deferred_vertex, shaders::deferred_vertex_reflect, shaders::deferred_geometry, shaders::deferred_geometry_reflect, gb) |> sdl_try; r.geometry = p
    var target = gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)
    target.blend_state.enable_blend = true; target.blend_state.dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
    target.blend_state.src_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ZERO; target.blend_state.dst_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE
    let accumulation <- array(target)
    p = pass_pipeline(device, shaders::deferred_fullscreen, shaders::deferred_fullscreen_reflect, shaders::deferred_light, shaders::deferred_light_reflect, accumulation, false, false) |> sdl_try; r.lighting = p
    let output <- array(gpu_color_target(format))
    p = pass_pipeline(device, shaders::deferred_fullscreen, shaders::deferred_fullscreen_reflect, shaders::deferred_resolve, shaders::deferred_resolve_reflect, output, false, false) |> sdl_try; r.resolve = p
    p = pass_pipeline(device, shaders::deferred_fullscreen, shaders::deferred_fullscreen_reflect, shaders::deferred_debug, shaders::deferred_debug_reflect, output, false, false) |> sdl_try; r.preview = p
    return body(r)
}
def resize_targets(device : SDL_GPUDevice?; var r : Resources; width, height : uint) : SdlStatus {
    if (r.size == uint2(width, height)) { return sdl_ok() }
    for (t in fixed_array(r.albedo, r.normal, r.depth, r.lightmap)) { if (t != null) { SDL_ReleaseGPUTexture(device, t) } }
    r.albedo = null; r.normal = null; r.depth = null; r.lightmap = null; r.size = uint2(0u)
    let usage = SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER
    var t = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, usage) |> sdl_try; r.albedo = t
    t = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, usage) |> sdl_try; r.normal = t
    t = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, usage) |> sdl_try; r.lightmap = t
    t = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.depth = t
    r.size = uint2(width, height); return sdl_ok()
}
def light_scissor(vp : float4x4; center : float3; radius : float; width, height : uint) : SDL_Rect {
    var lo = float2(1.0); var hi = float2(-1.0); var near = false
    for (i in 0..8) {
        let corner = center + float3((i & 1) != 0 ? radius : -radius, (i & 2) != 0 ? radius : -radius, (i & 4) != 0 ? radius : -radius)
        let clip = vp * float4(corner, 1.0)
        if (clip.w <= 0.0 || clip.z <= 0.0) { near = true }
        else { let ndc = clip.xy / clip.w; lo = min(lo, ndc); hi = max(hi, ndc) }
    }
    // Conservative full viewport when the box crosses the near plane.
    if (near) { return SDL_Rect(w = int(width), h = int(height)) }
    let x0 = int(floor(clamp(lo.x * 0.5 + 0.5, 0.0, 1.0) * float(width)))
    let x1 = int(ceil(clamp(hi.x * 0.5 + 0.5, 0.0, 1.0) * float(width)))
    let y0 = int(floor(clamp(0.5 - hi.y * 0.5, 0.0, 1.0) * float(height)))
    let y1 = int(ceil(clamp(0.5 - lo.y * 0.5, 0.0, 1.0) * float(height)))
    return SDL_Rect(x = x0, y = y0, w = max(0, x1 - x0), h = max(0, y1 - y0))
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    resize_targets(device, r, width, height) |> sdl_try
    let eye = float3(0.0, 0.0, -35.0); let vp = camera_matrix(width, height, eye, float3(0.0)); let inv = inverse(vp)
    let colors <- array(attachment(r.albedo, float4(0.0, 0.0, 0.0, 1.0)), attachment(r.normal, float4(0.5, 0.5, 1.0, 1.0)))
    var depth = depth_attachment(r.depth); depth.store_op = SDL_GPUStoreOp.STOREOP_STORE
    with_native_gpu_render_pass(command, colors, depth) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.geometry)
        var images <- array(r.stone, r.bump); bind_images(pass_, images, r.material_sampler) |> sdl_try
        for (y in 0..11) { for (x in 0..11) {
            let model = model_matrix(float3(float(x - 5) * 3.0, float(y - 5) * 3.0, 0.0), float3(1.0), time * 0.2 + float(x + y) * 0.1)
            push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model, vp = vp)) |> sdl_try
            draw_geometry(pass_, r.cube) |> sdl_try
        } }
        return sdl_ok()
    } |> sdl_try
    let accumulation <- array(attachment(r.lightmap))
    with_native_gpu_render_pass(command, accumulation) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.lighting)
        var images <- array(r.normal, r.depth); bind_images(pass_, images, r.sampler) |> sdl_try
        for (i in 0..settings.lights) {
            let fi = float(i); let t = time * (sin(fi / float(settings.lights) * PI * 0.5) * 0.5 + 0.5)
            let position = float3(sin(t + fi * 0.47 + PI * 0.5 * 1.37) * 15.0, cos(t + fi * 0.69 + PI * 0.5 * 1.49) * 15.0, sin(t + fi * 0.37 + PI * 0.5 * 1.57) * 2.0)
            let rect = settings.scissor ? light_scissor(vp, position, 2.0, width, height) : SDL_Rect(w = int(width), h = int(height))
            if (rect.w == 0 || rect.h == 0) { continue }
            SDL_SetGPUScissorRef(pass_, rect)
            let rgb = float3((i & 1) != 0 ? 1.0 : 0.25, (i & 2) != 0 ? 1.0 : 0.25, (i & 4) != 0 ? 1.0 : 0.25)
            push_gpu_dsl_fragment_uniform(command, 0u, shaders::Light(inverse_vp = inv, position_radius = float4(position, 2.0), color_inner = float4(rgb, 0.8), eye = float4(eye, 1.0))) |> sdl_try
            SDL_DrawGPUPrimitives(pass_, 3u, 1u, 0u, 0u)
        }
        return sdl_ok()
    } |> sdl_try
    if (settings.debug != 0) {
        var images <- array(settings.debug == 1 ? r.albedo : (settings.debug == 2 ? r.normal : (settings.debug == 3 ? r.depth : r.lightmap)))
        return fullscreen(command, r.preview, output, images, r.sampler)
    }
    var images <- array(r.albedo, r.lightmap)
    return fullscreen(command, r.resolve, output, images, r.sampler)
}
def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var settings = Settings(); var running = true; var frames = 0; let start = SDL_GetTicks()
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) { running = false }
                match (event) { if (SdlEvent(key_down = $v(k))) { if (!k.repeat) {
                    if (k.keycode == SDLK_L) { settings.lights = settings.lights >= 2048 ? 1 : settings.lights * 2 }
                    elif (k.keycode == SDLK_D) { settings.debug = (settings.debug + 1) % 5 }
                    elif (k.keycode == SDLK_S) { settings.scissor = !settings.scissor }
                } } if (_) {} }
            }
            if (!running) { break }
            let time = float(SDL_GetTicks() - start) * 0.001
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            set_title(window, "Deferred | L: lights {settings.lights} | D: G-buffer {settings.debug} | S: scissor {settings.scissor}") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
