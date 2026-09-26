options gen2
require dassdl3/sdl3_gpu_formats_boost

[export]
def main(smoke : bool) : int {
    verify(SDLTest_astc_footprints())
    let nonsquare = unwrap_or(gpu_format_block_extent(SDL_GPU_TEXTUREFORMAT_ASTC_5x4_UNORM), uint2(0u))
    verify(nonsquare.x == 5u && nonsquare.y == 4u)
    let wide = unwrap_or(gpu_format_block_extent(SDL_GPU_TEXTUREFORMAT_ASTC_12x10_FLOAT), uint2(0u))
    verify(wide.x == 12u && wide.y == 10u)
    for (format in SDL_GPU_TEXTUREFORMAT_ASTC_4x4_UNORM .. SDL_GPU_TEXTUREFORMAT_ASTC_12x12_FLOAT + 1u) {
        let extent = unwrap_or(gpu_format_block_extent(format), uint2(0u))
        verify(unwrap_or(gpu_format_block_bytes(format), 0u) == 16u)
        verify(unwrap_or(gpu_format_bytes(format, extent.x, extent.y, 1u), 0u) == 16u)
        verify(unwrap_or(gpu_format_bytes(format, extent.x + 1u, extent.y + 1u, 2u), 0u) == 128u)
        verify(unwrap_or(gpu_format_bytes(format, 1u, 1u, 1u), 0u) == 16u)
    }
    verify(unwrap_or(gpu_format_block_extent(SDL_GPU_TEXTUREFORMAT_BC1_RGBA_UNORM), uint2(0u)).x == 4u)
    verify(unwrap_or(gpu_format_block_extent(SDL_GPU_TEXTUREFORMAT_R8G8B8A8_UNORM), uint2(0u)).y == 1u)
    verify(SDL_GPUFormatBlockExtentChecked(0u).x == 0u)
    verify(SDL_GPUFormatBlockExtentChecked(0xffffffffu).x == 0u)
    print("ASTC 42-format CPU footprints, rectangular regions and mip edges PASS\n")
    return 0
}
