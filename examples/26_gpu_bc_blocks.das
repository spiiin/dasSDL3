options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_gpu_utilities_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : SdlStatus {
    let format = SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM
    var blocks, result : array<uint8>
    resize(blocks,32); resize(result,32)
    for (i in 0 .. 32) { blocks[i] = uint8(i*7) }
    sdl_scope() {
        let texture : GpuTextureHandle = device |> with_gpu_transfer_texture(8u,8u,1u,1u,format,SDL_GPU_TEXTURETYPE_2D) |> sdl_use
        device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,8u,8u),blocks,16u) |> sdl_try
        let ticket : GpuReadbackHandle = device |> with_gpu_texture_readback(texture,uint2(0u),uint4(0u,0u,8u,8u)) |> sdl_use
        device |> gpu_wait_readback(ticket) |> sdl_try
        device |> gpu_readback_bytes(ticket,result) |> sdl_try
        for (i in 0 .. 32) { verify(blocks[i] == result[i]) }

        return sdl_ok()
    } |> sdl_try
    print("BC1: four encoded blocks copied exactly; no CPU compression\n")

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
