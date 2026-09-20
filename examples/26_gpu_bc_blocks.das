options gen2
require dassdl3/sdl3_gpu_utilities_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    let format = SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM
    var blocks, result : array<uint8>
    resize(blocks,32); resize(result,32)
    for (i in 0 .. 32) { blocks[i] = uint8(i*7) }
    let gpu_transfer_texture_result = device |> with_gpu_transfer_texture(8u,8u,1u,1u,format,SDL_GPU_TEXTURETYPE_2D) $(texture : uint64) {
        var gpu_upload_texture_result <- device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,8u,8u),blocks,16u)
        if (is_err(gpu_upload_texture_result)) { return gpu_upload_texture_result }
        return device |> with_gpu_texture_readback(texture,uint2(0u),uint4(0u,0u,8u,8u)) $(ticket : uint64) {
            var gpu_wait_readback_result <- device |> gpu_wait_readback(ticket)
            if (is_err(gpu_wait_readback_result)) { return gpu_wait_readback_result }
            var gpu_readback_bytes_result <- device |> gpu_readback_bytes(ticket,result)
            if (is_err(gpu_readback_bytes_result)) { return gpu_readback_bytes_result }
            for (i in 0 .. 32) { verify(blocks[i] == result[i]) }

            return sdl_ok()
        }
    }
    if (is_err(gpu_transfer_texture_result)) { return gpu_transfer_texture_result }
    print("BC1: four encoded blocks copied exactly; no CPU compression\n")

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
