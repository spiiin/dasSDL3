options gen2
module sdl3_remaining_34_boost shared public
require dassdl3/sdl3_result public
require daslib/defer

def public set_window_progress_state(window : SDL_Window?; state : SDL_ProgressState) {
    return sdl_status(SDL_SetWindowProgressState(window,state),"SDL_SetWindowProgressState")
}
def public window_progress_state(window : SDL_Window?) {
    let state=SDL_GetWindowProgressState(window)
    if(state==SDL_ProgressState.PROGRESS_STATE_INVALID) {return err(sdl_error("SDL_GetWindowProgressState"),type<SDL_ProgressState>)}
    return ok(state,type<SdlError>)
}
def public set_window_progress_value(window : SDL_Window?; value : float) {
    return sdl_status(SDL_SetWindowProgressValue(window,value),"SDL_SetWindowProgressValue")
}
def public window_progress_value(window : SDL_Window?) {
    let value=SDL_GetWindowProgressValue(window)
    if(value<0.0) {return err(sdl_error("SDL_GetWindowProgressValue"),type<float>)}
    return ok(value,type<SdlError>)
}
def public set_window_fill_document(window : SDL_Window?; fill : bool) {
    return sdl_status(SDL_SetWindowFillDocument(window,fill),"SDL_SetWindowFillDocument")
}
def public pen_device_type(id : uint) {
    let value=SDL_GetPenDeviceType(id)
    if(value==SDL_PenDeviceType.PEN_DEVICE_TYPE_INVALID) {return err(sdl_error("SDL_GetPenDeviceType"),type<SDL_PenDeviceType>)}
    return ok(value,type<SdlError>)
}
// Borrowed properties; valid only while the HID device remains open.
def public hid_properties(device : SDL_hid_device?) {
    let value=SDL_hid_get_properties(device)
    if(value==0u) {return err(sdl_error("SDL_hid_get_properties"),type<uint>)}
    return ok(value,type<SdlError>)
}
def public event_description(event : SDL_Event) {return SDL_GetEventDescriptionCopy(event)}
def public put_audio_planar(stream : SDL_AudioStream?; samples : array<float>; channels,frames : int) {
    return sdl_status(SDL_PutAudioStreamPlanarFloats(stream,samples,channels,frames),"SDL_PutAudioStreamPlanarData")
}
def public with_animated_cursor(frames : array<SDL_CursorFrameInfo>; x,y : int;
    body : block<(cursor : SDL_Cursor?) : $Result<auto(T); SdlError>>) {
    let cursor=SDL_CreateAnimatedCursorArray(frames,x,y)
    if(cursor==null) {return err(sdl_error("SDL_CreateAnimatedCursor"),type<T>)}
    var result : $Result<T; SdlError>
    {
        defer(){SDL_DestroyCursor(cursor)}
        static_if(typeinfo can_copy(type<$Result<T; SdlError>>)) {result=body(cursor)}
        else {result <- body(cursor)}
    }
    return <- result
}

def public put_audio_planar(stream : SDL_AudioStream?; samples : array<uint8>; channels,frames : int) {
    return sdl_status(SDL_PutAudioStreamPlanarBytes(stream,samples,channels,frames),"SDL_PutAudioStreamPlanarData")
}
