options gen2
require daslib/defer
module sdl3_rect_clipboard_boost shared public
require dassdl3/sdl3_window_io_boost public

// Callback/captures/context stay live until this call returns. Do not panic in callbacks.
// Keep AOT block temporaries alive for the entire call, not just native registration.
[never_inline]
def public with_window_hit_test(window : SDL_Window?; callback : block<(window : SDL_Window?; x : int; y : int) : SDL_HitTestResult>; body : block<() : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let state = SDL_SetWindowHitTestBlock(window, callback)
    if (state == null) {return err(sdl_error("with_window_hit_test"), type<TT>)}
    {defer(){if (!SDL_ClearWindowHitTestBlockChecked(state) && is_ok(scope_result)){scope_result <- err(sdl_error("SDL_ClearWindowHitTestBlockChecked"), type<TT>)}}; static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = body() } else { scope_result <- body() }}

    return <- scope_result
}
def public clipboard_text() {
    var value : string
    if (!SDL_GetClipboardTextValue(value)) {return err(sdl_error("clipboard_text"), type<string>)}
    return ok(value, type<SdlError>)
}
def public primary_selection_text() {
    var value : string
    if (!SDL_GetPrimarySelectionTextValue(value)) {return err(sdl_error("primary_selection_text"), type<string>)}
    return ok(value, type<SdlError>)
}
def public clipboard_data(mime : string; var bytes : array<uint8>) {return sdl_status(SDL_GetClipboardDataCopy(mime, bytes), "clipboard_data")}
def public set_clipboard_data(mime : string; bytes : array<uint8>) {return sdl_status(SDL_SetClipboardDataCopy(mime, bytes), "set_clipboard_data")}
def public clipboard_mime_types(var types : array<string>) {return sdl_status(SDL_GetClipboardMimeTypesCopy(types), "clipboard_mime_types")}

def public clipboard_data(mime : string) {
    var bytes : array<uint8>
    let status = clipboard_data(mime, bytes)
    if (is_err(status)) { return err(unwrap_err(status), type<array<uint8>>) }
    var value <- bytes
    return <- move_ok(value, type<SdlError>)
}

def public clipboard_mime_types() {
    var types : array<string>
    let status = clipboard_mime_types(types)
    if (is_err(status)) { return err(unwrap_err(status), type<array<string>>) }
    var value <- types
    return <- move_ok(value, type<SdlError>)
}
