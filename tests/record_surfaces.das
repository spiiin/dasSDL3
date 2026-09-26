options gen2
require dassdl3/sdl3_record_access
require dassdl3/sdl3_try
require daslib/defer

def plane(format : SDL_PixelFormat; w, h, pitch, index : int; expected : int4; offset : int) {
    let s = SDLTestRecordSurface(format, w, h, pitch)
    verify(s != null)
    defer() {SDL_DestroySurface(s)}
    let info = surface_info(s) |> sdl_try
    verify(info.width == w && info.height == h && info.pitch == pitch && info.format == format)
    let layout = surface_plane_info(s, index) |> sdl_try
    verify(layout == expected)
    with_surface_bytes(s, index) $(var bytes : array<uint8>#; shape : int4) {
        verify(SDLTestRecordLocked(s) && shape == expected)
        let count = (shape.y - 1) * shape.z + shape.x
        verify(length(bytes) == count)
        bytes[0] = uint8(11); bytes[count - 1] = uint8(22)
        return sdl_ok()
    } |> sdl_try
    let count = (expected.y - 1) * expected.z + expected.x
    verify(!SDLTestRecordLocked(s))
    verify(SDLTestRecordByte(offset) == 11 && SDLTestRecordByte(offset + count - 1) == 22)
    if (offset > 0) {verify(SDLTestRecordByte(offset - 1) == 165)}
    verify(SDLTestRecordByte(offset + count) == 165)
    let failed = with_surface_bytes(s, index) $(var bytes : array<uint8>#; shape : int4) {
        return err(SdlError(operation = "body", message = "preserved"), type<SdlUnit>)
    }
    verify(is_err(failed) && unwrap_err(failed).operation == "body" && !SDLTestRecordLocked(s))
    var called = false
    let invalid = with_surface_bytes(s, 99) $(var bytes : array<uint8>#; shape : int4) {called = true; return sdl_ok()}
    verify(is_err(invalid) && !called && !SDLTestRecordLocked(s))
    return sdl_ok()
}
def run() {
    verify(is_err(surface_info(null)) && is_err(palette_colors(null)) && is_err(surface_plane_info(null)))
    plane(SDL_PixelFormat.PIXELFORMAT_RGB24, 3, 2, 12, 0, int4(9, 2, 12, 1), 0) |> sdl_try
    plane(SDL_PixelFormat.PIXELFORMAT_INDEX1LSB, 9, 2, 4, 0, int4(2, 2, 4, 1), 0) |> sdl_try
    plane(SDL_PixelFormat.PIXELFORMAT_INDEX4MSB, 3, 2, 4, 0, int4(2, 2, 4, 1), 0) |> sdl_try
    plane(SDL_PixelFormat.PIXELFORMAT_RGBA128_FLOAT, 2, 2, 36, 0, int4(32, 2, 36, 1), 0) |> sdl_try
    for (fmt in fixed_array(SDL_PixelFormat.PIXELFORMAT_IYUV, SDL_PixelFormat.PIXELFORMAT_YV12)) {
        plane(fmt, 3, 3, 5, 0, int4(3, 3, 5, 3), 0) |> sdl_try
        plane(fmt, 3, 3, 5, 1, int4(2, 2, 3, 3), 15) |> sdl_try
        plane(fmt, 3, 3, 5, 2, int4(2, 2, 3, 3), 21) |> sdl_try
    }
    for (fmt in fixed_array(SDL_PixelFormat.PIXELFORMAT_NV12, SDL_PixelFormat.PIXELFORMAT_NV21)) {
        plane(fmt, 3, 3, 5, 0, int4(3, 3, 5, 2), 0) |> sdl_try
        plane(fmt, 3, 3, 5, 1, int4(4, 2, 6, 2), 15) |> sdl_try
    }
    for (fmt in fixed_array(SDL_PixelFormat.PIXELFORMAT_YUY2, SDL_PixelFormat.PIXELFORMAT_UYVY, SDL_PixelFormat.PIXELFORMAT_YVYU)) {
        plane(fmt, 3, 2, 12, 0, int4(8, 2, 12, 1), 0) |> sdl_try
    }
    plane(SDL_PixelFormat.PIXELFORMAT_MJPG, 3, 2, 7, 0, int4(7, 1, 7, 1), 0) |> sdl_try
    plane(SDL_PixelFormat.PIXELFORMAT_P010, 3, 3, 8, 0, int4(6, 3, 8, 2), 0) |> sdl_try
    plane(SDL_PixelFormat.PIXELFORMAT_P010, 3, 3, 8, 1, int4(8, 2, 8, 2), 24) |> sdl_try
    let zero = SDL_CreateSurface(0, 0, SDL_PixelFormat.PIXELFORMAT_RGBA32); verify(zero != null)
    with_surface_bytes(zero, 0) $(var bytes : array<uint8>#; shape : int4) {
        verify(length(bytes) == 0 && shape.x == 0 && shape.y == 0); return sdl_ok()
    } |> sdl_try
    verify(!SDLTestRecordLocked(zero)); SDL_DestroySurface(zero)
    var entered = false
    let null_view = with_surface_bytes(null, 0) $(var bytes : array<uint8>#; shape : int4) {entered = true; return sdl_ok()}
    verify(is_err(null_view) && !entered)
    let palette = SDL_CreatePalette(2); verify(palette != null)
    var colors <- array<SDL_Color>(SDL_Color(r = 12u, g = 34u, b = 56u, a = 255u), SDL_Color(r = 90u, a = 255u))
    verify(SDL_SetPaletteColorsArray(palette, colors, 0))
    var copy <- palette_colors(palette) |> sdl_try
    SDL_DestroyPalette(palette)
    verify(length(copy) == 2 && uint(copy[0].r) == 12u && uint(copy[1].r) == 90u)
    return sdl_ok()
}
[export]
def main(smoke : bool) : int {
    let result = run()
    if (is_err(result)) {let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1}
    print("Surface metadata, copied palette and packed/planar/compressed byte views passed\n")
    return 0
}
