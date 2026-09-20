options gen2
require dassdl3/sdl3_gpu_utilities_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            var data : array<uint8>
            resize(data,16)
            let scope_ok_1 = device |> with_gpu_buffer(data,SDL_GPU_BUFFERUSAGE_VERTEX) $(buffer) {
                if (!(device |> gpu_buffer_name(buffer,"example29 vertices"))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                let scope_ok_2 = device |> with_gpu_rgba_texture(2u,2u) $(texture) {
                    if (!(device |> gpu_texture_name(texture,"example29 texture"))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                }
                if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            print("GPU resource names assigned (visibility depends on debug tools)\n")
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
