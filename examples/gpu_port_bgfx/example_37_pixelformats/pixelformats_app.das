options gen2
module pixelformats_app shared public
require ../common/imgui_gpu.das public
require ../common/texture_payload.das
require ./format_catalog.das
require ./shaders/pixelformats_shaders.das as shaders
require daslib/defer
struct Entry { description : Sample; texture, preview : SDL_GPUTexture ?; supported : bool }
struct Settings { sample, selected : int; alpha : bool = true; animate : bool; preview : float = 80.0 }
struct Resources { entries : array<Entry>; pipeline : SDL_GPUGraphicsPipeline ?; sampler : SDL_GPUSampler ? }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
 var r = Resources(); defer(){for (e in r.entries){if (e.texture != null){SDL_ReleaseGPUTexture(device, e.texture)}; if (e.preview != null){SDL_ReleaseGPUTexture(device, e.preview)}}; if (r.pipeline != null){SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline)}; if (r.sampler != null){SDL_ReleaseGPUSampler(device, r.sampler)}}
 r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR)); if (r.sampler == null){return err(sdl_error("sampler"), type<SdlUnit>)}
 let colors <- array(gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)); var pipe = pass_pipeline(device, shaders::pixelformats_screen, shaders::pixelformats_screen_reflect, shaders::pixelformats_preview, shaders::pixelformats_preview_reflect, colors, false, false) |> sdl_try; r.pipeline = pipe
 let catalog <- samples()
 for (s in catalog){var e = Entry(description = s, supported = SDL_GPUTextureSupportsFormat(device, s.format, SDL_GPUTextureType.TEXTURETYPE_2D, SDL_GPU_TEXTUREUSAGE_SAMPLER)); push(r.entries, e); let i = length(r.entries) - 1
  if (e.supported){var tex = load_texture_payload(device, s.file, s.format) |> sdl_try; r.entries[i].texture = tex
   tex = texture(device, s.width, s.height, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) |> sdl_try; r.entries[i].preview = tex}
 }
 return body(r)
}
def draw_previews(command : SDL_GPUCommandBuffer?; var r : Resources; settings : Settings; time : float) : SdlStatus {
 for (e in r.entries){if (e.supported && e.description.set_index == settings.sample){push_gpu_dsl_fragment_uniform(command, 0u, shaders::Config(values = float4(settings.alpha ? 1.0 : 0.0, settings.animate ? time : 0.0, float(e.description.width), float(e.description.height)))) |> sdl_try; var images <- array(e.texture); fullscreen(command, r.pipeline, e.preview, images, r.sampler) |> sdl_try}}
 return sdl_ok()
}
def gui(device : SDL_GPUDevice?; var r : Resources; var settings : Settings){
 SetNextWindowPos(ImVec2(10.0, 10.0), ImGuiCond.FirstUseEver); SetNextWindowSize(ImVec2(940.0, 690.0), ImGuiCond.FirstUseEver)
 if (Begin("Pixel formats")){
  SliderInt("Sample: hue / alpha / UV / compression", unsafe(addr(settings.sample)), 0, 3); SliderFloat("Preview size", unsafe(addr(settings.preview)), 24.0, 256.0); Checkbox("Alpha", unsafe(addr(settings.alpha))); SameLine(); Checkbox("Animate", unsafe(addr(settings.animate)))
  Text("Unsupported GPU formats are not created. Integer/depth formats are excluded as in bgfx.")
  Text("BC4/5/6H: no source in this set. ETC/ATC/PVRTC: no SDL GPU format.")
  if (r.entries[settings.selected].description.set_index != settings.sample) { for (i in range(length(r.entries))) { if (r.entries[i].description.set_index == settings.sample && r.entries[i].description.name == "R8G8B8A8_UNORM") { settings.selected = i; break } } }
  if (BeginTable("Formats", 10, ImGuiTableFlags.Borders)){
   for (i in range(length(r.entries))){let e = r.entries[i]; if (e.description.set_index != settings.sample){continue}; TableNextColumn(); if (Button(e.description.name, ImVec2(settings.preview, 0.0))){settings.selected = i}
    if (e.supported){Image(ImTextureRef(unsafe(reinterpret<uint64>(e.preview))), ImVec2(settings.preview, settings.preview), ImVec2(0.0), ImVec2(1.0))}else{Text("Unsupported")}
   }; EndTable()
  }
  let selected = r.entries[settings.selected]; Text("Selected: {selected.description.name}")
  let rt = SDL_GPUTextureSupportsFormat(device, selected.description.format, SDL_GPUTextureType.TEXTURETYPE_2D, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)
  Text("Sampled: {selected.supported} | Color target: {rt}")
  if (selected.supported){Image(ImTextureRef(unsafe(reinterpret<uint64>(selected.preview))), ImVec2(256.0), ImVec2(0.0), ImVec2(1.0))}
 }; End()
}
def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
 return with_imgui_gpu(window, device){DisableIniPersistence(); StyleColorsDark(); return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r){
  var settings = Settings(); var event = SDL_MakeEvent(); var running = true; var frames = 0; let start = SDL_GetTicks()
  while (running){while (is_some(poll_event(event))){ImGui_SDL3_ProcessEvent(event); if (should_close(decode_event(event), window)){running = false}}; if (!running){break}
   begin_gui(); gui(device, r, settings); Render()
   with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint){draw_previews(command, r, settings, float(SDL_GetTicks() - start) * 0.001) |> sdl_try
    let targets <- array(attachment(output, float4(0.188, 0.188, 0.188, 1.0))); with_native_gpu_render_pass(command, targets) $(var pass_){return sdl_ok()} |> sdl_try; return draw_gui(command, output)} |> sdl_try
   frames++; if (smoke && frames >= 4){break}
  }; return sdl_ok()
 }}
}
