options gen2
require dassdl3/sdl3_gpu_pipeline_boost

// Independent pipeline creation. Native command-plan drawing is the next stage.
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
            let vi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
            let fi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
            let scope_ok_1 = device |> with_gpu_shader_file("{base}.vert.{extension}",vi) $(vertex : uint64) {
                let scope_ok_2 = device |> with_gpu_shader_file("{base}.frag.{extension}",fi) $(fragment : uint64) {
                    let scope_ok_3 = device |> with_gpu_graphics_pipeline(vertex,fragment,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(pipeline : uint64) {
                        var query_result_1 : SDL_GPUGraphicsPipelineCreateInfo
                        var operation_result_1 <- gpu_graphics_pipeline_descriptor(device,pipeline,query_result_1)
                        if (is_err(operation_result_1)) { example_failed = true; print("SDL query: {unwrap_err(operation_result_1).message}\n"); return err(unwrap_err(operation_result_1),type<SdlUnit>) }
                        let info = query_result_1
                        verify(info.primitive_type == SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
                        print("Owned graphics pipeline {pipeline}: {SDL_GetGPUDeviceDriver(device)}, sample 1, RGBA8\n")

                        return sdl_ok()
                    }
                    if (is_err(scope_ok_3)) { example_failed = true; print("SDL acquisition: {unwrap_err(scope_ok_3).message}\n") ; return err(unwrap_err(scope_ok_3),type<SdlUnit>) }

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
