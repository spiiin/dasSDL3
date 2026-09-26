options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_shader_boost

// Trusted compiled assets, described with named shader options.

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : SdlStatus {
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let extension = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/shaders/triangle"
    let vertex_options = gpu_shader("{base}.vert.{extension}", format, SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    let fragment_options = gpu_shader("{base}.frag.{extension}", format, SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    return sdl_scope() {
        let vertex : GpuShaderHandle = device |> with_gpu_shader_file(vertex_options) |> sdl_use
        let fragment : GpuShaderHandle = device |> with_gpu_shader_file(fragment_options) |> sdl_use
        verify(vertex != fragment)
        let description = gpu_shader_descriptor(device, fragment) |> sdl_try
        let entrypoint = gpu_shader_entrypoint(device, fragment) |> sdl_try
        print("Owned {extension} shaders: vertex={vertex}, fragment={fragment}, entry={entrypoint}, samplers={description.num_samplers}\n")

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
