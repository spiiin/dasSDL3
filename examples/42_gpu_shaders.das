options gen2
require dassdl3/sdl3_gpu_shader_boost

// Trusted compiled assets. General script pipeline creation is the next stage.

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let extension = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/shaders/triangle"
    let vertex_info = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    let fragment_info = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    return device |> with_gpu_shader_file("{base}.vert.{extension}",vertex_info) $(vertex : uint64) {
        return device |> with_gpu_shader_file("{base}.frag.{extension}",fragment_info) $(fragment : uint64) {
            verify(vertex != fragment)
            var query_result_1 : SDL_GPUShaderCreateInfo
            var gpu_shader_descriptor_result <- gpu_shader_descriptor(device,fragment,query_result_1)
            if (is_err(gpu_shader_descriptor_result)) { return err(unwrap_err(gpu_shader_descriptor_result),type<SdlUnit>) }
            let description = query_result_1
            print("Owned {extension} shaders: vertex={vertex}, fragment={fragment}, entry={unwrap_or(gpu_shader_entrypoint(device,fragment),"")}, samplers={description.num_samplers}\n")

            return sdl_ok()
        }
    }
}

[export]
def main(smoke : bool) : int {
    let result = with_sdl() {
        return with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            return run_gpu_example(device, smoke)
        } |> is_ok
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }

        return sdl_ok()
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
