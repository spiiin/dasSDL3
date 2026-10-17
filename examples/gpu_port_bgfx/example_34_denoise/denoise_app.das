options gen2
module denoise_app shared public
require ../common/post_scene/scene.das as scene public
require ./shaders/denoise_shaders.das as shaders
require daslib/defer
struct Settings { noise : int = 2; dynamic_noise : bool = true; temporal : bool = true; passes : int = 5; extent : int = 1; sigma_depth : float = 0.05; sigma_normal : float = 128.0; txaa : bool; mitchell : bool = true; feedback_min : float = 0.8; feedback_max : float = 0.95; slow : bool }
struct Resources { images : array<SDL_GPUTexture?>; pipelines : array<SDL_GPUGraphicsPipeline?>; sampler, linear : SDL_GPUSampler ?; size : uint2; valid : bool; last_txaa : bool; previous_jitter : float2 }
def clear_images(device : SDL_GPUDevice?; var r : Resources) { for (i in r.images) { SDL_ReleaseGPUTexture(device, i) }; clear(r.images); r.valid = false }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() { clear_images(device, r); for (p in r.pipelines) { SDL_ReleaseGPUGraphicsPipeline(device, p) }; if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }; if (r.linear != null) { SDL_ReleaseGPUSampler(device, r.linear) } }
    let data = fixed_array(shaders::denoise_noisy, shaders::denoise_temporal, shaders::denoise_spatial, shaders::denoise_apply, shaders::denoise_copy, shaders::denoise_txaa)
    let refs = fixed_array(shaders::denoise_noisy_reflect, shaders::denoise_temporal_reflect, shaders::denoise_spatial_reflect, shaders::denoise_apply_reflect, shaders::denoise_copy_reflect, shaders::denoise_txaa_reflect)
    for (i in range(7)) { let colors <- array(SDL_GPUColorTargetDescription(format = i == 6 ? format : SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT)); var p = pass_pipeline(device, shaders::denoise_screen, shaders::denoise_screen_reflect, data[i == 6 ? 4 : i], refs[i == 6 ? 4 : i], colors, false, false) |> sdl_try; push(r.pipelines, p) }
    r.linear = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR)); r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info()); if (r.sampler == null || r.linear == null) { return err(sdl_error("Denoise sampler"), type<SdlUnit>) }; return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var world : scene::Scene; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; s : Settings; camera : scene::Camera; time : float; frame : uint) : SdlStatus {
    if (r.size != uint2(width, height)) { clear_images(device, r); for (i in range(7)) { var t = texture(device, width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; push(r.images, t) }; r.size = uint2(width, height) }
    if (s.txaa != r.last_txaa) { r.valid = false; world.initialized = false }; r.last_txaa = s.txaa
    let offsets = fixed_array(float2(0.5, 1.0 / 3.0), float2(0.25, 2.0 / 3.0), float2(0.75, 1.0 / 9.0), float2(0.125, 4.0 / 9.0), float2(0.625, 7.0 / 9.0), float2(0.375, 2.0 / 9.0), float2(0.875, 5.0 / 9.0), float2(0.0625, 8.0 / 9.0))
    let jitter = s.txaa ? offsets[frame % 8u] - float2(7.125 / 16.0, 0.5) : float2(0.0)
    scene::draw_scene(device, command, world, width, height, camera, time, float3(0.0), jitter) |> sdl_try
    var config = shaders::Config(size = float4(float(width), float(height), s.dynamic_noise ? float(frame % 8u) : 0.0, 0.0), noise = float4(float(s.noise), jitter.x - r.previous_jitter.x, jitter.y - r.previous_jitter.y, 0.0), spatial = float4(s.sigma_depth, s.sigma_normal, 1.0, float(s.extent + 1)), temporal = float4(s.feedback_min, s.feedback_max, s.mitchell ? 1.0 : 0.0, 0.0))
    push_gpu_dsl_fragment_uniform(command, 0u, config) |> sdl_try
    // 0/1 ping-pong, 2 previous first spatial pass, 3 previous normal,
    // 4 previous TXAA, 5 current TXAA, 6 lit color. History stays on the GPU.
    var sources <- array(world.normal); fullscreen(command, r.pipelines[0], r.images[0], sources, r.sampler) |> sdl_try; var last = 0
    if (s.temporal && r.valid) { sources <- array(r.images[0], world.normal, world.velocity, r.images[2], r.images[3]); fullscreen(command, r.pipelines[1], r.images[1], sources, r.sampler) |> sdl_try; last = 1 }
    for (i in range(s.passes)) {
        let target = i == 0 ? 2 : last == 0 ? 1 : 0
        config.spatial.z = float(1 << i); push_gpu_dsl_fragment_uniform(command, 0u, config) |> sdl_try
        sources <- array(r.images[last], world.normal, world.depth); fullscreen(command, r.pipelines[2], r.images[target], sources, r.sampler) |> sdl_try; last = target
    }
    if (s.passes == 0) { sources <- array(r.images[last]); fullscreen(command, r.pipelines[4], r.images[2], sources, r.sampler) |> sdl_try }
    sources <- array(r.images[last], world.color); fullscreen(command, r.pipelines[3], r.images[6], sources, r.sampler) |> sdl_try; last = 6
    if (s.txaa && r.valid) { sources <- array(r.images[6], r.images[4], world.velocity, world.depth); fullscreen(command, r.pipelines[5], r.images[5], sources, r.linear) |> sdl_try; last = 5 }
    sources <- array(r.images[last]); fullscreen(command, r.pipelines[4], r.images[4], sources, r.sampler) |> sdl_try
    fullscreen(command, r.pipelines[6], output, sources, r.sampler) |> sdl_try
    sources <- array(world.normal); fullscreen(command, r.pipelines[4], r.images[3], sources, r.sampler) |> sdl_try; r.valid = true; r.previous_jitter = jitter
    return sdl_ok()
}
def panel(var s : Settings) {
    SetNextWindowPos(ImVec2(600.0, 10.0), ImGuiCond.FirstUseEver); SetNextWindowSize(ImVec2(350.0, 480.0), ImGuiCond.FirstUseEver)
    if (Begin("Settings")) {
        let modes = fixed_array("none", "dither", "random"); if (BeginCombo("noise type", modes[s.noise])) { for (i in range(3)) { if (Selectable(modes[i], s.noise == i)) { s.noise = i } }; EndCombo() }
        Checkbox("dynamic noise", unsafe(addr(s.dynamic_noise))); Separator(); Text("temporal denoise pass controls:"); Checkbox("use temporal pass", unsafe(addr(s.temporal)))
        Separator(); Text("spatial denoise pass controls:"); SliderInt("spatial passes", unsafe(addr(s.passes)), 0, 6)
        let extents = fixed_array("three", "five"); if (BeginCombo("spatial sample extent", extents[s.extent])) { for (i in range(2)) { if (Selectable(extents[i], s.extent == i)) { s.extent = i } }; EndCombo() }
        SliderFloat("sigma depth", unsafe(addr(s.sigma_depth)), 0.0, 0.1); SliderFloat("sigma normal", unsafe(addr(s.sigma_normal)), 1.0, 256.0)
        Separator(); Checkbox("use TXAA", unsafe(addr(s.txaa))); Checkbox("apply Mitchell filter", unsafe(addr(s.mitchell))); SliderFloat("feedback min", unsafe(addr(s.feedback_min)), 0.0, 1.0); SliderFloat("feedback max", unsafe(addr(s.feedback_max)), 0.0, 1.0); Checkbox("debug TXAA with slow frame rate", unsafe(addr(s.slow))); Text("WASD: move | Arrows: look")
    }; End()
}
def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_imgui_gpu(window, device) {
        DisableIniPersistence(); StyleColorsDark()
        return scene::with_scene(device, 43) $(var world) {
            return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
                var settings = Settings(); var camera = scene::Camera(eye = float3(0.0, 1.5, 0.0)); var raw = SDL_MakeEvent(); var running = true; var frames = 0u; var time = 0.0; var last = SDL_GetTicks()
                while (running) {
                    while (is_some(poll_event(raw))) { ImGui_SDL3_ProcessEvent(raw); let e = decode_event(raw); if (should_close(e, window) && (!(e is key_down) || !ImGui_SDL3_WantCaptureKeyboard())) { running = false }; if (!ImGui_SDL3_WantCaptureKeyboard()) { scene::camera_event(e, camera) } }
                    if (!running) { break }
                    begin_gui(); panel(settings); Render()
                    let now = SDL_GetTicks(); time += float(now - last) * 0.001; last = now
                    with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) {
                        draw(device, command, world, r, output, width, height, settings, camera, time, frames) |> sdl_try
                        return draw_gui(command, output)
                    } |> sdl_try
                    if (settings.slow) { SDL_Delay(100u) }; frames++; if (smoke && frames >= 3u) { break }
                }; return sdl_ok()
            }
        }
    }
}
