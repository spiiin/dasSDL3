options gen2
require dassdl3/sdl3_gpu_pipeline_boost

// Independent pipeline creation. Native command-plan drawing is the next stage.
var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
            let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
            let extension = spirv ? "spv" : "dxil"
            let base = "{SDL_GetBasePath()}assets/shaders/triangle"
            let vi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
            let fi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
            let scope_ok_1 = device |> with_gpu_shader_file("{base}.vert.{extension}",vi) $(vertex) {
                let scope_ok_2 = device |> with_gpu_shader_file("{base}.frag.{extension}",fi) $(fragment) {
                    let scope_ok_3 = device |> with_gpu_graphics_pipeline(vertex,fragment,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(pipeline) {
                        var query_result_1 : SDL_GPUGraphicsPipelineCreateInfo
                        if (!gpu_graphics_pipeline_descriptor(device,pipeline,query_result_1)) { example_failed = true; print("SDL query: {SDL_GetError()}\n"); return }
                        let info = query_result_1
                        verify(info.primitive_type == SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
                        print("Owned graphics pipeline {pipeline}: {SDL_GetGPUDeviceDriver(device)}, sample 1, RGBA8\n")
                    }
                    if (!scope_ok_3) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
                }
                if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
        }
        if (!available) { print("GPU unavailable: {SDL_GetError()}\n") }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
