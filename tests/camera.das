options gen2
require dassdl3/sdl3_camera_boost
require dassdl3/sdl3_scope
require daslib/safe_addr

[export]
def main(smoke : bool) : int {
    verify(SDL_GetNumCameraDrivers() > 0)
    verify(length(SDL_GetCameraDriver(0)) > 0)
    verify(is_some(camera_driver(0)))
    verify(is_none(camera_driver(-1)) && is_none(camera_driver(SDL_GetNumCameraDrivers())))
    verify(is_none(current_camera_driver()))
    verify(is_err(cameras()))
    var saved : SdlError
    let result = with_sdl(SDL_INIT_CAMERA) {
        verify(SDL_GetCurrentCameraDriver() == "dummy")
        verify(unwrap(current_camera_driver()) == "dummy")
        var count = 99
        unsafe {
            let ids = SDL_GetCameras(addr(count))
            verify(ids != null && count == 0)
            SDL_free(ids)
            let specs = SDL_GetCameraSupportedFormats(0u, addr(count))
            verify(specs == null && count == 0)
            SDL_free(specs)
        }
        SDL_SetErrorText("stale error must not turn an empty list into failure")
        var ids <- cameras() |> sdl_try
        verify(length(ids) == 0)
        verify(is_err(camera_supported_formats(0u)))
        verify(length(SDL_GetCameraName(0u)) == 0)
        verify(is_err(camera_name(0u)))
        verify(SDL_GetCameraPosition(0u) == SDL_CameraPosition.CAMERA_POSITION_UNKNOWN)
        verify(camera_position(0u) == SDL_CameraPosition.CAMERA_POSITION_UNKNOWN)
        var spec = SDL_CameraSpec(
            format = SDL_PixelFormat.PIXELFORMAT_RGBA32,
            colorspace = SDL_Colorspace.COLORSPACE_SRGB,
            width = 320,
            height = 240,
            framerate_numerator = 30,
            framerate_denominator = 1
        )
        verify(spec.width == 320 && spec.height == 240 && spec.framerate_numerator == 30 && spec.framerate_denominator == 1)
        verify(SDL_OpenCamera(0u, null) == null)
        verify(is_err(open_camera(0u)) && is_err(open_camera(0u, spec)))
        verify(SDL_GetCameraPermissionState(null) == SDL_CameraPermissionState.DENIED)
        verify(camera_permission_state(null) == SDL_CameraPermissionState.DENIED)
        verify(SDL_GetCameraID(null) == 0u && SDL_GetCameraProperties(null) == 0u)
        verify(is_err(camera_id(null)) && is_err(camera_properties(null)))
        var timestamp = 99ul
        unsafe {
            verify(!SDL_GetCameraFormat(null, addr(spec)))
            verify(SDL_AcquireCameraFrame(null, addr(timestamp)) == null && timestamp == 0ul)
        }
        verify(is_err(camera_format(null)))
        let failed = acquire_camera_frame(null)
        verify(is_err(failed))
        saved = unwrap_err(failed)
        SDL_SetErrorText("replaced")
        verify(saved.operation == "SDL_AcquireCameraFrame" && saved.message != "replaced" && length(saved.message) > 0)
        var frame = CameraFrame(timestamp_ns = 123ul)
        release_camera_frame(null, frame)
        verify(frame.surface == null && frame.timestamp_ns == 0ul)
        SDL_ReleaseCameraFrame(null, null)
        SDL_CloseCamera(null)
        var camera : SDL_Camera?
        close_camera(camera)
        verify(camera == null)
        var called = false
        let scoped = with_camera(0u) $(opened) {called = true; return sdl_ok()}
        verify(is_err(scoped) && !called)
        let scoped_spec = with_camera(0u, spec) $(opened) {called = true; return sdl_ok()}
        verify(is_err(scoped_spec) && !called)
        var scoped_array <- with_camera(0u) $(opened) {
            called = true
            var values <- array<int>(1, 2)
            return <- move_ok(values, type<SdlError>)
        }
        verify(is_err(scoped_array) && !called)
        var scoped_frame <- with_camera_frame(null) $(borrowed) {called = true; return sdl_ok()}
        verify(is_err(scoped_frame) && !called)
        var scoped_number <- with_camera_frame(null) $(borrowed : CameraFrame) {
            called = true
            return ok(SDL_GetSurfaceProperties(borrowed.surface), type<SdlError>)
        }
        verify(is_err(scoped_number) && !called)
        var scoped_values <- with_camera_frame(null) $(borrowed) {
            called = true
            var values <- array<int>(3, 4)
            return <- move_ok(values, type<SdlError>)
        }
        verify(is_err(scoped_values) && !called)
        return sdl_ok()
    }
    verify(is_ok(result))
    verify(is_none(current_camera_driver()) && SDL_WasInit(SDL_INIT_CAMERA) == 0u)
    verify(saved.message != "replaced" && length(saved.message) > 0)
    print("Camera: 15 raw calls, dummy empty discovery, failure contracts and generic scope instantiations passed.\n")
    print("Hardware frame acquisition, permission transitions and successful release scopes NOT tested.\n")
    return 0
}
