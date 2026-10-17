options gen2
module hextile_app shared public
require ../common/imgui_gpu.das public
require ../common/texture_payload.das
require ./shaders/hextile_shaders.das as shaders
require daslib/defer
struct Settings { regular, weights, paused : bool; rate : int = 10; rotation, time : float }
struct Resources { geometry : GeometryBuffers; pipeline : SDL_GPUGraphicsPipeline ?; image, depth : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; size : uint2 }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
 var r = Resources(); defer(){release(device, r.geometry); if (r.pipeline != null){SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline)}; if (r.image != null){SDL_ReleaseGPUTexture(device, r.image)}; if (r.depth != null){SDL_ReleaseGPUTexture(device, r.depth)}; if (r.sampler != null){SDL_ReleaseGPUSampler(device, r.sampler)}}
 var g = Geometry(); for (p in fixed_array(float3(-1.0, 0.0, -1.0), float3(-1.0, 0.0, 1.0), float3(1.0, 0.0, -1.0), float3(1.0, 0.0, 1.0))){ for (v in fixed_array(p.x, p.y, p.z, 0.0, 1.0, 0.0, 0.0, 0.0)){push(g.vertices, v)} }; g.indices <- array(2u, 3u, 1u, 0u, 2u, 1u)
 var geo = upload_geometry(device, g) |> sdl_try; r.geometry = geo
 var image = load_texture_payload(device, "hextile.tex", SDL_GPUTextureFormat.TEXTUREFORMAT_BC7_RGBA_UNORM) |> sdl_try; r.image = image
 var si = gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR); si.address_mode_u = SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT; si.address_mode_v = si.address_mode_u; si.mipmap_mode = SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR; si.max_lod = 12.0
 r.sampler = SDL_CreateGPUSamplerRef(device, si); if (r.sampler == null){return err(sdl_error("sampler"), type<SdlUnit>)}
 let streams <- array(SDL_GPUVertexBufferDescription(pitch = 32u)); let attrs <- array(SDL_GPUVertexAttribute(format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3)); var p = pipeline(device, shaders::hextile_vertex, shaders::hextile_vertex_reflect, shaders::hextile_fragment, shaders::hextile_fragment_reflect, format, true, streams, attrs, false) |> sdl_try; r.pipeline = p
 return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; settings : Settings) : SdlStatus {
 replace_depth(device, r.depth, r.size, width, height) |> sdl_try
 let eye = float3(0.0, 2.0, -0.01 - fract(settings.time / 40.0) * 10.0)
 let vp = perspective(float(width) / float(height), 3.7320508, 0.1, 1000.0) * look_at_lh(eye, float3(0.0), float3(0.0, 1.0, 0.0))
 push_gpu_dsl_vertex_uniform(command, 0u, shaders::Camera(vp = vp)) |> sdl_try
 push_gpu_dsl_fragment_uniform(command, 0u, shaders::Config(values = float4(settings.weights ? 1.0 : 0.0, float(settings.rate), settings.rotation, settings.regular ? 1.0 : 0.0))) |> sdl_try
 let targets <- array(attachment(output, float4(0.188, 0.188, 0.188, 1.0)))
 return with_native_gpu_render_pass(command, targets, depth_attachment(r.depth)) $(var pass_ : SDL_GPURenderPass?&){SDL_BindGPUGraphicsPipeline(pass_, r.pipeline); var images <- array(r.image); bind_images(pass_, images, r.sampler) |> sdl_try; return draw_geometry(pass_, r.geometry)}
}
def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_imgui_gpu(window, device) {
        DisableIniPersistence(); StyleColorsDark()
        return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
            var settings = Settings(); var event = SDL_MakeEvent(); var running = true; var frames = 0; var last = SDL_GetTicks()
            while (running) {
                while (is_some(poll_event(event))) { ImGui_SDL3_ProcessEvent(event); let owned = decode_event(event); if (should_close(owned, window) && (!(owned is key_down) || !ImGui_SDL3_WantCaptureKeyboard())) { running = false } }
                if (!running) { break }
                begin_gui()
                SetNextWindowPos(ImVec2(650.0, 10.0), ImGuiCond.FirstUseEver)
                SetNextWindowSize(ImVec2(300.0, 230.0), ImGuiCond.FirstUseEver)
                if (Begin("Settings")) { Checkbox("Use Regular Tiling", unsafe(addr(settings.regular))); Checkbox("Show Weights", unsafe(addr(settings.weights))); Checkbox("Pause Animation", unsafe(addr(settings.paused))); SliderInt("Tile Rate", unsafe(addr(settings.rate)), 2, 25); SliderFloat("Tile Rotation", unsafe(addr(settings.rotation)), 0.0, 20.0) }
                End(); Render()
                if (!settings.paused) { settings.time += float(SDL_GetTicks() - last) * 0.001 }
                last = SDL_GetTicks()
                with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) {
                    draw(device, command, r, output, width, height, settings) |> sdl_try
                    return draw_gui(command, output)
                } |> sdl_try
                frames++; if (smoke && frames >= 3) { break }
            }
            return sdl_ok()
        }
    }
}
