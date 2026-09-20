options gen2
require dassdl3/sdl3_gpu_shader_boost

// Trusted compiled assets. General script pipeline creation is the next stage.
var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let base = "{SDL_GetBasePath()}assets/shaders/triangle"
            let vertex_info = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
            let fragment_info = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
            let scope_ok_1 = device |> with_gpu_shader_file("{base}.vert.{extension}",vertex_info) $(vertex : uint64) {
                let scope_ok_2 = device |> with_gpu_shader_file("{base}.frag.{extension}",fragment_info) $(fragment : uint64) {
                    verify(vertex != fragment)
                    var query_result_1 : SDL_GPUShaderCreateInfo
                    var operation_result_1 <- gpu_shader_descriptor(device,fragment,query_result_1)
                    if (is_err(operation_result_1)) { example_failed = true; print("SDL query: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                    let description = query_result_1
                    print("Owned {extension} shaders: vertex={vertex}, fragment={fragment}, entry={unwrap_or(gpu_shader_entrypoint(device,fragment),"")}, samplers={description.num_samplers}\n")

                    return sdl_ok()
                }
                if (is_err(scope_ok_2)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_2).message}\n") ; return err(unwrap_err(scope_ok_2),type<SdlUnit>) }

                return sdl_ok()
            }
            if (is_err(scope_ok_1)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_1).message}\n") ; return err(unwrap_err(scope_ok_1),type<SdlUnit>) }

            return sdl_ok()
        } |> is_ok
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }

        return sdl_ok()
    }
    if (is_err(scope_ok_0)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_0).message}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
