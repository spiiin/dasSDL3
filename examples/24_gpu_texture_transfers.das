options gen2
require dassdl3/sdl3_gpu_texture_transfer_boost

var example_failed = false

[export]
def main(smoke : bool) : int {
    var available = false
    let scope_ok_0 = with_sdl() {
        available = try_with_gpu_device(GPU_SHADER_FORMATS,true,"") $(device) {
            // 5x3 RGBA image, with 7 unused bytes after each source row.
            var pixels, result : array<uint8>
            resize(pixels,74) // 2*27 + 5*4; no final-row padding required.
            resize(result,60)
            for (pixel_byte in 0 .. 60) { let y = pixel_byte / 20; let x = pixel_byte % 20; pixels[y*27+x] = uint8((y*71+x*13)%256) }
            let scope_ok_1 = device |> with_gpu_rgba_texture(9u,7u) $(source) {
                if (!(device |> gpu_upload_texture(source,uint2(0u),uint4(2u,1u,5u,3u),pixels,27u))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                let scope_ok_2 = device |> with_gpu_rgba_texture(10u,8u,2u,2u) $(destination) {
                    // Copy the rectangle into mip 1, layer 1 of an array texture.
                    if (!(device |> gpu_copy_texture(source,uint2(0u),uint4(2u,1u,5u,3u),destination,uint2(1u,1u),uint2(0u)))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                    let scope_ok_3 = device |> with_gpu_texture_readback(destination,uint2(1u,1u),uint4(0u,0u,5u,3u)) $(ticket) {
                        if (!(device |> gpu_wait_readback(ticket))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        if (!(device |> gpu_readback_bytes(ticket,result))) { example_failed = true; print("SDL operation: {SDL_GetError()}\n"); return }
                        for (pixel_byte in 0 .. 60) { let y = pixel_byte / 20; let x = pixel_byte % 20; verify(result[y*20+x] == pixels[y*27+x]) }
                        print("GPU texture upload/copy/readback: 5x3 RGBA pixels match, mip 1 / layer 1 ({SDL_GetGPUDeviceDriver(device)})\n")
                    }
                    if (!scope_ok_3) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
                }
                if (!scope_ok_2) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
            }
            if (!scope_ok_1) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
        }
    }
    if (!scope_ok_0) { example_failed = true; print("SDL acquisition: {SDL_GetError()}\n") }
    return example_failed ? 1 : (available ? 0 : 77)
}
