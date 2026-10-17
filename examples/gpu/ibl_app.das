options gen2
module ibl_app shared public
require multipass_support public
require ./shaders/ibl_shaders.das as shaders
require daslib/defer
require daslib/match
struct Settings { gloss : float = 0.7; metal : float = 0.7; exposure : float = 0.0; specular_workflow : bool = false; diffuse : bool = true; specular : bool = true }
struct Resources { mesh : GeometryBuffers; lighting, sky : SDL_GPUGraphicsPipeline ?; radiance, irradiance, depth : SDL_GPUTexture ?; sampler : SDL_GPUSampler ?; size : uint2 }
def release(device : SDL_GPUDevice?; var r : Resources) {
    release(device, r.mesh)
    for (p in fixed_array(r.lighting, r.sky)) { if (p != null) { SDL_ReleaseGPUGraphicsPipeline(device, p) } }
    for (t in fixed_array(r.radiance, r.irradiance, r.depth)) { if (t != null) { SDL_ReleaseGPUTexture(device, t) } }
    if (r.sampler != null) { SDL_ReleaseGPUSampler(device, r.sampler) }
}
def upload_cube(device : SDL_GPUDevice?; var target : SDL_GPUTexture?; filename : string; side, levels : uint) : SdlStatus {
    let bytes <- load_file("{SDL_GetBasePath()}assets/bgfx/{filename}") |> sdl_try
    var expected = 0u
    for (mip in 0u..levels) { let size = max(1u, side >> mip); expected += size * size * 8u * 6u }
    if (uint(length(bytes)) != expected) { return err(SdlError(operation = filename, message = "Invalid IBL mip chain"), type<SdlUnit>) }
    return sdl_scope() {
        var transfer : SDL_GPUTransferBuffer? = with_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = expected)) |> sdl_use
        sdl_status(SDL_WriteGPUTransferBufferBytes(device, transfer, expected, 0u, bytes, false), "Upload IBL") |> sdl_try
        var command : SDL_GPUCommandBuffer?& = with_native_gpu_commands(device) |> sdl_use
        with_native_gpu_copy_pass(command) $(var pass_ : SDL_GPUCopyPass?&) {
            var offset = 0u
            for (face in 0u..6u) { for (mip in 0u..levels) {
                let size = max(1u, side >> mip)
                SDL_UploadToGPUTextureRef(pass_, SDL_GPUTextureTransferInfo(transfer_buffer = transfer, offset = offset, pixels_per_row = size, rows_per_layer = size), SDL_GPUTextureRegion(texture = target, mip_level = mip, layer = face, w = size, h = size, d = 1u), false)
                offset += size * size * 8u
            } }
            return sdl_ok()
        } |> sdl_try
        return native_gpu_submit(command)
    }
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : Resources) : SdlStatus>) : SdlStatus {
    var r : Resources; defer() { release(device, r) }
    let mesh <- load_geometry("{SDL_GetBasePath()}assets/meshes/bunny.msh") |> sdl_try
    var g = upload_geometry(device, mesh) |> sdl_try; r.mesh = g
    var info = gpu_texture(256u, 256u, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, SDL_GPU_TEXTUREUSAGE_SAMPLER) |> texture_shape(SDL_GPUTextureType.TEXTURETYPE_CUBE, 6u) |> mip_levels(9u)
    r.radiance = SDL_CreateGPUTextureRef(device, info)
    if (r.radiance == null) { return err(sdl_error("Create radiance"), type<SdlUnit>) }
    var t = texture(device, 128u, 128u, SDL_GPUTextureFormat.TEXTUREFORMAT_R16G16B16A16_FLOAT, SDL_GPU_TEXTUREUSAGE_SAMPLER, true) |> sdl_try; r.irradiance = t
    upload_cube(device, r.radiance, "kyoto_lod.rgba16f", 256u, 9u) |> sdl_try
    upload_cube(device, r.irradiance, "kyoto_irr.rgba16f", 128u, 1u) |> sdl_try
    var sampling = gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR)
    sampling.mipmap_mode = SDL_GPUSamplerMipmapMode.SAMPLERMIPMAPMODE_LINEAR; sampling.max_lod = 8.0
    r.sampler = SDL_CreateGPUSamplerRef(device, sampling)
    if (r.sampler == null) { return err(sdl_error("Create IBL sampler"), type<SdlUnit>) }
    let colors <- array(gpu_color_target(format))
    var p = pass_pipeline(device, shaders::ibl_vertex, shaders::ibl_vertex_reflect, shaders::ibl_fragment, shaders::ibl_fragment_reflect, colors) |> sdl_try; r.lighting = p
    p = pass_pipeline(device, shaders::ibl_fullscreen, shaders::ibl_fullscreen_reflect, shaders::ibl_sky, shaders::ibl_sky_reflect, colors, false, false) |> sdl_try; r.sky = p
    return body(r)
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : Resources; var output : SDL_GPUTexture?; width, height : uint; time : float; settings : Settings) : SdlStatus {
    replace_depth(device, r.depth, r.size, width, height) |> sdl_try
    let eye = float3(0.0, 1.5, -7.0)
    var mat = shaders::Material(eye = float4(eye, float(width) / float(height)), albedo = float4(0.75, 0.5, 0.25, 1.0), specular = float4(0.8, 0.8, 0.8, settings.specular_workflow ? 1.0 : 0.0), parameters = float4(settings.gloss, settings.metal, settings.exposure, time * 0.1), light = float4(-0.5, 0.8, -0.5, 0.0), light_color = float4(0.3), toggles = float4(1.0, 1.0, settings.diffuse ? 1.0 : 0.0, settings.specular ? 1.0 : 0.0))
    push_gpu_dsl_fragment_uniform(command, 0u, mat) |> sdl_try
    var images <- array(r.radiance, r.irradiance)
    // Sky shader only references radiance (one sampler).
    var sky <- array(r.radiance)
    fullscreen(command, r.sky, output, sky, r.sampler) |> sdl_try
    let colors <- array(attachment(output, float4(0.0), true)); let depth = depth_attachment(r.depth)
    return with_native_gpu_render_pass(command, colors, depth) $(var pass_ : SDL_GPURenderPass?&) {
        SDL_BindGPUGraphicsPipeline(pass_, r.lighting)
        bind_images(pass_, images, r.sampler) |> sdl_try
        let vp = camera_matrix(width, height, eye, float3(0.0, 0.3, 0.0))
        push_gpu_dsl_vertex_uniform(command, 0u, shaders::Transform(model = model_matrix(float3(0.0), float3(2.0), time * 0.15), vp = vp)) |> sdl_try
        return draw_geometry(pass_, r.mesh)
    }
}
def run(device : SDL_GPUDevice?; window : SDL_Window?; smoke : bool) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var settings = Settings(); var running = true; var frames = 0; let start = SDL_GetTicks()
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) { running = false }
                match (event) { if (SdlEvent(key_down = $v(k))) {
                    if (k.keycode == SDLK_LEFT) { settings.gloss = max(0.0, settings.gloss - 0.05) }
                    elif (k.keycode == SDLK_RIGHT) { settings.gloss = min(1.0, settings.gloss + 0.05) }
                    elif (k.keycode == SDLK_UP) { settings.metal = min(1.0, settings.metal + 0.05) }
                    elif (k.keycode == SDLK_DOWN) { settings.metal = max(0.0, settings.metal - 0.05) }
                    elif (!k.repeat && k.keycode == SDLK_M) { settings.specular_workflow = !settings.specular_workflow }
                    elif (!k.repeat && k.keycode == SDLK_D) { settings.diffuse = !settings.diffuse }
                    elif (!k.repeat && k.keycode == SDLK_S) { settings.specular = !settings.specular }
                } if (_) {} }
            }
            if (!running) { break }
            let time = float(SDL_GetTicks() - start) * 0.001
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var output : SDL_GPUTexture?; width, height : uint) { return draw(device, command, r, output, width, height, time, settings) } |> sdl_try
            set_title(window, "IBL | Left/Right: gloss {settings.gloss} | Up/Down: reflectivity {settings.metal} | M: workflow | D/S: diffuse/specular IBL") |> sdl_try
            frames++; if (smoke && frames >= 3) { break }
        }
        return sdl_ok()
    }
}
