options gen2
module svt_app shared public
require ../common/imgui_gpu.das public
require ../common/mesh_data.das
require ../common/post_scene/scene.das as scene
require ./shaders/svt_shaders.das as shaders
require dassdl3/sdl3_image_boost
require dassdl3/sdl3_surface_pixels_boost
require dassdl3/sdl3_record_access
require dassdl3/sdl3_iostream_boost
require daslib/defer
struct Settings { borders : bool; colors : bool; updates : int = 1 }
struct Page { x, y, mip : int; slot : int = -1; last : uint; requests : uint; part, offset, bytes : uint }
struct Resources { plane : GeometryBuffers; pipeline, feedback_pipeline : SDL_GPUGraphicsPipeline ?; atlas, page_table, feedback : SDL_GPUTexture ?; linear, nearest : SDL_GPUSampler ?; download : SDL_GPUTransferBuffer ?; fence : SDL_GPUFence ?; pages : array<Page>; slots : array<int>; stamp : uint; bias : int = 4; uploads : uint }
def index(x, y, mip : int) : int { var offset = 0; for (i in range(mip)) { let n = 64 >> i; offset += n * n }; return offset + y * (64 >> mip) + x }
def upload_region(device : SDL_GPUDevice?; var target : SDL_GPUTexture?; bytes : array<uint8>; x, y, w, h, pitch : uint) : SdlStatus {
    return sdl_scope() {
        var transfer : SDL_GPUTransferBuffer? = with_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = uint(length(bytes)))) |> sdl_use
        sdl_status(SDL_WriteGPUTransferBufferBytes(device, transfer, uint(length(bytes)), 0u, bytes, false), "SVT upload") |> sdl_try
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        with_native_gpu_copy_pass(command) $(var pass_ : SDL_GPUCopyPass?&) { SDL_UploadToGPUTextureRef(pass_, SDL_GPUTextureTransferInfo(transfer_buffer = transfer, pixels_per_row = pitch / 4u, rows_per_layer = h), SDL_GPUTextureRegion(texture = target, x = x, y = y, w = w, h = h, d = 1u), false); return sdl_ok() } |> sdl_try
        return native_gpu_submit(command)
    }
}
def load_page(device : SDL_GPUDevice?; var r : Resources; id, slot : int) : SdlStatus {
    let page = r.pages[id]
    return with_io_file("{SDL_GetBasePath()}assets/bgfx/svt-pages-{int(page.part)}.bin", "rb") $(io : SDL_IOStream?) {
        seek_io(io, int64(page.offset)) |> sdl_try
        return with_image(io) $(image : SDL_Surface?) {
            return with_converted_surface(image, SDL_PixelFormat.PIXELFORMAT_RGBA32) $(surface : SDL_Surface?) {
                return with_surface_bytes(surface, 0) $(var data : array<uint8>#; layout : int4) {
                    var bytes : array<uint8>; resize(bytes, 768 * 130)
                    for (y in range(130)) { for (x in range(520)) { bytes[y * 768 + x] = data[y * layout.z + x] } }
                    upload_region(device, r.atlas, bytes, uint(slot % 15) * 130u, uint(slot / 15) * 130u, 130u, 130u, 768u) |> sdl_try
                    if (r.slots[slot] >= 0) { r.pages[r.slots[slot]].slot = -1 }; r.slots[slot] = id; r.pages[id].slot = slot; r.pages[id].last = r.stamp; r.uploads++
                    return sdl_ok()
                }
            }
        }
    }
}
def update_table(device : SDL_GPUDevice?; var r : Resources) : SdlStatus {
    var data : array<uint8>; resize(data, 64 * 127 * 4)
    for (p in r.pages) { var ancestor = index(p.x, p.y, p.mip); var x = p.x; var y = p.y; var level = p.mip
        while (r.pages[ancestor].slot < 0 && level < 6) { x /= 2; y /= 2; level++; ancestor = index(x, y, level) }
        let slot = r.pages[ancestor].slot; let row = 128 - (128 >> p.mip) + p.y; let at = (row * 64 + p.x) * 4
        data[at] = uint8(slot % 15); data[at + 1] = uint8(slot / 15); data[at + 2] = uint8(level); data[at + 3] = 255u8
    }; return upload_region(device, r.page_table, data, 0u, 0u, 64u, 127u, 256u)
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r = Resources()
    defer() { if (r.fence != null) { SDL_ReleaseGPUFence(device, r.fence) }; if (r.download != null) { SDL_ReleaseGPUTransferBuffer(device, r.download) }; release(device, r.plane); for (resource in fixed_array(r.pipeline, r.feedback_pipeline)) { if (resource != null) { SDL_ReleaseGPUGraphicsPipeline(device, resource) } }; for (resource in fixed_array(r.atlas, r.page_table, r.feedback)) { if (resource != null) { SDL_ReleaseGPUTexture(device, resource) } }; for (resource in fixed_array(r.linear, r.nearest)) { if (resource != null) { SDL_ReleaseGPUSampler(device, resource) } } }
    let idx <- load_file("{SDL_GetBasePath()}assets/bgfx/svt-pages.idx") |> sdl_try
    if (length(idx) != 65536 || mesh_u32(idx, 0) != 5461u) { return err(SdlError(operation = "SVT index", message = "Unexpected tile directory"), type<SdlUnit>) }
    for (mip in range(7)) { let n = 64 >> mip; for (y in range(n)) { for (x in range(n)) { let at = 4 + 12 * length(r.pages); push(r.pages, Page(x = x, y = y, mip = mip, part = mesh_u32(idx, at), offset = mesh_u32(idx, at + 4), bytes = mesh_u32(idx, at + 8))) } } }
    resize(r.slots, 225); for (i in range(length(r.slots))) { r.slots[i] = -1 }
    var t = texture(device, 1950u, 1950u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER | SDL_GPU_TEXTUREUSAGE_COLOR_TARGET) |> sdl_try; r.atlas = t
    t = texture(device, 64u, 127u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.page_table = t
    t = texture(device, 64u, 64u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET | SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try; r.feedback = t
    var transfer = create_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD, size = 16384u)) |> sdl_try; r.download = transfer
    r.linear = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR)); r.nearest = SDL_CreateGPUSamplerRef(device, gpu_sampler_info())
    if (r.linear == null || r.nearest == null) { return err(sdl_error("SVT samplers"), type<SdlUnit>) }
    var mesh : Geometry; let n = float3(0.0, 1.0, 0.0)
    vertex(mesh, float3(-50.0, 0.0, 50.0), n, float2(1.0, 1.0)); vertex(mesh, float3(50.0, 0.0, 50.0), n, float2(1.0, 0.0)); vertex(mesh, float3(-50.0, 0.0, -50.0), n, float2(0.0, 1.0)); vertex(mesh, float3(50.0, 0.0, -50.0), n, float2(0.0, 0.0)); mesh.indices <- array<uint>(0u, 1u, 2u, 1u, 3u, 2u)
    var plane = upload_geometry(device, mesh) |> sdl_try; r.plane = plane
    let colors <- array(gpu_color_target(format)); var p = pass_pipeline(device, shaders::svt_vertex, shaders::svt_vertex_reflect, shaders::svt_fragment, shaders::svt_fragment_reflect, colors, true, false) |> sdl_try; r.pipeline = p
    let feedback <- array(gpu_color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM)); p = pass_pipeline(device, shaders::svt_vertex, shaders::svt_vertex_reflect, shaders::svt_feedback, shaders::svt_feedback_reflect, feedback, true, false) |> sdl_try; r.feedback_pipeline = p
    sdl_scope() { var command : SDL_GPUCommandBuffer ? & = with_native_gpu_commands(device) |> sdl_use; let targets <- array(attachment(r.atlas)); with_native_gpu_render_pass(command, targets) $(var pass_ : SDL_GPURenderPass?&) { return sdl_ok() } |> sdl_try; return native_gpu_submit(command) } |> sdl_try
    load_page(device, r, 5460, 0) |> sdl_try; update_table(device, r) |> sdl_try
    return body(r)
}
def process_feedback(device : SDL_GPUDevice?; var r : Resources; s : Settings) : SdlStatus {
    if (r.fence == null || !SDL_QueryGPUFence(device, r.fence)) { return sdl_ok() }
    var data : array<uint8>; resize(data, 16384)
    sdl_status(SDL_ReadGPUTransferBufferBytes(device, r.download, 16384u, 0u, data), "SVT feedback") |> sdl_try; SDL_ReleaseGPUFence(device, r.fence); r.fence = null; r.stamp++
    for (i in range(length(r.pages))) { r.pages[i].requests = 0u }
    for (i in range(4096)) { let at = i * 4; if (data[at + 3] == 0u8) { continue }; var mip = int(data[at + 2]); var x = int(data[at]); var y = int(data[at + 1]); if (mip > 6 || x >= (64 >> mip) || y >= (64 >> mip)) { continue }
        while (mip <= 6) { let id = index(x, y, mip); r.pages[id].requests++; if (r.pages[id].slot >= 0) { r.pages[id].last = r.stamp }; x /= 2; y /= 2; mip++ }
    }
    var touched = 0; for (p in r.pages) { if (p.slot >= 0 && p.requests > 0u) { touched++ } }
    if (touched >= 225) { r.bias = max(-6, r.bias - 1); return sdl_ok() }
    var changed = false
    for (upload in range(s.updates)) {
        var best = -1
        for (i in range(length(r.pages))) { let p = r.pages[i]; if (p.slot < 0 && p.requests > 0u && (best < 0 || p.mip > r.pages[best].mip || (p.mip == r.pages[best].mip && p.requests > r.pages[best].requests))) { best = i } }
        if (best < 0) { break }; var slot = 1; var oldest = 0xffffffffu
        for (i in range(1, 225)) { if (r.slots[i] < 0) { slot = i; break }; if (r.pages[r.slots[i]].last < oldest) { oldest = r.pages[r.slots[i]].last; slot = i } }
        load_page(device, r, best, slot) |> sdl_try; changed = true
    }
    if (changed) { update_table(device, r) |> sdl_try }; return sdl_ok()
}
def request_feedback(device : SDL_GPUDevice?; var r : Resources) : SdlStatus {
    if (r.fence != null) { return sdl_ok() }
    return sdl_scope() { var command : SDL_GPUCommandBuffer ? & = with_native_gpu_commands(device) |> sdl_use
        with_native_gpu_copy_pass(command) $(var pass_ : SDL_GPUCopyPass?&) { SDL_DownloadFromGPUTextureRef(pass_, SDL_GPUTextureRegion(texture = r.feedback, w = 64u, h = 64u, d = 1u), SDL_GPUTextureTransferInfo(transfer_buffer = r.download, pixels_per_row = 64u, rows_per_layer = 64u)); return sdl_ok() } |> sdl_try
        var f = native_gpu_submit_fence(command) |> sdl_try; r.fence = f; return sdl_ok()
    }
}
def draw(command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; s : Settings; camera : scene::Camera) : SdlStatus {
    let direction = float3(cos(camera.pitch) * sin(camera.yaw), sin(camera.pitch), cos(camera.pitch) * cos(camera.yaw))
    let vp = perspective(float(width) / float(height), 1.7320508, 0.1, 1000.0) * look_at_lh(camera.eye, camera.eye + direction, float3(0.0, 1.0, 0.0))
    let config = shaders::Config(vp = vp, settings = float4(float(r.bias), s.borders ? 1.0 : 0.0, s.colors ? 1.0 : 0.0, 0.0)); push_gpu_dsl_vertex_uniform(command, 0u, config) |> sdl_try; push_gpu_dsl_fragment_uniform(command, 0u, config) |> sdl_try
    let feedback <- array(attachment(r.feedback)); with_native_gpu_render_pass(command, feedback) $(var pass_ : SDL_GPURenderPass?&) { SDL_BindGPUGraphicsPipeline(pass_, r.feedback_pipeline); return draw_geometry(pass_, r.plane) } |> sdl_try
    let colors <- array(attachment(output, float4(0.188, 0.188, 0.188, 1.0)))
    return with_native_gpu_render_pass(command, colors) $(var pass_ : SDL_GPURenderPass?&) { SDL_BindGPUGraphicsPipeline(pass_, r.pipeline); let samplers <- array(SDL_GPUTextureSamplerBinding(texture = r.page_table, sampler = r.nearest), SDL_GPUTextureSamplerBinding(texture = r.atlas, sampler = r.linear)); sdl_status(SDL_BindGPUFragmentSamplersArray(pass_, 0u, samplers), "SVT page page_table and atlas") |> sdl_try; return draw_geometry(pass_, r.plane) }
}
def panel(var s : Settings; var r : Resources) { SetNextWindowPos(ImVec2(700.0, 10.0), ImGuiCond.FirstUseEver); SetNextWindowSize(ImVec2(250.0, 650.0), ImGuiCond.FirstUseEver)
    if (Begin("Settings")) { Checkbox("Show borders", unsafe(addr(s.borders))); Checkbox("Color mip levels", unsafe(addr(s.colors))); SliderInt("Updates per frame", unsafe(addr(s.updates)), 1, 100); Text("Uploads: {int(r.uploads)} | Bias: {r.bias}");
        Image(ImTextureRef(unsafe(reinterpret<uint64>(r.atlas))), ImVec2(220.0, 220.0), ImVec2(0.0), ImVec2(1.0)); Image(ImTextureRef(unsafe(reinterpret<uint64>(r.feedback))), ImVec2(220.0, 220.0), ImVec2(0.0), ImVec2(1.0)); Text("WASD: move | Arrows: look")
    }; End()
}
def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_imgui_gpu(window, device) { DisableIniPersistence(); StyleColorsDark()
        return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
            var settings = Settings(); var camera = scene::Camera(eye = float3(0.0, 5.0, 0.0), pitch = 0.0); var raw = SDL_MakeEvent(); var running = true; var frames = 0u
            while (running) {
                while (is_some(poll_event(raw))) { ImGui_SDL3_ProcessEvent(raw); let e = decode_event(raw); if (should_close(e, window) && (!(e is key_down) || !ImGui_SDL3_WantCaptureKeyboard())) { running = false }; if (!ImGui_SDL3_WantCaptureKeyboard()) { scene::camera_event(e, camera) } }
                if (!running) { break }; process_feedback(device, r, settings) |> sdl_try; begin_gui(); panel(settings, r); Render()
                with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { draw(command, r, output, width, height, settings, camera) |> sdl_try; return draw_gui(command, output) } |> sdl_try
                request_feedback(device, r) |> sdl_try; frames++; if (smoke && frames >= 20u) { break }
            }; return sdl_ok()
        }
    }
}
