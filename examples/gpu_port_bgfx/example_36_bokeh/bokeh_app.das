options gen2
module bokeh_app shared public
require ../common/post_scene/scene.das as scene public
require ./shaders/bokeh_shaders.das as shaders
require daslib/defer
struct Settings { enabled : bool = true; single : bool; debug : bool; max_blur : float = 20.0; focus : float = 5.0; focus_scale : float = 3.0; radius_scale : float = 0.5; lobes : int = 6; pinch : float = 0.2; rotation : float }
struct Resources { downsample, blurred, linear_depth : SDL_GPUTexture ?; pipelines : array<SDL_GPUGraphicsPipeline?>; sampler : SDL_GPUSampler ?; size : uint2 }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() { for (resource in fixed_array(r.downsample, r.blurred, r.linear_depth)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }; for (p in r.pipelines) { SDL_ReleaseGPUGraphicsPipeline(device, p) }; if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) } }
    let shaders_data = fixed_array(shaders::bokeh_downsample, shaders::bokeh_half, shaders::bokeh_single, shaders::bokeh_combine, shaders::bokeh_copy, shaders::bokeh_debug, shaders::bokeh_depth)
    let reflections = fixed_array(shaders::bokeh_downsample_reflect, shaders::bokeh_half_reflect, shaders::bokeh_single_reflect, shaders::bokeh_combine_reflect, shaders::bokeh_copy_reflect, shaders::bokeh_debug_reflect, shaders::bokeh_depth_reflect)
    for (i in range(7)) { let colors <- array(SDL_GPUColorTargetDescription(format = i == 6 ? SDL_GPUTextureFormat.TEXTUREFORMAT_R32_FLOAT : i < 2 ? SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT : format)); var p = pass_pipeline(device, shaders::bokeh_screen, shaders::bokeh_screen_reflect, shaders_data[i], reflections[i], colors, false, false) |> sdl_try; push(r.pipelines, p) }
    r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR)); if (r.sampler == null) { return err(sdl_error("Bokeh sampler"), type<SdlUnit>) }; return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var world : scene::Scene; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; s : Settings; camera : scene::Camera; time : float; frame : uint) : SdlStatus {
    let halfsize = uint2(max(1u, width / 2u), max(1u, height / 2u))
    if (r.size != uint2(width, height)) { for (resource in fixed_array(r.downsample, r.blurred, r.linear_depth)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }; r.downsample = null; r.blurred = null; r.linear_depth = null
        var image = texture(device, halfsize.x, halfsize.y, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.downsample = image
        image = texture(device, halfsize.x, halfsize.y, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.blurred = image; r.size = uint2(width, height)
        image = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R32_FLOAT, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.linear_depth = image
    }
    scene::draw_scene(device, command, world, width, height, camera, time, float3(0.0, 6.0, 10.0)) |> sdl_try
    var config = shaders::Config(size = float4(float(width), float(height), float(frame % 8u), 0.0), focus = float4(s.max_blur, s.focus, s.focus_scale, s.radius_scale), shape = float4(float(s.lobes), 1.0 - s.pinch, 2.0 * s.pinch, s.rotation))
    push_gpu_dsl_fragment_uniform(command, 0u, config) |> sdl_try
    var sources <- array(world.depth); fullscreen(command, r.pipelines[6], r.linear_depth, sources, r.sampler) |> sdl_try
    sources <- array(world.color, r.linear_depth)
    if (!s.enabled || s.debug || s.single) { return fullscreen(command, r.pipelines[!s.enabled ? 4 : s.debug ? 5 : 2], output, sources, r.sampler) }
    config.focus.x *= 0.5; config.focus.w *= 0.5; config.size.x = float(halfsize.x); config.size.y = float(halfsize.y)
    push_gpu_dsl_fragment_uniform(command, 0u, config) |> sdl_try
    fullscreen(command, r.pipelines[0], r.downsample, sources, r.sampler) |> sdl_try
    sources <- array(r.downsample, r.linear_depth); fullscreen(command, r.pipelines[1], r.blurred, sources, r.sampler) |> sdl_try
    sources <- array(world.color, r.blurred); return fullscreen(command, r.pipelines[3], output, sources, r.sampler)
}
def panel(var s : Settings) {
    SetNextWindowPos(ImVec2(600.0, 10.0), ImGuiCond.FirstUseEver); SetNextWindowSize(ImVec2(350.0, 550.0), ImGuiCond.FirstUseEver)
    if (Begin("Settings")) {
        Checkbox("use bokeh dof", unsafe(addr(s.enabled))); Checkbox("use single pass at full res", unsafe(addr(s.single))); Checkbox("show debug vis", unsafe(addr(s.debug)))
        SliderFloat("max blur size", unsafe(addr(s.max_blur)), 10.0, 50.0); SliderFloat("focusPoint", unsafe(addr(s.focus)), 1.0, 20.0); SliderFloat("focusScale", unsafe(addr(s.focus_scale)), 0.0, 10.0)
        SliderFloat("radiusScale", unsafe(addr(s.radius_scale)), 0.5, 4.0); SliderInt("lobe count", unsafe(addr(s.lobes)), 1, 8); SliderFloat("lobe pinch", unsafe(addr(s.pinch)), 0.0, 1.0); SliderFloat("lobe rotation", unsafe(addr(s.rotation)), -1.0, 1.0)
        var radius = s.radius_scale; var samples = 1
        while (radius < s.max_blur) { samples++; radius += s.radius_scale / radius }
        Text("Number of samples taken: {samples}")
        let origin = GetCursorScreenPos(); Dummy(ImVec2(128.0, 128.0)); var list = GetWindowDrawList()
        unsafe { *list |> AddRectFilled(origin, origin + float2(128.0), 0xff101010u, 0.0, ImDrawFlags.None) }
        var angle = 0.0; radius = s.radius_scale
        while (radius < s.max_blur) { let shape = s.lobes <= 1 ? 1.0 : abs(fract(angle * float(s.lobes) / 6.2831853 + s.rotation) - 0.5) * 2.0 * s.pinch + 1.0 - s.pinch
            let point = origin + float2(64.0) + float2(cos(angle), sin(angle)) * radius * shape * (60.0 / s.max_blur)
            unsafe { *list |> AddCircleFilled(point, 0.6, 0xffffffffu, 4) }; angle += 2.39996323; radius += s.radius_scale / radius
        }
        Text("WASD: move | Arrows: look")
    }; End()
}
def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_imgui_gpu(window, device) {
        DisableIniPersistence(); StyleColorsDark()
        return scene::with_scene(device, 45) $(var world) {
            return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
                var settings = Settings(); var camera = scene::Camera(eye = float3(0.0, 2.5, -20.0)); var raw = SDL_MakeEvent(); var running = true; var frames = 0u; var time = 0.0; var last = SDL_GetTicks()
                while (running) {
                    while (is_some(poll_event(raw))) { ImGui_SDL3_ProcessEvent(raw); let e = decode_event(raw); if (should_close(e, window) && (!(e is key_down) || !ImGui_SDL3_WantCaptureKeyboard())) { running = false }; if (!ImGui_SDL3_WantCaptureKeyboard()) { scene::camera_event(e, camera) } }
                    if (!running) { break }
                    begin_gui(); panel(settings); Render()
                    let now = SDL_GetTicks(); time += float(now - last) * 0.001; last = now
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
