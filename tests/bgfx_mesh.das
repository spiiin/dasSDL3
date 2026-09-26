options gen2
// GPU regression harness; rendering functions come from the interactive example.
require ../examples/gpu/mesh_app.das as demo
// Port of bgfx examples/04-mesh; BSD-2-Clause (LICENSE-bgfx.txt).
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_native_boost
require dassdl3/sdl3_gpu_pipeline_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_window_boost
require dassdl3/sdl3_iostream_boost
require dassdl3/sdl3_init_boost
require daslib/match
require daslib/defer
require math
require ../examples/gpu/mesh_data.das

let WIDTH = 640u
let HEIGHT = 360u

def check_image(device : SDL_GPUDevice?; var color : SDL_GPUTexture?) {
    return sdl_scope() {
        var download : SDL_GPUTransferBuffer? = device |> with_native_gpu_transfer_buffer(
            SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_DOWNLOAD, size = WIDTH * HEIGHT * 4u)) |> sdl_use
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        sdl_scope() {
            var copy_pass : SDL_GPUCopyPass?& = with_native_gpu_copy_pass(command) |> sdl_use
            let from = SDL_GPUTextureRegion(texture = color, w = WIDTH, h = HEIGHT, d = 1u)
            let to = SDL_GPUTextureTransferInfo(transfer_buffer = download, pixels_per_row = WIDTH, rows_per_layer = HEIGHT)
            SDL_DownloadFromGPUTextureRef(copy_pass, from, to)
            return sdl_ok()
        } |> sdl_try
        var fence = native_gpu_submit_fence(command) |> sdl_try
        {
            defer() { SDL_ReleaseGPUFence(device, fence) }
            let fences <- array(fence)
            sdl_status(SDL_WaitForGPUFencesArray(device, true, fences), "SDL_WaitForGPUFencesArray") |> sdl_try
        }
        var pixels : array<uint8>
        resize(pixels, int(WIDTH * HEIGHT * 4u))
        sdl_status(SDL_ReadGPUTransferBufferBytes(device, download, WIDTH * HEIGHT * 4u, 0u, pixels), "SDL_ReadGPUTransferBufferBytes") |> sdl_try
        var foreground = 0; var lit_pixels = 0
        var hash = 2166136261u
        for (i in 0 .. int(WIDTH * HEIGHT)) {
            let red = int(pixels[i * 4]); let green = int(pixels[i * 4 + 1]); let blue = int(pixels[i * 4 + 2])
            if (red != 48 || green != 48 || blue != 48) { foreground++ }
            if (max(red, max(green, blue)) > 160 && max(red, max(green, blue)) - min(red, min(green, blue)) > 30) { lit_pixels++ }
            hash = (hash ^ uint(pixels[i * 4])) * 16777619u
            hash = (hash ^ uint(pixels[i * 4 + 1])) * 16777619u
            hash = (hash ^ uint(pixels[i * 4 + 2])) * 16777619u
        }
        if (foreground < 2000 || foreground > int(WIDTH * HEIGHT) / 2 || lit_pixels < 2000) {
            return err(SdlError(operation = "mesh readback", message = "Unexpected coverage: {foreground} foreground, {lit_pixels} lit colored pixels"), type<uint>)
        }
        // The bunny is centered; clear pixels must survive in opposite corners.
        let last = int((WIDTH * HEIGHT - 1u) * 4u)
        if (int(pixels[0]) != 48 || int(pixels[1]) != 48 || int(pixels[last]) != 48 || int(pixels[last + 2]) != 48) {
            return err(SdlError(operation = "mesh readback", message = "Background corners differ"), type<uint>)
        }
        let capture_path = hint_string("DASSDL3_MESH_CAPTURE") |> unwrap_or("")
        if (capture_path != "") { save_file(capture_path, pixels) |> sdl_try }
        print("Mesh readback: {foreground} object pixels, hash={hash}.\n")
        return ok(hash, type<SdlError>)
    }
}

def animate(device : SDL_GPUDevice?; window : SDL_Window?; pipeline : SDL_GPUGraphicsPipeline?;
            var vb, ib : SDL_GPUBuffer?; count : uint; smoke : bool) {
    var running = true; var paused = false; var time = 0.0; var previous = SDL_GetTicks(); var frames = 0
    var depth : SDL_GPUTexture?
    var depth_width = 0u; var depth_height = 0u
    var resized = false; var resize_seen = false
    defer() { if (depth != null) { SDL_ReleaseGPUTexture(device, depth) } }
    while (running) {
        for (event in poll_events()) {
            if (should_close(event, window)) { running = false }
            match (event) {
                if (SdlEvent(key_down = $v(key))) {
                    if (key.window_id == SDL_GetWindowID(window) && !key.repeat) {
                        if (key.keycode == SDLK_SPACE) { paused = !paused }
                        elif (key.keycode == SDLK_R) { time = 0.0 }
                    }
                }
                if (_) { }
            }
        }
        if (!running) { break }
        let now = SDL_GetTicks()
        if (!paused) { time += min(0.1, float(now - previous) * 0.001) }
        previous = now
        with_native_gpu_swapchain(device, window) $(command; var swapchain; width, height) {
            if (width != depth_width || height != depth_height) {
                let settings = gpu_texture(width, height, SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)
                var replacement = SDL_CreateGPUTextureRef(device, settings)
                if (replacement == null) { return err(sdl_error("SDL_CreateGPUTexture"), type<SdlUnit>) }
                if (depth != null) { SDL_ReleaseGPUTexture(device, depth) }
                depth = replacement; depth_width = width; depth_height = height
                if (resized) { resize_seen = true }
                print("Mesh target: {int(width)}x{int(height)}.\n")
            }
            return demo::draw(command, pipeline, vb, ib, count, swapchain, depth, width, height, time)
        } |> sdl_try
        frames++
        if (smoke && !resized && depth != null) {
            sdl_status(SDL_SetWindowSize(window, 800, 600), "SDL_SetWindowSize") |> sdl_try
            resized = true
        }
        if (smoke && resize_seen && frames >= 3) { break }
        if (smoke && frames >= 100) { return err(SdlError(operation = "mesh resize", message = "Swapchain resize not observed"), type<SdlUnit>) }
        SDL_Delay(16u)
    }
    sdl_status(SDL_WaitForGPUIdle(device), "SDL_WaitForGPUIdle") |> sdl_try
    print("Mesh: {frames} frames, {SDL_GetGPUDeviceDriver(device)}.\n")
    return sdl_ok()
}

def smoke_frames(device : SDL_GPUDevice?; pipeline : SDL_GPUGraphicsPipeline?;
                 var vb, ib : SDL_GPUBuffer?; count : uint) {
    return sdl_scope() {
        var color : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT,
            SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_COLOR_TARGET)) |> sdl_use
        var depth : SDL_GPUTexture? = device |> with_native_gpu_texture(gpu_texture(WIDTH, HEIGHT,
            SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT, SDL_GPU_TEXTUREUSAGE_DEPTH_STENCIL_TARGET)) |> sdl_use
        var first_hash = 0u
        for (i in 1 .. 3) {
            sdl_scope() {
                var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
                demo::draw(command, pipeline, vb, ib, count, color, depth, WIDTH, HEIGHT, float(i) * 0.6) |> sdl_try
                return native_gpu_submit(command)
            } |> sdl_try
            let hash = check_image(device, color) |> sdl_try
            if (i == 1) { first_hash = hash }
            elif (hash == first_hash) { return err(SdlError(operation = "mesh animation", message = "Uniform update did not change pixels"), type<SdlUnit>) }
        }
        return sdl_ok()
    }
}

def resources(device : SDL_GPUDevice?; window : SDL_Window?; var vertex, fragment : SDL_GPUShader?; smoke : bool) {
    let mesh <- load_mesh("{SDL_GetBasePath()}assets/meshes/bunny.msh") |> sdl_try
    print("Bunny: {int(mesh.vertex_count)} vertices, {int(mesh.index_count/3u)} triangles.\n")
    var info = SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vertex, fragment_shader = fragment)
    info |> topology(SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
    info |> rasterizer(SDL_GPURasterizerState(enable_depth_clip = true, cull_mode = SDL_GPUCullMode.CULLMODE_BACK,
        front_face = SDL_GPUFrontFace.FRONTFACE_CLOCKWISE))
    info |> depth_target(SDL_GPUTextureFormat.TEXTUREFORMAT_D32_FLOAT)
    info |> depth_test(SDL_GPUCompareOp.COMPAREOP_LESS)
    info |> depth_write(true)
    let format = smoke ? SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM : SDL_GetGPUSwapchainTextureFormat(device, window)
    let colors <- array(gpu_color_target(format))
    let buffers <- array(SDL_GPUVertexBufferDescription(pitch = 24u))
    let attributes <- array(SDL_GPUVertexAttribute(location = 0u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3),
        SDL_GPUVertexAttribute(location = 1u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3, offset = 12u))
    return sdl_scope() {
        var vb : SDL_GPUBuffer? = device |> with_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_VERTEX, size = uint(length(mesh.vertices)))) |> sdl_use
        var ib : SDL_GPUBuffer? = device |> with_native_gpu_buffer(SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_INDEX, size = uint(length(mesh.indices)))) |> sdl_use
        demo::upload_buffer(device, vb, mesh.vertices) |> sdl_try
        demo::upload_buffer(device, ib, mesh.indices) |> sdl_try
        if (smoke) {
            sdl_scope() {
                let pipeline : SDL_GPUGraphicsPipeline? = device |> with_native_gpu_graphics_pipeline(info, buffers, attributes, colors) |> sdl_use
                return smoke_frames(device, pipeline, vb, ib, mesh.index_count)
            } |> sdl_try
        }
        let swapchain_colors <- array(gpu_color_target(SDL_GetGPUSwapchainTextureFormat(device, window)))
        let pipeline : SDL_GPUGraphicsPipeline? = device |> with_native_gpu_graphics_pipeline(info, buffers, attributes, swapchain_colors) |> sdl_use
        return animate(device, window, pipeline, vb, ib, mesh.index_count, smoke)
    }
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) {
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let ext = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/shaders/mesh"
    var vs = gpu_shader("{base}.vert.{ext}", format, SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    vs |> uniform_buffers(1u)
    let fs = gpu_shader("{base}.frag.{ext}", format, SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    return sdl_scope() {
        var vertex : SDL_GPUShader? = device |> with_native_gpu_shader_file(vs) |> sdl_use
        var fragment : SDL_GPUShader? = device |> with_native_gpu_shader_file(fs) |> sdl_use
        return resources(device, window, vertex, fragment, smoke)
    }
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let settings = window_options("bgfx mesh | Space: pause | R: reset | Esc: exit", int2(960, 540))
        let window : SDL_Window? = with_window(settings) |> sdl_use
        let device : SDL_GPUDevice? = with_native_gpu_device(GPU_SHADER_FORMATS, true, "") |> sdl_use
        sdl_status(SDL_ClaimWindowForGPUDevice(device, window), "SDL_ClaimWindowForGPUDevice") |> sdl_try
        {
            defer() { SDL_ReleaseWindowFromGPUDevice(device, window) }
            return run(device, window, smoke)
        }
    }
    if (is_err(result)) { let error = unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1 }
    return 0
}
