options gen2
require dassdl3/sdl3_render_surface_34_boost
require dassdl3/sdl3_gpu_native_boost
require daslib/defer

[export]
def main(smoke : bool) : int {
    verify(SDL_Init(SDL_INIT_VIDEO)); defer(){SDL_Quit()}
    let device = SDL_CreateGPUDeviceDefault(SDL_GPU_SHADERFORMAT_SPIRV | SDL_GPU_SHADERFORMAT_DXIL, false, "")
    verify(device != null); defer(){SDL_DestroyGPUDevice(device)}
    let renderer = SDL_CreateGPURenderer(device, null); verify(renderer != null)
    defer(){SDL_DestroyRenderer(renderer)}
    verify(SDL_GetGPURendererDevice(renderer) == device)
    let target = SDL_CreateTexture(renderer, SDL_PixelFormat.PIXELFORMAT_RGBA32, SDL_TextureAccess.TEXTUREACCESS_TARGET, 16, 16)
    verify(target != null); defer(){SDL_SetRenderTarget(renderer, null); SDL_DestroyTexture(target)}
    verify(SDL_SetRenderTarget(renderer, target))
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let info = SDL_GPUShaderCreateInfo(format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL,
        stage = SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT, num_uniform_buffers = 1u)
    let extension = spirv ? "spv" : "dxil"
    var shader = SDL_LoadGPUShaderFile(device, info, "{SDL_GetBasePath()}assets/shaders/render_state.frag.{extension}", "main")
    verify(shader != null); defer(){SDL_ReleaseGPUShader(device, shader)}
    var create_info = SDL_GPURenderStateCreateInfo(fragment_shader = shader)
    var state : SDL_GPURenderState?
    unsafe{state = SDL_CreateGPURenderState(renderer, addr(create_info))}
    verify(state != null)
    {
        defer(){SDL_SetGPURenderState(renderer, null); SDL_DestroyGPURenderState(state)}
        var tint <- array<float>(0.0, 1.0, 0.0, 1.0)
        unsafe{verify(SDL_SetGPURenderStateFragmentUniforms(state, 0u, addr(tint[0]), 16u))}
        tint[1] = 0.0// SDL copied the uniform payload.
        verify(SDL_SetGPURenderState(renderer, state))
        var rect = SDL_FRect(w = 16.0, h = 16.0)
        verify(SDL_RenderFillRectRef(renderer, rect))
        let pixels = SDL_RenderReadPixels(renderer, null); verify(pixels != null)
        verify(unwrap(read_surface_pixel(pixels, 8, 8)) == uint4(0u, 255u, 0u, 255u)); SDL_DestroySurface(pixels)
        tint[2] = 1.0
        verify(is_ok(set_gpu_render_state_fragment_uniforms(state, 0u, tint)))
        verify(SDL_RenderFillRectRef(renderer, rect))
        let blue = SDL_RenderReadPixels(renderer, null); verify(blue != null)
        verify(unwrap(read_surface_pixel(blue, 8, 8)) == uint4(0u, 0u, 255u, 255u)); SDL_DestroySurface(blue)
        var empty : array<uint8>; verify(is_err(set_gpu_render_state_fragment_uniforms(state, 0u, empty)))
        var bytes <- array<uint8>(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 128, 63, 0, 0, 128, 63)
        verify(is_ok(set_gpu_render_state_fragment_uniforms(state, 0u, bytes)))
    }
    var samplers : array<SDL_GPUTextureSamplerBinding>
    var textures : array<SDL_GPUTexture?>; var buffers : array<SDL_GPUBuffer?>
    let early = with_gpu_render_state(renderer, shader, samplers, textures, buffers, 0u) $(resource) {
        verify(is_ok(set_gpu_render_state(renderer, resource)))
        return err(SdlError(operation = "body", message = "early return"), type<SdlUnit>)
    }
    verify(is_err(early) && unwrap_err(early).message == "early return")
    verify(SDL_RenderClear(renderer)) // Scope cleared the selected state before destroying it.
    let indexed = SDL_CreateTexture(renderer, SDL_PixelFormat.PIXELFORMAT_INDEX8, SDL_TextureAccess.TEXTUREACCESS_STATIC, 2, 2)
    verify(indexed != null); defer(){SDL_DestroyTexture(indexed)}
    let palette = SDL_CreatePalette(256); verify(palette != null)
    verify(SDL_SetTexturePalette(indexed, palette) && SDL_GetTexturePalette(indexed) == palette)
    var palette_result <- texture_palette(indexed); var maybe_palette <- move_unwrap(palette_result); verify(is_some(maybe_palette))
    SDL_DestroyPalette(palette) // Texture retains a reference.
    verify(is_ok(set_texture_palette(indexed, null)))
    verify(SDL_GetTexturePalette(indexed) == null)
    verify(is_ok(with_gpu_renderer(device, null) $(other) {
        verify(SDL_GetGPURendererDevice(other) == device); return sdl_ok()
    }))
    verify(SDL_SetGPURenderState(renderer, null) && SDL_RenderPresent(renderer))
    verify(SDL_GetGPURendererDevice(null) == null && !SDL_SetGPURenderState(null, null))
    verify(SDL_CreateGPURenderState(null, null) == null)
    verify(!SDL_SetGPURenderStateFragmentUniforms(null, 0u, null, 0u)); SDL_DestroyGPURenderState(null)
    print("SDL 3.4 GPU renderer: native state, uniform copies, pixel readback, palette and cleanup PASS\n")
    return 0
}
