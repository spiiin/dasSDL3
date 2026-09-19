options gen2
require dassdl3/sdl3_gpu_utilities_boost

[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        let names <- gpu_driver_names()
        verify(length(names) == SDL_GPUDriverCountChecked())
        verify(SDL_GPUDriverNameCopy(-1) == "")
        verify(SDL_GPUDriverNameCopy(length(names)) == "")
        verify(SDL_GPUShaderSupportChecked(0u,"") == -1)
        verify(SDL_GPUShaderSupportChecked(0x80000000u,"") == -1)
        // SDL_GPU_DRIVER overrides even an explicit preferred driver name.
        verify(SDL_GPUShaderSupportChecked(GPU_CLEAR_FORMATS,"not-a-real-gpu-driver") >= 0)
        for (i in 0 .. length(names)) {
            verify(names[i] != "")
            verify(names[i] == SDL_GPUDriverNameCopy(i))
            print("Compiled driver {names[i]}, runtime supported: {gpu_supports_shaders(GPU_CLEAR_FORMATS,names[i])}\n")
        }
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            verify(gpu_supports_shaders(GPU_CLEAR_FORMATS,SDL_GetGPUDeviceDriver(device)))
            var bytes : array<uint8>
            resize(bytes,16)
            var dead = 0ul
            device |> with_gpu_buffer(bytes,SDL_GPU_BUFFERUSAGE_VERTEX) $(buffer) {
                dead = buffer
                device |> gpu_buffer_name(buffer,"данные / vertex")
                device |> gpu_buffer_name(buffer,"")
                device |> with_gpu_rgba_texture(2u,2u) $(texture) {
                    device |> gpu_texture_name(texture,"текстура / RGBA")
                    device |> gpu_texture_name(texture,"")
                    verify(!SDL_SetGPUDataBufferNameChecked(device,texture,"wrong kind"))
                    verify(!SDL_SetGPUTransferTextureNameChecked(device,buffer,"wrong kind"))
                    var long_name = ""
                    for (i in 0 .. 4097) { long_name = "{long_name}x" }
                    verify(!SDL_SetGPUTransferTextureNameChecked(device,texture,long_name))
                    verify(!SDL_SetGPUDataBufferNameChecked(device,buffer,long_name))
                    with_gpu_device() $(other) {
                        verify(!SDL_SetGPUDataBufferNameChecked(other,buffer,"wrong device"))
                        verify(!SDL_SetGPUTransferTextureNameChecked(other,texture,"wrong device"))
                    }
                    device |> gpu_texture_name(texture,"still alive")
                }
            }
            verify(!SDL_SetGPUDataBufferNameChecked(device,dead,"stale"))
            verify(!SDL_SetGPUTransferTextureNameChecked(device,0ul,"invalid"))
            verify(!SDL_SetGPUDataBufferNameChecked(null,dead,"null device"))
            print("GPU discovery and checked resource names PASS\n")
        }
    }
    return available ? 0 : 77
}
