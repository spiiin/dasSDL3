options gen2
require dassdl3/sdl3_camera_boost
require dassdl3/sdl3_scope

// A normal run opens the first camera. Smoke mode only enumerates dummy devices.
// Keep every borrowed surface inside this block. Copy it if it must outlive release.
def read_one_frame(camera : SDL_Camera?) : $Result<SdlUnit; SdlError> {
    let deadline=SDL_GetTicks()+5000ul
    while(SDL_GetTicks()<deadline) {
        SDL_PumpEvents()
        let permission=camera |> camera_permission_state()
        if(permission==SDL_CameraPermissionState.PENDING) {SDL_Delay(10u);continue}
        if(permission==SDL_CameraPermissionState.DENIED) {
            return err(SdlError(operation="camera_permission_state",message="Camera access denied"),type<SdlUnit>)
        }
        var available <- camera |> with_camera_frame() $(frame) {
            let spec=camera |> camera_format() |> sdl_try
            print("Frame {spec.width}x{spec.height}, timestamp {frame.timestamp_ns} ns.\n")
            return sdl_ok()
        }
        if(is_err(available)) {return err(unwrap_err(available),type<SdlUnit>)}
        var value <- move_unwrap(available)
        if(is_some(value)) {return sdl_ok()}
        SDL_Delay(10u)
    }
    print("No frame within five seconds; permission may still be pending.\n")
    return sdl_ok()
}
def example(smoke : bool) : $Result<SdlUnit; SdlError> {
    return sdl_scope() {
        with_sdl(SDL_INIT_CAMERA) |> sdl_use
        let ids <- cameras() |> sdl_try
        print("Found {length(ids)} camera(s).\n")
        for(id in ids) {
            let name=camera_name(id) |> sdl_try
            let formats <- camera_supported_formats(id) |> sdl_try
            print("{id}: {name}, {length(formats)} native formats.\n")
        }
        if(smoke || length(ids)==0) {return sdl_ok()}
        let camera : SDL_Camera? = with_camera(ids[0]) |> sdl_use
        return read_one_frame(camera)
    }
}
[export]
def main(smoke : bool) : int {
    let result=example(smoke)
    if(is_err(result)) {let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    return 0
}
