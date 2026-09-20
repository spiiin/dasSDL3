options gen2
require dassdl3/sdl3_gpu_shader_boost

// Trusted compiled assets. General script pipeline creation is the next stage.
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
            let vertex_info = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_VERTEX)
            let fragment_info = gpu_shader_info(format,SDL_GPUShaderStage.SHADERSTAGE_FRAGMENT)
            let scope_ok_1 = device |> with_gpu_shader_file("{base}.vert.{extension}",vertex_info) $(vertex) {
                let scope_ok_2 = device |> with_gpu_shader_file("{base}.frag.{extension}",fragment_info) $(fragment) {
                    verify(vertex != fragment)
                    var query_result_1 : SDL_GPUShaderCreateInfo
                    if (!gpu_shader_descriptor(device,fragment,query_result_1)) { example_failed = true; print("SDL query: {SDL_GetError()}\n"); return }
                    let description = query_result_1
                    print("Owned {extension} shaders: vertex={vertex}, fragment={fragment}, entry={gpu_shader_entrypoint(device,fragment)}, samplers={description.num_samplers}\n")
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
