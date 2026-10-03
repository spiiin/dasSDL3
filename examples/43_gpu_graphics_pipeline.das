options gen2
require gpu/file_shader_support
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_pipeline_boost

// Independent pipeline creation; direct command recording is shown in example 44.

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : SdlStatus {
    let backend = file_shader_backend(device)
    let format = backend.format
    let extension = backend.extension
    let base = "{SDL_GetBasePath()}assets/shaders/triangle"
    let vi = gpu_shader("{base}.vert.{extension}", format, SDL_GPUShaderStage.SHADERSTAGE_VERTEX) |> entrypoint(backend.entry)
    let fi = gpu_shader("{base}.frag.{extension}", format, SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT) |> entrypoint(backend.entry)
    return sdl_scope() {
        let vertex : GpuShaderHandle = device |> with_gpu_shader_file(vi) |> sdl_use
        let fragment : GpuShaderHandle = device |> with_gpu_shader_file(fi) |> sdl_use
        var description <- (gpu_pipeline(vertex, fragment)
            |> topology(SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
            |> rasterizer(SDL_GPURasterizerState(
                fill_mode = SDL_GPUFillMode.FILLMODE_FILL,
                cull_mode = SDL_GPUCullMode.CULLMODE_BACK,
                front_face = SDL_GPUFrontFace.FRONTFACE_COUNTER_CLOCKWISE,
                enable_depth_clip = true))
            |> sample_count(SDL_GPUSampleCount.SAMPLECOUNT_1)
            |> color_target(SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM))
        let pipeline : GpuPipelineHandle = device |> with_gpu_graphics_pipeline(description) |> sdl_use
        let info = gpu_graphics_pipeline_descriptor(device, pipeline) |> sdl_try
        verify(info.primitive_type == SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
        verify(info.rasterizer_state.cull_mode == SDL_GPUCullMode.CULLMODE_BACK)
        print("Owned graphics pipeline {pipeline}: {SDL_GetGPUDeviceDriver(device)}, sample 1, RGBA8\n")

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_gpu_device(GPU_SHADER_FORMATS, true, "") |> sdl_use
        return run_gpu_example(device, smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation == "with_gpu_device" ? 77 : 1
    }
    return 0
}
