options gen2
module sss_app shared public
require ../common/post_scene/scene.das as scene public
require ./shaders/sss_shaders.das as shaders
require daslib/defer
struct Settings { pixels : bool; radius : float = 0.25; pixel_radius : float = 25.0; steps : int = 8; softness : int; noise : bool = true; dynamic_noise : bool = true; shadows_only : bool; move_light : bool = true }
struct Resources { linear, shadows : SDL_GPUTexture ?; depth_pass, shadow_pass, combine_pass : SDL_GPUGraphicsPipeline ?; sampler : SDL_GPUSampler ?; size : uint2 }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() { for (resource in fixed_array(r.linear, r.shadows)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }; for (resource in fixed_array(r.depth_pass, r.shadow_pass, r.combine_pass)) { if (resource != null) { SDL_ReleaseGPUGraphicsPipeline(device, resource) } }; if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) } }
    let colors <- array(SDL_GPUColorTargetDescription(format = SDL_GPUTextureFormat.TEXTUREFORMAT_R32_FLOAT))
    var p = pass_pipeline(device, shaders::sss_screen, shaders::sss_screen_reflect, shaders::sss_depth, shaders::sss_depth_reflect, colors, false, false) |> sdl_try; r.depth_pass = p
    p = pass_pipeline(device, shaders::sss_screen, shaders::sss_screen_reflect, shaders::sss_shadow, shaders::sss_shadow_reflect, colors, false, false) |> sdl_try; r.shadow_pass = p
    let target <- array(SDL_GPUColorTargetDescription(format = format))
    p = pass_pipeline(device, shaders::sss_screen, shaders::sss_screen_reflect, shaders::sss_combine, shaders::sss_combine_reflect, target, false, false) |> sdl_try; r.combine_pass = p
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info()); if (r.sampler == null) { return err(sdl_error("SSS sampler"), type<SdlUnit>) }
    return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var world : scene::Scene; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; settings : Settings; camera : scene::Camera; time : float; frame : uint) : SdlStatus {
    if (r.size != uint2(width, height)) {
        for (resource in fixed_array(r.linear, r.shadows)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }; r.linear = null; r.shadows = null
        var image = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R32_FLOAT, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.linear = image
        image = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R32_FLOAT, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.shadows = image; r.size = uint2(width, height)
    }
    let light = float3(cos(time * 0.75) * 3.0, 1.5, sin(time * 0.75) * 3.0)
    scene::draw_scene(device, command, world, width, height, camera, 0.0, light) |> sdl_try
    let config = shaders::Config(view = world.view, projection = world.projection, size = float4(float(width), float(height), settings.dynamic_noise ? float(frame % 8u) : 0.0, 0.0), light = world.view * float4(light, 1.0), settings = float4(settings.pixels ? settings.pixel_radius : settings.radius, float(settings.steps), float(settings.softness), 0.0), controls = float4(settings.pixels ? 1.0 : 0.0, settings.noise ? 1.0 : 0.0, settings.shadows_only ? 1.0 : 0.0, 0.0))
    push_gpu_dsl_fragment_uniform(command, 0u, config) |> sdl_try
    var sources <- array(world.depth); fullscreen(command, r.depth_pass, r.linear, sources, r.sampler) |> sdl_try
    sources <- array(r.linear); fullscreen(command, r.shadow_pass, r.shadows, sources, r.sampler) |> sdl_try
    sources <- array(world.color, world.normal, r.linear, r.shadows)
    return fullscreen(command, r.combine_pass, output, sources, r.sampler)
}
def panel(var s : Settings) {
    SetNextWindowPos(ImVec2(600.0, 10.0), ImGuiCond.FirstUseEver); SetNextWindowSize(ImVec2(350.0, 360.0), ImGuiCond.FirstUseEver)
    if (Begin("Settings")) {
        Text("shadow controls:")
        Checkbox("screen space radius", unsafe(addr(s.pixels)))
        if (s.pixels) { SliderFloat("radius in pixels", unsafe(addr(s.pixel_radius)), 1.0, 100.0) } else { SliderFloat("radius in world units", unsafe(addr(s.radius)), 0.001, 1.0) }
        SliderInt("shadow steps", unsafe(addr(s.steps)), 1, 64)
        let modes = fixed_array("hard", "soft", "very soft")
        if (BeginCombo("contact shadows mode", modes[s.softness])) { for (i in range(3)) { if (Selectable(modes[i], s.softness == i)) { s.softness = i } }; EndCombo() }
        Checkbox("add random offset", unsafe(addr(s.noise))); Checkbox("different offset each frame", unsafe(addr(s.dynamic_noise)))
        Separator(); Text("scene controls:")
        Checkbox("display shadows only", unsafe(addr(s.shadows_only))); Checkbox("move light", unsafe(addr(s.move_light)))
        Text("WASD: move | Arrows: look")
    }; End()
}
def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_imgui_gpu(window, device) {
        DisableIniPersistence(); StyleColorsDark()
        return scene::with_scene(device, 44) $(var world) {
            return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
                var settings = Settings(); var camera = scene::Camera(eye = float3(0.0, 1.5, -4.0)); var raw = SDL_MakeEvent(); var running = true; var frames = 0u; var time = 0.0; var last = SDL_GetTicks()
                while (running) {
                    while (is_some(poll_event(raw))) { ImGui_SDL3_ProcessEvent(raw); let e = decode_event(raw); if (should_close(e, window) && (!(e is key_down) || !ImGui_SDL3_WantCaptureKeyboard())) { running = false }; if (!ImGui_SDL3_WantCaptureKeyboard()) { scene::camera_event(e, camera) } }
                    if (!running) { break }
                    begin_gui(); panel(settings); Render()
                    let now = SDL_GetTicks(); if (settings.move_light) { time += float(now - last) * 0.001 }; last = now
                    with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) {
                        draw(device, command, world, r, output, width, height, settings, camera, time, frames) |> sdl_try
                        return draw_gui(command, output)
                    } |> sdl_try
                    frames++; if (smoke && frames >= 3u) { break }
                }; return sdl_ok()
            }
        }
    }
}
