options gen2
require dassdl3/sdl3_scope
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
    sdl_scope() {
        let volume : GpuVolumeHandle = device |> with_gpu_volume(uint3(5u,3u,3u)) |> sdl_use
        let copy : GpuVolumeHandle = device |> with_gpu_volume(uint3(3u,2u,2u)) |> sdl_use
        device |> gpu_upload_volume(volume,0u,uint3(0u),uint3(5u,3u,3u),source,row_pitch,slice_pitch) |> sdl_try
        device |> gpu_copy_volume(volume,0u,uint3(1u,0u,1u),uint3(3u,2u,2u),copy,0u,uint3(0u)) |> sdl_try
        let ticket : GpuReadbackHandle = device |> with_gpu_volume_readback(copy,0u,uint3(0u),uint3(3u,2u,2u)) |> sdl_use
        device |> gpu_wait_readback(ticket) |> sdl_try
        device |> gpu_readback_bytes(ticket,actual) |> sdl_try

        return sdl_ok()
    } |> sdl_try
    for (i in 0 .. length(actual)) { verify(actual[i] == expected[i]) }
    print("3D texture: padded 5x3x3 upload, 3x2x2 copy and 48-byte readback PASS ({SDL_GetGPUDeviceDriver(device)})\n")

    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        let device : SDL_GPUDevice? = with_gpu_device(GPU_SHADER_FORMATS,true,"") |> sdl_use
        return run_gpu_example(device, smoke)
    }
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return smoke && error.operation=="with_gpu_device" ? 77 : 1
    }
    return 0
}
