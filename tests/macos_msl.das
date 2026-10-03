options gen2
require dassdl3/sdl3_gpu_shader_boost

[export]
def main(smoke : bool) : int {
    verify(SDLTest_shader_invalid_metadata())
    let result = with_sdl() {
        return with_gpu_device(SDL_GPU_SHADERFORMAT_MSL, true, "metal") $(device : SDL_GPUDevice?) {
            let vi = gpu_shader_info(SDL_GPU_SHADERFORMAT_MSL, SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
            let fi = gpu_shader_info(SDL_GPU_SHADERFORMAT_MSL, SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
            let vs = SDL_LoadGPUCheckedShader(device, "examples/assets/shaders/triangle.vert.msl", vi, "main0")
            if (*vs == 0ul) {return err(sdl_error("MSL vertex"), type<SdlUnit>)}
            let fs = SDL_LoadGPUCheckedShader(device, "examples/assets/shaders/triangle.frag.msl", fi, "main0")
            if (*fs == 0ul) {
                let error = sdl_error("MSL fragment")
                SDL_ReleaseGPUCheckedShader(device, vs)
                return err(error, type<SdlUnit>)
            }
            // The native probe consumes the shaders and compares rendered
            // triangle pixels against the same CPU oracle as SPIR-V/DXIL.
            if (!SDLTest_shader_pipeline_pixels(device, *vs, *fs)) {return err(sdl_error("MSL triangle pixels"), type<SdlUnit>)}
            print("Metal MSL shaders: rendered triangle pixels match CPU oracle.\n")
            return sdl_ok()
        }
    }
    if (is_err(result)) {let error = unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1}
    return 0
}
