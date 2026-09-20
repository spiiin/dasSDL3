options gen2
require dassdl3/sdl3_gpu_volume_boost

// Upload a padded 3D image, copy a box crossing two depth slices, read it back.

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var source, expected, actual : array<uint8>
    let row_pitch = 23u
    let slice_pitch = 76u
    resize(source,218) // Last row needs no trailing padding.
    for (i in 0 .. length(source)) { source[i] = uint8(i*13+7) }
    resize(expected,48); resize(actual,48)
    for (z in 0 .. 2) { for (y in 0 .. 2) { for (x in 0 .. 12) {
        expected[(z*2+y)*12+x] = source[(z+1)*int(slice_pitch)+y*int(row_pitch)+4+x]
    } } }
    let gpu_volume_result = device |> with_gpu_volume(uint3(5u,3u,3u)) $(volume : uint64) {
        return device |> with_gpu_volume(uint3(3u,2u,2u)) $(copy : uint64) {
            var gpu_upload_volume_result <- device |> gpu_upload_volume(volume,0u,uint3(0u),uint3(5u,3u,3u),source,row_pitch,slice_pitch)
            if (is_err(gpu_upload_volume_result)) { return err(unwrap_err(gpu_upload_volume_result),type<SdlUnit>) }
            var gpu_copy_volume_result <- device |> gpu_copy_volume(volume,0u,uint3(1u,0u,1u),uint3(3u,2u,2u),copy,0u,uint3(0u))
            if (is_err(gpu_copy_volume_result)) { return err(unwrap_err(gpu_copy_volume_result),type<SdlUnit>) }
            return device |> with_gpu_volume_readback(copy,0u,uint3(0u),uint3(3u,2u,2u)) $(ticket : uint64) {
                var gpu_wait_readback_result <- device |> gpu_wait_readback(ticket)
                if (is_err(gpu_wait_readback_result)) { return err(unwrap_err(gpu_wait_readback_result),type<SdlUnit>) }
                var gpu_readback_bytes_result <- device |> gpu_readback_bytes(ticket,actual)
                if (is_err(gpu_readback_bytes_result)) { return err(unwrap_err(gpu_readback_bytes_result),type<SdlUnit>) }

                return sdl_ok()
            }
        }
    }
    if (is_err(gpu_volume_result)) { return err(unwrap_err(gpu_volume_result),type<SdlUnit>) }
    for (i in 0 .. length(actual)) { verify(actual[i] == expected[i]) }
    print("3D texture: padded 5x3x3 upload, 3x2x2 copy and 48-byte readback PASS ({SDL_GetGPUDeviceDriver(device)})\n")

    return sdl_ok()
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
