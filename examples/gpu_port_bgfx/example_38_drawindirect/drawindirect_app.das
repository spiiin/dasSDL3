options gen2
module drawindirect_app shared public
require ../common/imgui_gpu.das public
require ../common/compute_support.das
require ./shaders/drawindirect_shaders.das as shaders
require daslib/defer
struct Settings { side : int = 11; vertex_mode, index_mode : int; paused : bool; time : float }
struct Resources { geometry : GeometryBuffers; pipeline : SDL_GPUGraphicsPipeline ?; compute : SDL_GPUComputePipeline ?; commands, instances : SDL_GPUBuffer ?; depth : SDL_GPUTexture ?; size : uint2; vertex_bytes, index_bytes : array<uint8>; vb_mode, ib_mode : int = -1; vb_offset, ib_offset : uint }
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
 var r = Resources(); defer(){release(device, r.geometry); if (r.pipeline != null){SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline)}; if (r.compute != null){SDL_ReleaseGPUComputePipeline(device, r.compute)}; if (r.depth != null){SDL_ReleaseGPUTexture(device, r.depth)}; for (resource in fixed_array(r.commands, r.instances)){if (resource != null){SDL_ReleaseGPUBuffer(device, resource)}}}
 var g = Geometry()
 let xyz <- array<float>(-1.0, 1.0, 1.0, 1.0, 1.0, 1.0, -1.0, -1.0, 1.0, 1.0, -1.0, 1.0, -1.0, 1.0, -1.0, 1.0, 1.0, -1.0, -1.0, -1.0, -1.0, 1.0, -1.0, -1.0, 1.0, 1.0, 1.0, 1.0, -1.0, -1.0, -1.0, 1.0, -1.0, -1.0, -1.0, 1.0)
 let colors <- array<uint>(0u, 1u, 2u, 3u, 4u, 5u, 6u, 7u, 1u, 0u, 2u, 3u)
 for (i in 0..12){for (v in fixed_array(xyz[i * 3], xyz[i * 3 + 1], xyz[i * 3 + 2], float(colors[i] & 1u), float((colors[i] >> 1u) & 1u), float((colors[i] >> 2u) & 1u), 0.0, 0.0)){push(g.vertices, v)}}
 g.indices <- array<uint>(0u, 1u, 2u, 1u, 3u, 2u, 4u, 6u, 5u, 5u, 6u, 7u, 0u, 2u, 4u, 4u, 2u, 6u, 1u, 5u, 3u, 5u, 7u, 3u, 0u, 4u, 1u, 4u, 5u, 1u, 2u, 3u, 6u, 6u, 3u, 7u, 0u, 2u, 1u, 1u, 2u, 3u, 0u, 3u, 2u, 1u, 3u, 0u)
 for (v in g.vertices){let bits = unsafe(reinterpret<uint>(v)); for (s in fixed_array(0u, 8u, 16u, 24u)){push(r.vertex_bytes, uint8((bits >> s) & 255u))}}
 for (v in g.indices){for (s in fixed_array(0u, 8u, 16u, 24u)){push(r.index_bytes, uint8((v >> s) & 255u))}}
 var buf = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(size = 2048u, usage = SDL_GPU_BUFFERUSAGE_VERTEX)) |> sdl_try; r.geometry.vb = buf
 buf = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(size = 1024u, usage = SDL_GPU_BUFFERUSAGE_INDEX)) |> sdl_try; r.geometry.ib = buf
 buf = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(size = 6561u * 20u, usage = SDL_GPU_BUFFERUSAGE_INDIRECT | SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE)) |> sdl_try; r.commands = buf
 buf = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(size = 6561u * 80u, usage = SDL_GPU_BUFFERUSAGE_VERTEX | SDL_GPU_BUFFERUSAGE_COMPUTE_STORAGE_WRITE)) |> sdl_try; r.instances = buf
 var cp = compute_pipeline(device, shaders::drawindirect_build, shaders::drawindirect_build_reflect, shaders::drawindirect_build_access) |> sdl_try; r.compute = cp
 let streams <- array(SDL_GPUVertexBufferDescription(pitch = 32u), SDL_GPUVertexBufferDescription(slot = 1u, pitch = 80u, input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE))
 var attrs <- array(SDL_GPUVertexAttribute(format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3), SDL_GPUVertexAttribute(location = 1u, offset = 12u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3))
 for (i in 0u..5u){push(attrs, SDL_GPUVertexAttribute(location = 3u + i, buffer_slot = 1u, offset = i * 16u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4))}
 var pp = pipeline(device, shaders::drawindirect_vertex, shaders::drawindirect_vertex_reflect, shaders::drawindirect_fragment, shaders::drawindirect_fragment_reflect, format, true, streams, attrs, true) |> sdl_try; r.pipeline = pp
 return body(r)
}
def upload_mode(device : SDL_GPUDevice?; var buffer : SDL_GPUBuffer?; bytes : array<uint8>; offset : uint) : SdlStatus {
 var data : array<uint8>; resize(data, int(offset)); for (b in bytes){push(data, b)}
 return sdl_scope(){var transfer : SDL_GPUTransferBuffer ? = with_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(size = uint(length(data)))) |> sdl_use
 sdl_status(SDL_WriteGPUTransferBufferBytes(device, transfer, uint(length(data)), 0u, data, false), "buffer upload") |> sdl_try
 var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
 with_native_gpu_copy_pass(command) $(var pass_){SDL_UploadToGPUBufferRef(pass_, SDL_GPUTransferBufferLocation(transfer_buffer = transfer), SDL_GPUBufferRegion(buffer = buffer, size = uint(length(data))), true); return sdl_ok()} |> sdl_try; return native_gpu_submit(command)}
}
def prepare(device : SDL_GPUDevice?; var r : Resources; settings : Settings) : SdlStatus {
 if (r.vb_mode != settings.vertex_mode || settings.vertex_mode == 2){r.vb_offset = settings.vertex_mode == 0 ? 0u : 1024u; upload_mode(device, r.geometry.vb, r.vertex_bytes, r.vb_offset) |> sdl_try; r.vb_mode = settings.vertex_mode}
 if (r.ib_mode != settings.index_mode || settings.index_mode == 2){r.ib_offset = settings.index_mode == 0 ? 0u : 256u; upload_mode(device, r.geometry.ib, r.index_bytes, r.ib_offset) |> sdl_try; r.ib_mode = settings.index_mode}
 return sdl_ok()
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; settings : Settings) : SdlStatus {
 replace_depth(device, r.depth, r.size, width, height) |> sdl_try
 push_gpu_dsl_compute_uniform(command, 0u, shaders::Params(values = float4(float(settings.side), settings.time, 0.0, 0.0))) |> sdl_try
 var textures : array<SDL_GPUStorageTextureReadWriteBinding>; let buffers <- array(SDL_GPUStorageBufferReadWriteBinding(buffer = r.commands), SDL_GPUStorageBufferReadWriteBinding(buffer = r.instances))
 with_native_gpu_compute_pass(command, textures, buffers) $(var pass_ : SDL_GPUComputePass?&){SDL_BindGPUComputePipeline(pass_, r.compute); SDL_DispatchGPUCompute(pass_, uint((settings.side * settings.side + 63) / 64), 1u, 1u); return sdl_ok()} |> sdl_try
 let vp = perspective(float(width) / float(height), 1.7320508, 0.1, 500.0) * look_at_lh(float3(0.0, 0.0, -35.0), float3(0.0), float3(0.0, 1.0, 0.0))
 push_gpu_dsl_vertex_uniform(command, 0u, shaders::Camera(vp = vp)) |> sdl_try
 let targets <- array(attachment(output, float4(48.0 / 255.0, 48.0 / 255.0, 48.0 / 255.0, 1.0)))
 return with_native_gpu_render_pass(command, targets, depth_attachment(r.depth)) $(var pass_ : SDL_GPURenderPass?&){SDL_BindGPUGraphicsPipeline(pass_, r.pipeline); let vbs <- array(SDL_GPUBufferBinding(buffer = r.geometry.vb, offset = r.vb_offset), SDL_GPUBufferBinding(buffer = r.instances)); sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, vbs), "instances") |> sdl_try; SDL_BindGPUIndexBufferRef(pass_, SDL_GPUBufferBinding(buffer = r.geometry.ib, offset = r.ib_offset), SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT); SDL_DrawGPUIndexedPrimitivesIndirect(pass_, r.commands, 0u, uint(settings.side * settings.side)); return sdl_ok()}
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
                if (Begin("Settings")) { Text("{settings.side*settings.side} objects, one multi-draw API call"); SliderInt("Grid Side Size", unsafe(addr(settings.side)), 1, 81); SliderInt("Vertex buffer: static/padded/cycled", unsafe(addr(settings.vertex_mode)), 0, 2); SliderInt("Index buffer: static/padded/cycled", unsafe(addr(settings.index_mode)), 0, 2); Text("GPU indirect count is not exposed by SDL"); Checkbox("Pause", unsafe(addr(settings.paused))) }
                End(); Render()
                if (!settings.paused) { settings.time += float(SDL_GetTicks() - last) * 0.001 }
                last = SDL_GetTicks()
                prepare(device, r, settings) |> sdl_try
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
