options gen2
require dassdl3/sdl3_camera_boost
require dassdl3/sdl3_pixels_boost
require dassdl3/sdl3_try

var camera : SDL_Camera?
var previous_timestamp : uint64
var frame_count : int

def select_camera() : uint {
    var found <- cameras()
    if (is_err(found)) {
        print("SDL_GetCameras: {unwrap_err(found).message}\n")
        return 0u
    }
    let ids <- move_unwrap(found)
    if (empty(ids)) { return 0u }
    return ids[0]
}

[export]
def camera_open(expect_denied : bool) : int {
    let driver = SDL_GetPlatform() == "Android" ? "android" : "coremedia"
    if (SDL_GetCurrentCameraDriverCopy() != driver) { return -1 }
    let id = select_camera()
    if (id == 0u) {
        print("SDL found no camera to test.\n")
        return -1
    }
    var opened <- open_camera(id)
    if (is_err(opened)) {
        print("SDL_OpenCamera: {unwrap_err(opened).message}\n")
        return expect_denied ? 1 : -1
    }
    camera = move_unwrap(opened)
    let name = SDL_GetCameraName(id)
    print("Opened camera: {name}\n")
    return 0
}

[export]
def camera_tick(expect_denied : bool) : int {
    let permission = camera_permission_state(camera)
    if (permission == SDL_CameraPermissionState.PENDING) { return 0 }
    if (permission == SDL_CameraPermissionState.DENIED) {
        print("SDL reported camera permission denied.\n")
        return expect_denied ? 1 : -1
    }
    if (expect_denied) { return -1 }
    var result <- camera |> with_camera_frame() $(frame) {
        let size = surface_size(frame.surface) |> sdl_try
        if (size.x <= 0 || size.y <= 0 || frame.timestamp_ns <= previous_timestamp) {
            return err(SdlError(operation = "Camera frame", message = "Invalid dimensions or timestamp"), type<SdlUnit>)
        }
        previous_timestamp = frame.timestamp_ns
        frame_count++
        print("Camera frame {frame_count}: {size.x}x{size.y}, timestamp {frame.timestamp_ns}\n")
        return sdl_ok()
    }
    if (is_err(result)) {
        print("{unwrap_err(result).message}\n")
        return -1
    }
    return frame_count >= 3 ? 1 : 0
}

[export]
def camera_close() {
    if (camera != null) { close_camera(camera) }
}
