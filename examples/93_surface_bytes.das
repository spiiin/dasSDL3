options gen2
require dassdl3/sdl3_record_access
require dassdl3/sdl3_try
require daslib/defer

def run() {
    let surface = SDL_CreateSurface(32, 32, SDL_PixelFormat.PIXELFORMAT_RGB24)
    if (surface == null) {return err(sdl_error("SDL_CreateSurface"), type<SdlUnit>)}
    defer() {SDL_DestroySurface(surface)}
    let info = surface_info(surface) |> sdl_try
    with_surface_bytes(surface, 0) $(var bytes : array<uint8>#; layout : int4) {
        for (y in 0 .. layout.y) {
            for (x in 0 .. info.width) {
                let offset = y * layout.z + x * 3
                bytes[offset] = uint8(x * 8); bytes[offset + 1] = uint8(y * 8); bytes[offset + 2] = uint8(180)
            }
        }
        return sdl_ok()
    } |> sdl_try
    print("RGB24 surface: {info.width} x {info.height}, pitch={info.pitch}; automatically unlocked\n")
    return sdl_ok()
}
[export]
def main(smoke : bool) : int {
    let result = run()
    if (is_err(result)) {let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1}
    return 0
}
