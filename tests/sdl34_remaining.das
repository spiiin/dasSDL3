options gen2
require dassdl3/sdl3_remaining_34_boost
require dassdl3/sdl3_boost
require daslib/defer

def window_and_cursor {
    let window = SDL_CreateWindow("SDL 3.4 contract test", 64, 64, SDL_WINDOW_HIDDEN); verify(window != null)
    defer(){SDL_DestroyWindow(window)}
    verify(SDL_SetWindowProgressState(window, SDL_ProgressState.PROGRESS_STATE_NORMAL))
    verify(SDL_GetWindowProgressState(window) == SDL_ProgressState.PROGRESS_STATE_NORMAL)
    verify(SDL_SetWindowProgressValue(window, 0.375) && SDL_GetWindowProgressValue(window) == 0.375)
    verify(is_ok(set_window_progress_value(window, 2.0)) && unwrap(window_progress_value(window)) == 1.0)
    verify(is_ok(set_window_progress_value(window, -2.0)) && unwrap(window_progress_value(window)) == 0.0)
    verify(is_ok(set_window_progress_state(window, SDL_ProgressState.PROGRESS_STATE_NONE)))
    verify(unwrap(window_progress_state(window)) == SDL_ProgressState.PROGRESS_STATE_NONE)
    verify(!SDL_SetWindowProgressState(window, SDL_ProgressState.PROGRESS_STATE_INVALID))
    verify(SDL_GetWindowProgressState(null) == SDL_ProgressState.PROGRESS_STATE_INVALID && SDL_GetWindowProgressValue(null) == -1.0)
    verify(is_err(window_progress_state(null)) && is_err(window_progress_value(null)))
    verify(!SDL_SetWindowProgressValue(null, 0.0) && !SDL_SetWindowFillDocument(null, true))
    // On desktop fill-document is a successful no-op, not fullscreen.
    verify(SDL_SetWindowFillDocument(window, true))
    verify(is_ok(set_window_fill_document(window, false)))
    var first = SDL_CreateSurface(8, 8, SDL_PixelFormat.PIXELFORMAT_RGBA32)
    var second = SDL_CreateSurface(8, 8, SDL_PixelFormat.PIXELFORMAT_RGBA32)
    verify(first != null && second != null)
    verify(SDL_ClearSurface(first, 1.0, 0.0, 0.0, 1.0) && SDL_ClearSurface(second, 0.0, 0.0, 1.0, 1.0))
    var frames <- array<SDL_CursorFrameInfo>(SDL_CursorFrameInfo(surface = first, duration = 100u), SDL_CursorFrameInfo(surface = second, duration = 100u))
    var cursor : SDL_Cursor?
    unsafe{cursor = SDL_CreateAnimatedCursor(addr(frames[0]), 2, 0, 0)}
    verify(cursor != null)
    verify(is_ok(with_animated_cursor(frames, 0, 0) $(borrowed) {verify(borrowed != null); return sdl_ok()}))
    let failed = with_animated_cursor(frames, 0, 0) $(borrowed) {return err(SdlError(operation = "body", message = "early"), type<SdlUnit>)}
    verify(is_err(failed) && unwrap_err(failed).message == "early")
    SDL_DestroySurface(first); SDL_DestroySurface(second)
    verify(SDL_SetCursor(cursor) && SDL_GetCursor() == cursor)
    verify(SDL_SetCursor(SDL_GetDefaultCursor())); SDL_DestroyCursor(cursor)
    var empty : array<SDL_CursorFrameInfo>
    verify(is_err(with_animated_cursor(empty, 0, 0) $(borrowed) {verify(false); return sdl_ok()}))
    verify(SDL_CreateAnimatedCursor(null, 0, 0, 0) == null)
    verify(SDL_SetRelativeMouseTransform(SDLTestRemaining34Callback(true), null))
    verify(SDL_SetRelativeMouseTransform(null, null))// No retained script callback/context.
}
[export]
def main(smoke : bool) : int {
    verify(SDL_Init(SDL_INIT_VIDEO)); defer(){SDL_Quit()}
    window_and_cursor()
    verify(SDL_GetSystemPageSize() > 0)
    verify(SDL_GetPenDeviceType(0u) == SDL_PenDeviceType.PEN_DEVICE_TYPE_INVALID && is_err(pen_device_type(0u)))
    verify(SDL_hid_get_properties(null) == 0u && is_err(hid_properties(null)))
    verify(SDL_PROP_HIDAPI_LIBUSB_DEVICE_HANDLE_POINTER == "SDL.hidapi.libusb.device.handle")
    var event = SDL_MakeEvent(); event.event_type = SDL_EVENT_QUIT
    var expected : int
    unsafe{expected = SDL_GetEventDescription(addr(event), "", 0)}
    let buffer = SDLTestRemaining34DescriptionBuffer()
    unsafe{verify(SDL_GetEventDescription(addr(event), buffer, 1024) == expected)}
    verify(length(buffer) == expected)
    unsafe{verify(SDL_GetEventDescription(addr(event), buffer, 4) == expected)}
    verify(length(buffer) == 3)// Raw writable char buffer and truncation in both backends/AOT.
    let description = event_description(event)
    verify(expected > 0 && length(description) == expected)
    event.event_type = SDL_EVENT_MOUSE_MOTION
    let changed = event_description(event)
    verify(length(changed) > 0 && description != changed && length(description) == expected)
    verify(SDL_GetEventDescription(null, "", 0) > 0)
    print("SDL 3.4 window/cursor/events/page size/native callbacks: PASS; HID/pen invalid-device paths only\n")
    return 0
}
