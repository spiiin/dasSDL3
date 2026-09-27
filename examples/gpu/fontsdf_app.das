options gen2
module fontsdf_app shared public
require bgfx_support public
require dassdl3/sdl3_ttf_boost public
require dassdl3/sdl3_shader_uniforms
require dassdl3/sdl3_gpu_sampler_boost
require dassdl3/sdl3_events
require dassdl3/sdl3_window_boost
require ./shaders/fontsdf_shaders.das as shaders
require daslib/defer
require daslib/match
require math

let TEXT_CAPACITY = 2097152u
let DEMO_TEXT = "A Scandal in Bohemia\nTo Sherlock Holmes she is always THE woman.\nI have seldom heard him mention her under\nany other name.\n\nSigned distance fields:\nscale, rotate, outline, shadow.\nABCDEFGHIJKLMNOPQRSTUVWXYZ 0123456789"
struct TextControls {
    scale : float = 0.9
    angle : float = 0.0
    outline : bool = true
    shadow : bool = true
    scroll : float = 0.0
}
struct TextResources {
    pipeline : SDL_GPUGraphicsPipeline?
    sampler : SDL_GPUSampler?
    vb, ib : SDL_GPUBuffer?
    upload : SDL_GPUTransferBuffer?
    text : TTF_Text? const
    wrap_width : int
    layout_size : int2
}
def release(device : SDL_GPUDevice?; var r : TextResources) {
    if (r.pipeline != null) {
        SDL_ReleaseGPUGraphicsPipeline(device, r.pipeline)
    }
    if (r.sampler != null) {
        SDL_ReleaseGPUSampler(device, r.sampler)
    }
    if (r.vb != null) {
        SDL_ReleaseGPUBuffer(device, r.vb)
    }
    if (r.ib != null) {
        SDL_ReleaseGPUBuffer(device, r.ib)
    }
    if (r.upload != null) {
        SDL_ReleaseGPUTransferBuffer(device, r.upload)
    }
}
def with_resources(device : SDL_GPUDevice?; format : SDL_GPUTextureFormat; body : block<(var r : TextResources) : SdlStatus>) : SdlStatus {
    return sdl_scope() {
        with_ttf() |> sdl_use
        let font : TTF_Font? = with_font("{SDL_GetBasePath()}assets/libraries/JetBrainsMono-Regular.ttf", 32.0) |> sdl_use
        sdl_status(TTF_SetFontSDF(font, true), "TTF_SetFontSDF") |> sdl_try
        if (!TTF_GetFontSDF(font)) {
            return err(SdlError(operation = "SDF font", message = "SDF mode was not enabled"), type<SdlUnit>)
        }
        let engine : TTF_TextEngine? = device |> with_gpu_text_engine() |> sdl_use
        let text : TTF_Text? = engine |> with_text(font, DEMO_TEXT) |> sdl_use
        var r = TextResources(text = text)
        defer() {
            release(device, r)
        }
        var vs : SDL_GPUShader? = device |> with_example_shader(shaders::fontsdf_vertex, shaders::fontsdf_vertex_reflect) |> sdl_use
        var fs : SDL_GPUShader? = device |> with_example_shader(shaders::fontsdf_fragment, shaders::fontsdf_fragment_reflect) |> sdl_use
        let layout <- array(SDL_GPUVertexBufferDescription(pitch = 32u))
        let attributes <- array(SDL_GPUVertexAttribute(format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2), SDL_GPUVertexAttribute(location = 1u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT2, offset = 8u), SDL_GPUVertexAttribute(location = 2u, format = SDL_GPUVertexElementFormat.VERTEXELEMENTFORMAT_FLOAT4, offset = 16u))
        let colors <- array(SDL_GPUColorTargetDescription(format = format, blend_state = SDL_GPUColorTargetBlendState(color_blend_op = SDL_GPUBlendOp.BLENDOP_ADD, alpha_blend_op = SDL_GPUBlendOp.BLENDOP_ADD, enable_blend = true, src_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE, dst_color_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA, src_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE, dst_alpha_blendfactor = SDL_GPUBlendFactor.BLENDFACTOR_ONE_MINUS_SRC_ALPHA)))
        var pipeline = create_native_gpu_graphics_pipeline(device, SDL_GPUGraphicsPipelineCreateInfo(vertex_shader = vs, fragment_shader = fs, rasterizer_state = SDL_GPURasterizerState(enable_depth_clip = true)), layout, attributes, colors) |> sdl_try
        r.pipeline = pipeline
        var buffer = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_VERTEX, size = TEXT_CAPACITY)) |> sdl_try
        r.vb = buffer
        buffer = create_native_gpu_buffer(device, SDL_GPUBufferCreateInfo(usage = SDL_GPU_BUFFERUSAGE_INDEX, size = TEXT_CAPACITY)) |> sdl_try
        r.ib = buffer
        var upload = create_native_gpu_transfer_buffer(device, SDL_GPUTransferBufferCreateInfo(usage = SDL_GPUTransferBufferUsage.TRANSFERBUFFERUSAGE_UPLOAD, size = TEXT_CAPACITY)) |> sdl_try
        r.upload = upload
        r.sampler = SDL_CreateGPUSamplerRef(device, gpu_sampler_info(SDL_GPUFilter.FILTER_LINEAR, SDL_GPUSamplerAddressMode.SAMPLERADDRESSMODE_CLAMP_TO_EDGE))
        if (r.sampler == null) {
            return err(sdl_error("SDL_CreateGPUSampler"), type<SdlUnit>)
        }
        return body(r)
    }
}
def draw(device : SDL_GPUDevice?; command : SDL_GPUCommandBuffer?; var r : TextResources; var target : SDL_GPUTexture?; width, height : uint; controls : TextControls) : SdlStatus {
    let wrap_width = max(1, int((float(width) - 60.0) / controls.scale))
    if (r.wrap_width != wrap_width) {
        sdl_status(TTF_SetTextWrapWidth(r.text, wrap_width), "TTF_SetTextWrapWidth") |> sdl_try
        let size = text_size(r.text) |> sdl_try
        r.layout_size = size
        r.wrap_width = wrap_width
    }
    let clear <- array(SDL_GPUColorTargetInfo(texture = target, load_op = SDL_GPULoadOp.LOADOP_CLEAR, store_op = SDL_GPUStoreOp.STOREOP_STORE, clear_color = SDL_FColor(r = 0.12, g = 0.14, b = 0.18, a = 1.0)))
    with_native_gpu_render_pass(command, clear) $(var pass_) {
        return sdl_ok()
    }  |> sdl_try
    var sequences <- gpu_text_draw_data(r.text) |> sdl_try
    for (sequence in sequences) {
        if (sequence.image_type == TTF_ImageType.IMAGE_INVALID) {
            continue
        }
        // SDL_ttf 3.2.2 reports FreeType single-channel SDF images as ALPHA.
        // The font is explicitly configured and checked for SDF above.
        if (sequence.image_type != TTF_ImageType.IMAGE_SDF && sequence.image_type != TTF_ImageType.IMAGE_ALPHA) {
            return err(SdlError(operation = "SDF atlas", message = "Expected distance-field glyphs: {int(sequence.image_type)}"), type<SdlUnit>)
        }
        var vertices : array<float>
        var indices : array<uint8>
        if (length(sequence.xy) != length(sequence.uv) || length(sequence.xy) % 4 != 0) {
            return err(SdlError(operation = "SDF quads", message = "Unexpected text-engine vertex layout"), type<SdlUnit>)
        }
        for (i in 0 .. length(sequence.xy)) {
            let base = i / 4 * 4
            var lower = float2(sequence.uv[base].x, sequence.uv[base].y)
            var upper = lower
            for (j in 1 .. 4) {
                let uv = float2(sequence.uv[base + j].x, sequence.uv[base + j].y)
                lower = min(lower, uv)
                upper = max(upper, uv)
            }
            push(vertices, sequence.xy[i].x)
            push(vertices, sequence.xy[i].y)
            push(vertices, sequence.uv[i].x)
            push(vertices, sequence.uv[i].y)
            push(vertices, lower.x)
            push(vertices, lower.y)
            push(vertices, upper.x)
            push(vertices, upper.y)
        }
        for (index in sequence.indices) {
            for (b in 0 .. 4) {
                push(indices, uint8(uint(index) >> uint(b * 8)))
            }
        }
        let vb_size = uint(length(vertices)) * 4u
        let ib_size = uint(length(indices))
        if (vb_size + ib_size > TEXT_CAPACITY) {
            return err(SdlError(operation = "SDF upload", message = "Text exceeds upload capacity"), type<SdlUnit>)
        }
        write_native_gpu_transfer_floats(device, r.upload, TEXT_CAPACITY, 0u, vertices, true) |> sdl_try
        sdl_status(SDL_WriteGPUTransferBufferBytes(device, r.upload, TEXT_CAPACITY, vb_size, indices, false), "text indices") |> sdl_try
        with_native_gpu_copy_pass(command) $(var copy_) {
            SDL_UploadToGPUBufferRef(copy_, SDL_GPUTransferBufferLocation(transfer_buffer = r.upload), SDL_GPUBufferRegion(buffer = r.vb, size = vb_size), true)
            SDL_UploadToGPUBufferRef(copy_, SDL_GPUTransferBufferLocation(transfer_buffer = r.upload, offset = vb_size), SDL_GPUBufferRegion(buffer = r.ib, size = ib_size), true)
            return sdl_ok()
        }  |> sdl_try
        let transform = shaders::TextTransform(viewport = float4(float(width), float(height), controls.scale, controls.angle), origin = float4(30.0, 60.0 - clamp(controls.scroll, 0.0, max(0.0, float(r.layout_size.y) * controls.scale + 90.0 - float(height))), 0.0, 0.0))
        let style = shaders::TextStyle(effects = float4(controls.outline ? 0.1 : 0.0, 2.0, 3.0, 3.0), color = float4(1.0), outline = float4(0.9, 0.2, 0.1, 1.0), shadow = float4(0.0, 0.0, 0.0, controls.shadow ? 0.7 : 0.0))
        push_gpu_dsl_vertex_uniform(command, 0u, transform) |> sdl_try
        push_gpu_dsl_fragment_uniform(command, 0u, style) |> sdl_try
        let targets <- array(SDL_GPUColorTargetInfo(texture = target, load_op = SDL_GPULoadOp.LOADOP_LOAD, store_op = SDL_GPUStoreOp.STOREOP_STORE))
        with_native_gpu_render_pass(command, targets) $(var pass_) {
            SDL_BindGPUGraphicsPipeline(pass_, r.pipeline)
            let vb <- array(SDL_GPUBufferBinding(buffer = r.vb))
            let textures <- array(SDL_GPUTextureSamplerBinding(texture = sequence.atlas_texture, sampler = r.sampler))
            sdl_status(SDL_BindGPUVertexBuffersArray(pass_, 0u, vb), "text vertices") |> sdl_try
            SDL_BindGPUIndexBufferRef(pass_, SDL_GPUBufferBinding(buffer = r.ib), SDL_GPUIndexElementSize.INDEXELEMENTSIZE_32BIT)
            sdl_status(SDL_BindGPUFragmentSamplersArray(pass_, 0u, textures), "text atlas") |> sdl_try
            SDL_DrawGPUIndexedPrimitives(pass_, uint(length(sequence.indices)), 1u, 0u, 0, 0u)
            return sdl_ok()
        }  |> sdl_try
    }
    return sdl_ok()
}
def run(device : SDL_GPUDevice?; window : SDL_Window?) : SdlStatus {
    return with_resources(device, SDL_GetGPUSwapchainTextureFormat(device, window)) $(var r) {
        var controls = TextControls()
        var running = true
        while (running) {
            for (event in poll_events()) {
                if (should_close(event, window)) {
                    running = false
                }
                match (event) {
                    if (SdlEvent(key_down = $v(key))) {
                        if (!key.repeat) {
                            if (key.keycode == SDLK_O) {
                                controls.outline = !controls.outline
                            }
                            elif (key.keycode == SDLK_S) {
                                controls.shadow = !controls.shadow
                            }
                            elif (key.keycode == SDLK_UP) {
                                controls.scale = min(4.0, controls.scale + 0.1)
                            }
                            elif (key.keycode == SDLK_DOWN) {
                                controls.scale = max(0.2, controls.scale - 0.1)
                            }
                            elif (key.keycode == SDLK_LEFT) {
                                controls.angle -= 0.1
                            }
                            elif (key.keycode == SDLK_RIGHT) {
                                controls.angle += 0.1
                            }
                            elif (key.keycode == SDLK_PAGEUP) {
                                controls.scroll -= 40.0
                            }
                            elif (key.keycode == SDLK_PAGEDOWN) {
                                controls.scroll += 40.0
                            }
                            elif (key.keycode == SDLK_R) {
                                controls = TextControls()
                            }
                        }
                    } if (_) {
                    }
                }
            }
            if (!running) {
                break
            }
            with_native_gpu_swapchain(device, window) $(command : SDL_GPUCommandBuffer?; var target : SDL_GPUTexture?; width, height : uint) {
                return draw(device, command, r, target, width, height, controls)
            }  |> sdl_try
            set_title(window, "SDF text | arrows: scale/rotate | O: outline | S: shadow | PgUp/PgDn: scroll | R/Esc") |> sdl_try
            SDL_Delay(16u)
        }
        return sdl_ok()
    }
}
