options gen2
require dassdl3/sdl3_gpu_utilities_boost

[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            var data : array<uint8>
            resize(data,16)
            device |> with_gpu_buffer(data,SDL_GPU_BUFFERUSAGE_VERTEX) $(buffer) {
                device |> gpu_buffer_name(buffer,"example29 vertices")
                device |> with_gpu_rgba_texture(2u,2u) $(texture) {
                    device |> gpu_texture_name(texture,"example29 texture")
                }
            }
            print("GPU resource names assigned (visibility depends on debug tools)\n")
        }
    }
    return available ? 0 : 77
}
