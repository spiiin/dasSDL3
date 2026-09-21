options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_gpu_pipeline_boost

// Independent pipeline creation; direct command recording is shown in example 44.

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    let spirv = (SDL_GetGPUShaderFormats(device) & SDL_GPU_SHADERFORMAT_SPIRV) != 0u
    let format = spirv ? SDL_GPU_SHADERFORMAT_SPIRV : SDL_GPU_SHADERFORMAT_DXIL
    let extension = spirv ? "spv" : "dxil"
    let base = "{SDL_GetBasePath()}assets/shaders/triangle"
    let vi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
    let fi = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
    return device |> with_gpu_shader_file("{base}.vert.{extension}",vi) $(vertex : GpuShaderHandle) {
        return device |> with_gpu_shader_file("{base}.frag.{extension}",fi) $(fragment : GpuShaderHandle) {
            return device |> with_gpu_graphics_pipeline(vertex,fragment,SDL_GPUTextureFormat.TEXTUREFORMAT_R8G8B8A8_UNORM) $(pipeline : GpuPipelineHandle) {
                let info = gpu_graphics_pipeline_descriptor(device,pipeline) |> sdl_try
                verify(info.primitive_type == SDL_GPUPrimitiveType.PRIMITIVETYPE_TRIANGLELIST)
                print("Owned graphics pipeline {pipeline}: {SDL_GetGPUDeviceDriver(device)}, sample 1, RGBA8\n")

                return sdl_ok()
            }
        }
    }
}

[export]
def main(smoke : bool) : int {
    let result = with_sdl() {
        return with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device : SDL_GPUDevice?) {
            return run_gpu_example(device, smoke)
        }
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
