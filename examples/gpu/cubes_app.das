options gen2
module cubes_app shared public
// bgfx 05-instancing / 06-bump; BSD-2-Clause (LICENSE-bgfx.txt).
require bgfx_support public
require cube_data
require dassdl3/sdl3_gpu_sampler_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_window_boost
require daslib/match
require daslib/defer
require math

let INSTANCE_CAPACITY = 32u * 32u * 80u

// Borrowed only inside with_resources; the module owns all destruction.
struct CubeResources {
    vb, ib, instances : SDL_GPUBuffer?
    transfer : SDL_GPUTransferBuffer?
    graphics : SDL_GPUGraphicsPipeline?
    albedo, normal : SDL_GPUTexture?
    sampler : SDL_GPUSampler?
}

def release(device : SDL_GPUDevice?; var r : CubeResources) {
    if (r.graphics != null) { SDL_ReleaseGPUGraphicsPipeline(device, r.graphics) }
    if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
    if (r.albedo != null) { SDL_ReleaseGPUTexture(device, r.albedo) }
    if (r.normal != null) { SDL_ReleaseGPUTexture(device, r.normal) }
    if (r.vb != null) { SDL_ReleaseGPUBuffer(device, r.vb) }
    if (r.ib != null) { SDL_ReleaseGPUBuffer(device, r.ib) }
    if (r.instances != null) { SDL_ReleaseGPUBuffer(device, r.instances) }
    if (r.transfer != null) { SDL_ReleaseGPUTransferBuffer(device, r.transfer) }
}

def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; bump : bool;
                   body : block<(var resources : CubeResources) : SdlStatus>) : SdlStatus {
    var r : CubeResources
    defer() { release(device, r) }
    let vertices <- cube_vertices(); let indices <- cube_indices()
    var handle = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_VERTEX, size = uint(length(vertices)) * 4u)) |> sdl_try
    r.vb = handle
    handle = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_INDEX, size = uint(length(indices)))) |> sdl_try
    r.ib = handle
    handle = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_VERTEX, size = INSTANCE_CAPACITY)) |> sdl_try
    r.instances = handle
    var transfer = create_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = INSTANCE_CAPACITY)) |> sdl_try
    r.transfer = transfer
    sdl_scope() {
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        upload_floats(device, command, r.vb, r.transfer, INSTANCE_CAPACITY, vertices) |> sdl_try
        return native_gpu_submit(command)
    } |> sdl_try
    upload_bytes(device, r.ib, indices) |> sdl_try
    let layouts <- array(SDL_GPUVertexBufferDescription(slot = 0u, pitch = 64u),
        SDL_GPUVertexBufferDescription(slot = 1u, pitch = 80u, input_rate = SDL_GPUVertexInputRate.VERTEXINPUTRATE_INSTANCE))
    var attributes <- array(SDL_GPUVertexAttribute(location = 0u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3))
    if (bump) {
        push(attributes, SDL_GPUVertexAttribute(location = 1u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT3, offset = 12u))
        push(attributes, SDL_GPUVertexAttribute(location = 2u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4, offset = 24u))
        push(attributes, SDL_GPUVertexAttribute(location = 3u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2, offset = 40u))
    } else {
        push(attributes, SDL_GPUVertexAttribute(location = 1u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4, offset = 48u))
    }
    let first = bump ? 4u : 2u
    for (i in 0u .. (bump ? 4u : 5u)) {
        push(attributes, SDL_GPUVertexAttribute(location = first + i, buffer_slot = 1u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4, offset = i * 16u))
    }
    let name = bump ? "bgfx_bump" : "bgfx_instancing"
    var graphics = pipeline(device, name, name, format, true, bump ? 2u : 0u, layouts, attributes) |> sdl_try
    r.graphics = graphics
    if (bump) {
        var tex = texture(device, 512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try
        r.albedo = tex
        tex = texture(device, 512u, 512u, SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> sdl_try
        r.normal = tex
        r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR, SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_REPEAT))
        if (r.sampler == null) { return err(sdl_error("SDL_CreateGPUSampler"), type<SdlUnit>) }
        upload_texture(device, r.albedo, "fieldstone-rgba.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
        upload_texture(device, r.normal, "fieldstone-n.rgba8", 512u, 512u, 4u, 1u) |> sdl_try
    }
    return body(r)
}

def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : CubeResources;
         var color, depth : SDL_GPUTexture?; width, height : uint; time : float; bump : bool;
         side : int = 11; instanced : bool = true; normal_mapping : bool = true) : SdlStatus {
    var values : array<float>
    update_instances(values, side, time, bump)
    upload_floats(device, command, r.instances, r.transfer, INSTANCE_CAPACITY, values) |> sdl_try
    let uniforms <- array<float>(time, float(width) / float(height), bump ? 7.0 : 35.0, normal_mapping ? 1.0 : 0.0)
    command |> push_native_gpu_vertex_uniforms(0u, uniforms) |> sdl_try
    let targets <- array(SDL_GPUColorTargetInfo(
        texture = color,
        load_op = SDL_GPULoadOp.LOADOP_CLEAR,
        store_op = SDL_GPUStoreOp.STOREOP_STORE,
        clear_color = SDL_FColor(r = 48.0 / 255.0, g = 48.0 / 255.0, b = 48.0 / 255.0, a = 1.0)))
    let depth_info = depth_attachment(depth)
    return with_native_gpu_render_pass(command, targets, depth_info) $(var render_pass) {
        SDL_BindGPUGraphicsPipeline(render_pass, r.graphics)
        let bindings <- array(SDL_GPUBufferBinding(buffer = r.vb), SDL_GPUBufferBinding(buffer = r.instances))
        sdl_status(SDL_BindGPUVertexBuffersArray(render_pass, 0u, bindings), "SDL_BindGPUVertexBuffersArray") |> sdl_try
        let index = SDL_GPUBufferBinding(buffer = r.ib)
        SDL_BindGPUIndexBufferRef(render_pass, index, SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
        if (bump) {
            let textures <- array(SDL_GPUTextureSamplerBinding(texture = r.albedo, sampler = r.sampler), SDL_GPUTextureSamplerBinding(texture = r.normal, sampler = r.sampler))
            sdl_status(SDL_BindGPUFragmentSamplersArray(render_pass, 0u, textures), "SDL_BindGPUFragmentSamplersArray") |> sdl_try
        }
        if (instanced) { SDL_DrawGPUIndexedPrimitives(render_pass, 36u, uint(side * side), 0u, 0, 0u) }
        else { for (i in 0u .. uint(side * side)) { SDL_DrawGPUIndexedPrimitives(render_pass, 36u, 1u, 0u, 0, i) } }
        return sdl_ok()
    }
}

def animate(device : SDL_GPUDevice?; window : SDL_Window?; var resources : CubeResources; bump : bool) : SdlStatus {
    var depth : SDL_GPUTexture?; var size = uint2(0u)
    defer() { if (depth != null) { SDL_ReleaseGPUTexture(device, depth) } }
    var running = true; var paused = false; var instanced = true; var normal_mapping = true
    var side = bump ? 3 : 11; var time = 0.0; var previous = SDL_GetTicks()
    while (running) {
        for (event in poll_events()) {
            if (should_close(event, window)) { running = false }
            match (event) {
                if (SdlEvent(key_down = $v(key))) {
                    if (key.window_id == SDL_GetWindowID(window) && !key.repeat) {
                        if (key.keycode == SDLK_SPACE) { paused = !paused }
                        elif (key.keycode == SDLK_R) { time = 0.0 }
                        elif (key.keycode == SDLK_I) { instanced = !instanced }
                        elif (key.keycode == SDLK_N) { normal_mapping = !normal_mapping }
                        elif (!bump && key.keycode == SDLK_UP) { side = min(32, side + 1) }
                        elif (!bump && key.keycode == SDLK_DOWN) { side = max(1, side - 1) }
                    }
                }
                if (_) { }
            }
        }
        if (!running) { break }
        let now = SDL_GetTicks(); if (!paused) { time += min(0.1, float(now - previous) * 0.001) }; previous = now
        with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var swapchain : SDL_GPUTexture?; width, height : uint) {
            replace_depth(device, depth, size, width, height) |> sdl_try
            return draw(device, command, resources, swapchain, depth, width, height, time, bump, side, instanced, normal_mapping)
        } |> sdl_try
        let name = bump ? "bgfx bump" : "bgfx instancing"
        let calls = instanced ? 1 : side * side
        set_title(window, "{name} | {side*side} cubes, {calls} draws | I: instancing | N: normal map | arrows: grid | Space/R/Esc") |> sdl_try
        SDL_Delay(16u)
    }
    return sdl_ok()
}

def run(device : SDL_GPUDevice?; window : SDL_Window?; bump : bool) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window), bump) $(var resources) {
        return animate(device, window, resources, bump)
    }
}
