options gen2
require dassdl3/sdl3_gpu_formats_boost

[export]
def main(smoke : bool) : int {
    verify(SDLTest_astc_footprints())
    let nonsquare = gpu_format_block_extent(SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM)
    verify(nonsquare.x == 5u && nonsquare.y == 4u)
    let wide = gpu_format_block_extent(SDL_GPU_TEXTUREFORMAT_ASTC_12x10_FLOAT)
    verify(wide.x == 12u && wide.y == 10u)
    for (format in SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM .. SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT+1u) {
        let extent = gpu_format_block_extent(format)
        verify(gpu_format_block_bytes(format) == 16u)
        verify(gpu_format_bytes(format,extent.x,extent.y,1u) == 16u)
        verify(gpu_format_bytes(format,extent.x+1u,extent.y+1u,2u) == 128u)
        verify(gpu_format_bytes(format,1u,1u,1u) == 16u)
    }
    verify(gpu_format_block_extent(SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM).x == 4u)
    verify(gpu_format_block_extent(SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM).y == 1u)
    verify(SDL_GPUFormatBlockExtentChecked(0u).x == 0u)
    verify(SDL_GPUFormatBlockExtentChecked(0xffffffffu).x == 0u)
    print("ASTC 42-format CPU footprints, rectangular regions and mip edges PASS\n")
    return 0
}
