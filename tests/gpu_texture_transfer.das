options gen2
require dassdl3/sdl3_gpu_texture_transfer_boost
require daslib/rtti
require daslib/strings_boost

def check(ok : bool) { if (!ok) { panic("GPU texture transfer test: {SDL_GetError()}") } }
def equal(a,b : array<uint8>) {
    verify(length(a) == length(b))
    for (i in 0 .. length(a)) { verify(a[i] == b[i]) }
}
def pixels(device : SDL_GPUDevice?; texture : uint64; sub : uint2; width,height : uint; expected : array<uint8>) {
    var actual : array<uint8>
    resize(actual,int(width*height*4u))
    device |> with_gpu_texture_readback(texture,sub,uint4(0u,0u,width,height)) $(ticket) {
        device |> gpu_wait_readback(ticket)
        device |> gpu_readback_bytes(ticket,actual)
        equal(actual,expected)
    }
}
def zeros(device : SDL_GPUDevice?; texture : uint64; sub : uint2; width,height : uint) {
    var expected : array<uint8>
    resize(expected,int(width*height*4u))
    for (i in 0 .. length(expected)) { expected[i] = uint8(0) }
    pixels(device,texture,sub,width,height,expected)
}
[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            verify(SDL_CreateGPUTransferTexture(device,0u,1u,1u,1u) == 0ul)
            verify(SDL_CreateGPUTransferTexture(device,8193u,1u,1u,1u) == 0ul)
            verify(SDL_CreateGPUTransferTexture(device,1u,1u,0u,1u) == 0ul)
            verify(SDL_CreateGPUTransferTexture(device,1u,1u,257u,1u) == 0ul)
            verify(SDL_CreateGPUTransferTexture(device,7u,5u,1u,4u) == 0ul)
            verify(SDL_CreateGPUTransferTexture(device,8192u,8192u,1u,1u) == 0ul)
            verify(SDL_CreateGPUTransferTexture(device,1024u,1024u,17u,1u) == 0ul)
            var packed, padded : array<uint8>
            resize(packed,140)
            resize(padded,152) // odd byte pitch, minimal final row.
            for (pixel_byte in 0 .. 140) { let y = pixel_byte / 28; let x = pixel_byte % 28;
                packed[y*28+x] = uint8((y*47+x*7+5)%256)
                padded[y*31+x] = packed[y*28+x]
            }
            var stale = 0ul
            device |> with_gpu_rgba_texture(7u,5u,2u,3u) $(source) {
                stale = source
                for (layer in 0u .. 2u) {
                    zeros(device,source,uint2(0u,layer),7u,5u)
                    zeros(device,source,uint2(1u,layer),3u,2u)
                    zeros(device,source,uint2(2u,layer),1u,1u)
                }
                verify(!SDL_UploadGPUTextureRegion(device,source,uint2(0u),uint4(0u,0u,7u,5u),padded,27u,false))
                verify(!SDL_UploadGPUTextureRegion(device,source,uint2(0u),uint4(0u,0u,7u,5u),padded,32u,false))
                verify(!SDL_UploadGPUTextureRegion(device,source,uint2(0u),uint4(0u,0u,7u,5u),padded,31u,true))
                verify(SDL_RequestGPUTextureReadback(device,source,uint2(3u,0u),uint4(0u,0u,1u,1u)) == 0ul)
                verify(SDL_RequestGPUTextureReadback(device,source,uint2(0u,2u),uint4(0u,0u,1u,1u)) == 0ul)
                verify(SDL_RequestGPUTextureReadback(device,source,uint2(0u),uint4(0xffffffffu,0u,1u,1u)) == 0ul)
                verify(SDL_RequestGPUTextureReadback(device,source,uint2(0u),uint4(6u,4u,2u,2u)) == 0ul)
                verify(SDL_RequestGPUTextureReadback(device,source,uint2(0u),uint4(0u)) == 0ul)
                verify(!SDL_CopyGPUTextureRegion(device,source,uint2(0u),uint4(0u,0u,1u,1u),source,uint2(0u),uint2(1u)))
                device |> gpu_upload_texture(source,uint2(0u),uint4(0u,0u,7u,5u),padded,31u)
                clear(padded) // The upload must own a copy already.
                pixels(device,source,uint2(0u),7u,5u,packed)
                zeros(device,source,uint2(0u,1u),7u,5u)
                zeros(device,source,uint2(1u,0u),3u,2u)
                var tiny : array<uint8>
                resize(tiny,4)
                tiny[0] = uint8(19); tiny[1] = uint8(28); tiny[2] = uint8(73); tiny[3] = uint8(11)
                device |> gpu_upload_texture(source,uint2(2u,1u),uint4(0u,0u,1u,1u),tiny,4u)
                pixels(device,source,uint2(2u,1u),1u,1u,tiny)
                // Partial upload must preserve every other pixel, mip and layer.
                device |> gpu_upload_texture(source,uint2(0u),uint4(4u,3u,1u,1u),tiny,4u)
                for (c in 0 .. 4) { packed[100+c] = tiny[c] }
                pixels(device,source,uint2(0u),7u,5u,packed)
                pixels(device,source,uint2(2u,1u),1u,1u,tiny)
                zeros(device,source,uint2(0u,1u),7u,5u)
                device |> with_gpu_rgba_texture(8u,6u,2u,3u) $(destination) {
                    verify(!SDL_CopyGPUTextureRegion(device,source,uint2(0u),uint4(2u,1u,3u,2u),destination,uint2(1u,1u),uint2(3u,1u)))
                    device |> gpu_copy_texture(source,uint2(0u),uint4(2u,1u,3u,2u),destination,uint2(1u,1u),uint2(1u,1u))
                    var expected : array<uint8>
                    resize(expected,48)
                    for (i in 0 .. 48) { expected[i] = uint8(0) }
                    for (pixel_byte in 0 .. 24) { let y = pixel_byte / 12; let x = pixel_byte % 12; expected[(y+1)*16+4+x] = packed[(y+1)*28+8+x] }
                    pixels(device,destination,uint2(1u,1u),4u,3u,expected)
                    zeros(device,destination,uint2(0u,1u),8u,6u)
                    zeros(device,destination,uint2(1u,0u),4u,3u)
                    let other_available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(other) {
                        verify(!SDL_ReleaseGPUTransferTexture(other,source))
                        verify(SDL_RequestGPUTextureReadback(other,source,uint2(0u),uint4(0u,0u,1u,1u)) == 0ul)
                        let own = SDL_CreateGPUTransferTexture(other,3u,2u,2u,2u)
                        verify(own != 0ul)
                        verify(!SDL_CopyGPUTextureRegion(device,source,uint2(0u),uint4(0u,0u,1u,1u),own,uint2(0u),uint2(0u)))
                        verify(SDL_RequestGPUTextureReadback(other,own,uint2(0u),uint4(0u,0u,3u,2u)) != 0ul)
                        // Deliberately leave texture/ticket for device-specific cleanup.
                    }
                    verify(other_available)
                    pixels(device,destination,uint2(1u,1u),4u,3u,expected)
                }
            }
            verify(!SDL_ReleaseGPUTransferTexture(device,stale))
            // Queued snapshot, cycling and release of source before reading.
            let texture = SDL_CreateGPUTransferTexture(device,7u,5u,1u,1u)
            verify(texture != 0ul)
            device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,7u,5u),packed,28u,true)
            var dead_ticket = 0ul
            device |> with_gpu_texture_readback(texture,uint2(0u),uint4(0u,0u,7u,5u)) $(ticket) {
                dead_ticket = ticket
                var zero, actual : array<uint8>
                resize(zero,140); resize(actual,140)
                for (i in 0 .. 140) { zero[i] = uint8(0) }
                verify(!SDL_ReleaseGPUTransferTexture(device,ticket))
                verify(SDL_RequestGPUBufferReadback(device,texture,0u,4u) == 0ul)
                device |> gpu_upload_texture(texture,uint2(0u),uint4(0u,0u,7u,5u),zero,28u,true)
                check(SDL_ReleaseGPUTransferTexture(device,texture))
                device |> gpu_wait_readback(ticket)
                verify(!SDL_ReadGPUReadback(device,ticket,padded))
                device |> gpu_readback_bytes(ticket,actual)
                equal(actual,packed)
            }
            verify(SDL_PollGPUReadback(device,dead_ticket) == -1)
            var caught = false
            try {
                device |> with_gpu_rgba_texture(1u,1u) $(owned) {
                    stale = owned
                    device |> with_gpu_texture_readback(owned,uint2(0u),uint4(0u,0u,1u,1u)) $(ticket) {
                        dead_ticket = ticket
                        panic("texture transfer scope sentinel")
                    }
                }
            } recover { caught = rtrim(this_context().last_exception) == "texture transfer scope sentinel" }
            verify(caught && !SDL_ReleaseGPUTransferTexture(device,stale))
            verify(SDL_PollGPUReadback(device,dead_ticket) == -1)
            device |> with_gpu_rgba_texture(1u,1u) $(owned) { stale = owned; return }
            verify(!SDL_ReleaseGPUTransferTexture(device,stale))
            device |> with_gpu_rgba_texture(3u,2u) $(owned) {
                for (i in 0 .. 64) {
                    device |> with_gpu_texture_readback(owned,uint2(0u),uint4(0u,0u,3u,2u)) $(ticket) { dead_ticket = ticket; return }
                    verify(SDL_PollGPUReadback(device,dead_ticket) == -1)
                }
                zeros(device,owned,uint2(0u),3u,2u)
            }
            print("GPU texture mip/layer, pitch, copy, snapshots, bounds and scopes PASS: {SDL_GetGPUDeviceDriver(device)}\n")
        }
    }
    return available ? 0 : 77
}
