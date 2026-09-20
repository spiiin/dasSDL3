options gen2
require dassdl3/sdl3_gpu_volume_boost

// Upload a padded 3D image, copy a box crossing two depth slices, read it back.
var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            var source, expected, actual : array<uint8>
            let row_pitch = 23u
            let slice_pitch = 76u
            resize(source,218) // Last row needs no trailing padding.
            for (i in 0 .. length(source)) { source[i] = uint8(i*13+7) }
            resize(expected,48); resize(actual,48)
            for (z in 0 .. 2) { for (y in 0 .. 2) { for (x in 0 .. 12) {
                expected[(z*2+y)*12+x] = source[(z+1)*int(slice_pitch)+y*int(row_pitch)+4+x]
            } } }
            let scope_ok_1 = device |> with_gpu_volume(uint3(5u,3u,3u)) $(volume) {
                let scope_ok_2 = device |> with_gpu_volume(uint3(3u,2u,2u)) $(copy) {
                    if (!(device |> gpu_upload_volume(volume,0u,uint3(0u),uint3(5u,3u,3u),source,row_pitch,slice_pitch))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    if (!(device |> gpu_copy_volume(volume,0u,uint3(1u,0u,1u),uint3(3u,2u,2u),copy,0u,uint3(0u)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    let scope_ok_3 = device |> with_gpu_volume_readback(copy,0u,uint3(0u),uint3(3u,2u,2u)) $(ticket) {
                        if (!(device |> gpu_wait_readback(ticket))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        if (!(device |> gpu_readback_bytes(ticket,actual))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    }
                    if (!scope_ok_3) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
                }
                if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            for (i in 0 .. length(actual)) { verify(actual[i] == expected[i]) }
            print("3D texture: padded 5x3x3 upload, 3x2x2 copy and 48-byte readback PASS ({SDL_GetGPUDeviceDriver(device)})\n")
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
