options gen2
require math
require dassdl3/sdl3_gpu_image_boost

def assert_pixels(device : SDL_GPUDevice?; texture : uint64; sub : uint2; rect : uint4;
        expected : array<uint8>; tolerance : int = 0) {
    var actual : array<uint8>
    resize(actual,length(expected))
    device |> with_gpu_texture_readback(texture,sub,rect) $(ticket) {
        device |> gpu_wait_readback(ticket)
        device |> gpu_readback_bytes(ticket,actual)
    }
    for (i in 0 .. length(actual)) {
        if (abs(int(actual[i])-int(expected[i])) > tolerance) {
            panic("Image byte {i}: expected {int(expected[i])}, got {int(actual[i])}")
        }
    }
}
def pattern(var bytes : array<uint8>; layer : int) {
    resize(bytes,64)
    for (y in 0 .. 4) { for (x in 0 .. 4) {
        let i = (y*4+x)*4
        bytes[i] = uint8(x*40+layer*20)
        bytes[i+1] = uint8(y*40+layer*20)
        bytes[i+2] = uint8(24+layer*16)
        bytes[i+3] = uint8(255)
    } }
}
def half_image(input : array<uint8>; width : int) : array<uint8> {
    let out_width = width/2
    var result : array<uint8>
    resize(result,out_width*out_width*4)
    for (y in 0 .. out_width) { for (x in 0 .. out_width) { for (c in 0 .. 4) {
        let i = (y*2*width+x*2)*4+c
        let sum = int(input[i])+int(input[i+4])+int(input[i+width*4])+int(input[i+width*4+4])
        result[(y*out_width+x)*4+c] = uint8((sum+2)/4)
    } } }
    return <- result
}
def check_image(device : SDL_GPUDevice?; format : uint) {
    var bytes, zero : array<uint8>
    resize(zero,64)
    device |> with_gpu_color_target_texture(4u,4u,2u,3u,format) $(image) {
        for (layer in 0u .. 2u) {
            assert_pixels(device,image,uint2(0u,layer),uint4(0u,0u,4u,4u),zero)
            pattern(bytes,int(layer))
            device |> gpu_upload_texture(image,uint2(0u,layer),uint4(0u,0u,4u,4u),bytes,16u)
        }
        device |> gpu_generate_mipmaps(image)
        for (layer in 0u .. 2u) {
            pattern(bytes,int(layer))
            let mip1 <- half_image(bytes,4)
            let mip2 <- half_image(mip1,2)
            assert_pixels(device,image,uint2(0u,layer),uint4(0u,0u,4u,4u),bytes)
            assert_pixels(device,image,uint2(1u,layer),uint4(0u,0u,2u,2u),mip1,1)
            assert_pixels(device,image,uint2(2u,layer),uint4(0u,0u,1u,1u),mip2,1)
        }
        // Regeneration after changing the base; old lower levels are overwritten.
        pattern(bytes,0)
        for (i in 0 .. 64) { bytes[i] = uint8(80) }
        device |> gpu_upload_texture(image,uint2(0u),uint4(0u,0u,4u,4u),bytes,16u)
        device |> gpu_generate_mipmaps(image)
        var tiny : array<uint8>
        resize(tiny,4)
        for (i in 0 .. 4) { tiny[i] = uint8(80) }
        assert_pixels(device,image,uint2(2u,0u),uint4(0u,0u,1u,1u),tiny,1)
    }
    // Odd dimensions: each allocated level keeps a spatially constant color.
    device |> with_gpu_color_target_texture(7u,5u,1u,3u,format) $(odd) {
        resize(bytes,140)
        for (i in 0 .. 140) { bytes[i] = uint8(48) }
        device |> gpu_upload_texture(odd,uint2(0u),uint4(0u,0u,7u,5u),bytes,28u)
        device |> gpu_generate_mipmaps(odd)
        resize(bytes,24)
        assert_pixels(device,odd,uint2(1u,0u),uint4(0u,0u,3u,2u),bytes,1)
        resize(bytes,4)
        assert_pixels(device,odd,uint2(2u,0u),uint4(0u,0u,1u,1u),bytes,1)
    }
    device |> with_gpu_color_texture(4u,4u,1u,1u,format) $(source) {
        pattern(bytes,0)
        device |> gpu_upload_texture(source,uint2(0u),uint4(0u,0u,4u,4u),bytes,16u)
        verify(!SDL_GenerateGPUTextureMipmapsChecked(device,source))
        device |> with_gpu_color_target_texture(6u,6u,2u,2u,format) $(target) {
            var expected : array<uint8>
            resize(expected,144)
            for (i in 0 .. 144) { expected[i] = uint8(17) }
            device |> gpu_upload_texture(target,uint2(0u,1u),uint4(0u,0u,6u,6u),expected,24u)
            device |> gpu_blit_texture(source,uint2(0u),uint4(1u,1u,2u,2u),target,uint2(0u,1u),uint4(1u,1u,4u,4u))
            for (y in 0 .. 4) { for (x in 0 .. 4) { for (c in 0 .. 4) {
                expected[((y+1)*6+x+1)*4+c] = bytes[((y/2+1)*4+x/2+1)*4+c]
            } } }
            assert_pixels(device,target,uint2(0u,1u),uint4(0u,0u,6u,6u),expected)
            var untouched : array<uint8>
            resize(untouched,144)
            assert_pixels(device,target,uint2(0u),uint4(0u,0u,6u,6u),untouched)
            // A separate linear downsample into mip 1; all source texels contribute.
            device |> gpu_blit_texture(source,uint2(0u),uint4(0u,0u,4u,4u),target,uint2(1u,0u),uint4(0u,0u,2u,2u),SDL_GPU_FILTER_LINEAR)
            let averaged <- half_image(bytes,4)
            assert_pixels(device,target,uint2(1u,0u),uint4(0u,0u,2u,2u),averaged,1)
            assert_pixels(device,source,uint2(0u),uint4(0u,0u,4u,4u),bytes)
            verify(!SDL_BlitGPUTextureChecked(device,target,uint2(0u),uint4(0u,0u,1u,1u),target,uint2(0u),uint4(1u,1u,1u,1u),0u))
            verify(!SDL_BlitGPUTextureChecked(device,source,uint2(0u),uint4(0u,0u,4u,4u),target,uint2(0u),uint4(0u,0u,7u,6u),0u))
            verify(!SDL_BlitGPUTextureChecked(device,source,uint2(0u),uint4(0u,0u,0u,4u),target,uint2(0u),uint4(0u,0u,2u,2u),0u))
            verify(!SDL_BlitGPUTextureChecked(device,source,uint2(9u),uint4(0u,0u,4u,4u),target,uint2(0u),uint4(0u,0u,2u,2u),0u))
            verify(!SDL_BlitGPUTextureChecked(device,source,uint2(0u),uint4(0u,0u,4u,4u),target,uint2(0u),uint4(0u,0u,2u,2u),2u))
            verify(!SDL_BlitGPUTextureChecked(device,target,uint2(0u),uint4(0u,0u,4u,4u),source,uint2(0u),uint4(0u,0u,4u,4u),0u))
            with_gpu_device() $(other) {
                verify(!SDL_GenerateGPUTextureMipmapsChecked(other,target))
                verify(!SDL_BlitGPUTextureChecked(other,source,uint2(0u),uint4(0u,0u,4u,4u),target,uint2(0u),uint4(0u,0u,2u,2u),0u))
            }
            assert_pixels(device,target,uint2(0u,1u),uint4(0u,0u,6u,6u),expected)
        }
    }
}
[export]
def main(smoke : bool) : int {
    var available = false
    with_sdl() {
        available = try_with_gpu_device(GPU_CLEAR_FORMATS,true,"") $(device) {
            verify(SDL_CreateGPUColorTargetTexture(device,4u,4u,1u,1u,SDL_GPU_TEXTUREFORMAT_R32_FLOAT) == 0ul)
            verify(SDL_CreateGPUColorTargetTexture(device,0u,4u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) == 0ul)
            verify(!SDL_GenerateGPUTextureMipmapsChecked(device,0ul))
            check_image(device,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM)
            check_image(device,SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM)
            device |> with_gpu_color_texture(4u,4u,1u,3u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(sampler_only) {
                verify(!SDL_GenerateGPUTextureMipmapsChecked(device,sampler_only))
            }
            device |> with_gpu_transfer_texture(2u,2u,6u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM,SDL_GPU_TEXTURETYPE_CUBE) $(cube) {
                var face : array<uint8>
                resize(face,16)
                for (i in 0 .. 16) { face[i] = uint8(104) }
                device |> gpu_upload_texture(cube,uint2(0u,5u),uint4(0u,0u,2u,2u),face,8u)
                device |> with_gpu_color_target_texture(2u,2u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(target) {
                    device |> gpu_blit_texture(cube,uint2(0u,5u),uint4(0u,0u,2u,2u),target,uint2(0u),uint4(0u,0u,2u,2u))
                    assert_pixels(device,target,uint2(0u),uint4(0u,0u,2u,2u),face)
                }
            }
            device |> with_gpu_rgba_texture(2u,2u) $(source) {
                device |> with_gpu_color_target_texture(2u,2u,1u,1u,SDL_GPU_TEXTUREFORMAT_B8G8R8A8_UNORM) $(target) {
                    verify(!SDL_BlitGPUTextureChecked(device,source,uint2(0u),uint4(0u,0u,2u,2u),target,uint2(0u),uint4(0u,0u,2u,2u),0u))
                }
            }
            // Public ticket owns the generated snapshot after texture destruction.
            var ticket = 0ul
            device |> with_gpu_color_target_texture(2u,2u,1u,2u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(image) {
                var data : array<uint8>
                resize(data,16)
                for (i in 0 .. 16) { data[i] = uint8(72) }
                device |> gpu_upload_texture(image,uint2(0u),uint4(0u,0u,2u,2u),data,8u)
                device |> gpu_generate_mipmaps(image)
                ticket = SDL_RequestGPUTextureReadback(device,image,uint2(1u,0u),uint4(0u,0u,1u,1u))
                verify(ticket != 0ul)
            }
            var snapshot : array<uint8>
            resize(snapshot,4)
            device |> gpu_wait_readback(ticket)
            device |> gpu_readback_bytes(ticket,snapshot)
            for (byte in snapshot) { verify(byte == uint8(72)) }
            verify(SDL_ReleaseGPUReadback(device,ticket))
            var stale = 0ul
            var caught = false
            try {
                device |> with_gpu_color_target_texture(2u,2u,1u,1u,SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM) $(id) {
                    stale = id
                    verify(!SDL_GenerateGPUTextureMipmapsChecked(device,id))
                    panic("image cleanup")
                }
            } recover { caught = true }
            verify(caught)
            verify(!SDL_GenerateGPUTextureMipmapsChecked(device,stale))
            verify(!SDL_ReleaseGPUTransferTexture(device,stale))
            print("GPU image CPU pixel references, mips, blits, bounds and lifetime PASS: {SDL_GetGPUDeviceDriver(device)}\n")
        }
    }
    return available ? 0 : 77
}
