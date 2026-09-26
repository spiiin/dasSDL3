options gen2
require dassdl3/sdl3_gpu_utilities_boost

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        let names <- move_unwrap(gpu_driver_names())
        verify(length(names) == SDL_GPUDriverCountChecked())
        verify(SDL_GPUDriverNameCopy(-1) == "")
        verify(SDL_GPUDriverNameCopy(length(names)) == "")
        verify(SDL_GPUShaderSupportChecked(0u, "") == -1)
        verify(SDL_GPUShaderSupportChecked(0x80000000u, "") == -1)
        // SDL_GPU_DRIVER overrides even an explicit preferred driver name.
        verify(SDL_GPUShaderSupportChecked(GPU_SHADER_FORMATS, "not-a-real-gpu-driver") >= 0)
        for (i in 0 .. length(names)) {
            verify(names[i] != "")
            verify(names[i] == SDL_GPUDriverNameCopy(i))
            print("Compiled driver {names[i]}, runtime supported: {gpu_supports_shaders(GPU_SHADER_FORMATS,names[i])}\n")
        }
        available = with_gpu_device(GPU_SHADER_FORMATS, true, "") $(device : SDL_GPUDevice?) {
            verify(unwrap_or(gpu_supports_shaders(GPU_SHADER_FORMATS, SDL_GetGPUDeviceDriver(device)), false))
            var bytes : array<uint8>
            resize(bytes, 16)
            var dead : GpuBufferHandle
            let scope_ok_1 = device |> with_gpu_buffer(bytes, SDL_GPU_BUFFERUSAGE_VERTEX) $(buffer : GpuBufferHandle) {
                dead = buffer
                is_ok(device |> gpu_buffer_name(buffer, "данные / vertex"))
                is_ok(device |> gpu_buffer_name(buffer, ""))
                let scope_ok_2 = device |> with_gpu_rgba_texture(2u, 2u) $(texture : GpuTextureHandle) {
                    is_ok(device |> gpu_texture_name(texture, "текстура / RGBA"))
                    is_ok(device |> gpu_texture_name(texture, ""))
                    verify(!SDL_SetGPUDataBufferNameChecked(device, GpuBufferHandle(*texture), "wrong kind"))
                    verify(!SDL_SetGPUTransferTextureNameChecked(device, GpuTextureHandle(*buffer), "wrong kind"))
                    var long_name = ""
                    for (i in 0 .. 4097) { long_name = "{long_name}x" }
                    verify(!SDL_SetGPUTransferTextureNameChecked(device, texture, long_name))
                    verify(!SDL_SetGPUDataBufferNameChecked(device, buffer, long_name))
                    let scope_ok_3 = with_gpu_device() $(other : SDL_GPUDevice?) {
                        verify(!SDL_SetGPUDataBufferNameChecked(other, buffer, "wrong device"))
                        verify(!SDL_SetGPUTransferTextureNameChecked(other, texture, "wrong device"))

                        return sdl_ok()
                    } |> is_ok
                    verify(scope_ok_3)
                    is_ok(device |> gpu_texture_name(texture, "still alive"))

                    return sdl_ok()
                } |> is_ok
                verify(scope_ok_2)

                return sdl_ok()
            } |> is_ok
            verify(scope_ok_1)
            verify(!SDL_SetGPUDataBufferNameChecked(device, dead, "stale"))
            verify(!SDL_SetGPUTransferTextureNameChecked(device, GpuTextureHandle(0ul), "invalid"))
            verify(!SDL_SetGPUDataBufferNameChecked(null, dead, "null device"))
            print("GPU discovery and checked resource names PASS\n")

            return sdl_ok()
        } |> is_ok

        return sdl_ok()
    } |> is_ok
    verify(scope_ok_0)
    return available ? 0 : 77
}
