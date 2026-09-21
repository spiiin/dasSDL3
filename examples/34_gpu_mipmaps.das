options gen2
require dassdl3/sdl3_scope
require math
require dassdl3/sdl3_gpu_image_boost

def run_gpu_example(device : SDL_GPUDevice?; smoke : bool) : $Result<SdlUnit; SdlError> {
    var base, tiny : array<uint8>
    resize(base,64); resize(tiny,4)
    for (y in 0 .. 4) { for (x in 0 .. 4) {
        let i = (y*4+x)*4
        base[i] = uint8(x*40); base[i+1] = uint8(y*40)
        base[i+2] = uint8(24); base[i+3] = uint8(255)
    } }
    return sdl_scope() {
        let texture : GpuTextureHandle = device |> with_gpu_color_target_texture(4u,4u,1u,3u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) |> sdl_use
        device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,4u,4u),base,16u) |> sdl_try
        device |> gpu_generate_mipmaps(texture) |> sdl_try
        sdl_scope() {
            let ticket : GpuReadbackHandle = device |> with_gpu_texture_readback(texture,uint2(2u,0u),uint4(0u,0u,1u,1u)) |> sdl_use
            device |> gpu_wait_readback(ticket) |> sdl_try
            device |> gpu_readback_bytes(ticket,tiny) |> sdl_try
            verify(abs(int(tiny[0])-60) <= 1 && abs(int(tiny[1])-60) <= 1)
            verify(tiny[2] == uint8(24) && tiny[3] == uint8(255))

            return sdl_ok()
        } |> sdl_try
        print("Mip chain 4x4 -> 2x2 -> 1x1 matches the CPU average\n")

        return sdl_ok()
    }
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
