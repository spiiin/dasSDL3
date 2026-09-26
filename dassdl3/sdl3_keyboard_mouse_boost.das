options gen2
require daslib/defer
module sdl3_keyboard_mouse_boost shared public
require dassdl3/sdl3_boost public

def public keyboards() {
    var values : array<uint>
    if (!SDL_GetKeyboardsCopy(values)) { return err(sdl_error("SDL_GetKeyboardsCopy"), type<array<uint>>) }
    return <- move_ok(values, type<SdlError>)
}
def public mice() {
    var values : array<uint>
    if (!SDL_GetMiceCopy(values)) { return err(sdl_error("SDL_GetMiceCopy"), type<array<uint>>) }
    return <- move_ok(values, type<SdlError>)
}
def public keyboard_state() {
    var values : array<bool>
    SDL_GetKeyboardStateCopy(values)
    return <- values
}
def public keyboard_name(id : uint) {
    var value : string
    if (!SDL_GetKeyboardNameValue(id, value)) { return err(sdl_error("SDL_GetKeyboardNameValue"), type<string>) }
    return ok(value, type<SdlError>)
}
def public mouse_name(id : uint) {
    var value : string
    if (!SDL_GetMouseNameValue(id, value)) { return err(sdl_error("SDL_GetMouseNameValue"), type<string>) }
    return ok(value, type<SdlError>)
}
// SDL represents unknown/unnamed keys by an empty string; preserve it.
def public key_name(key : uint) : string { return SDL_GetKeyNameCopy(key) }
def public scancode_name(code : SDL_Scancode) : string { return SDL_GetScancodeNameCopy(code) }
def public scancode_from_key(key : uint; var mods : uint&) : SDL_Scancode { return SDL_GetScancodeFromKeyRef(key, mods) }
def public global_mouse_state(var position : float2&) : uint { return SDL_GetGlobalMouseStateRef(position.x, position.y) }
// Reading consumes accumulated relative motion, as in SDL.
def public relative_mouse_state(var delta : float2&) : uint { return SDL_GetRelativeMouseStateRef(delta.x, delta.y) }
def public set_text_input_area(window : SDL_Window?; rect : SDL_Rect; cursor : int) { return sdl_status(SDL_SetTextInputAreaRef(window, rect, cursor), "SDL_SetTextInputArea") }
def public text_input_area(window : SDL_Window?; var rect : SDL_Rect; var cursor : int&) { return sdl_status(SDL_GetTextInputAreaRef(window, rect, cursor), "SDL_GetTextInputArea") }
def public set_relative_mouse_mode(window : SDL_Window?; enabled : bool) { return sdl_status(SDL_SetWindowRelativeMouseMode(window, enabled), "SDL_SetWindowRelativeMouseMode") }
def public capture_mouse(enabled : bool) { return sdl_status(SDL_CaptureMouse(enabled), "SDL_CaptureMouse") }
def public warp_mouse_global(position : float2) { return sdl_status(SDL_WarpMouseGlobal(position.x, position.y), "SDL_WarpMouseGlobal") }
def public set_cursor(cursor : SDL_Cursor?) { return sdl_status(SDL_SetCursor(cursor), "SDL_SetCursor") }
def public show_cursor() { return sdl_status(SDL_ShowCursor(), "SDL_ShowCursor") }
def public hide_cursor() { return sdl_status(SDL_HideCursor(), "SDL_HideCursor") }
// Borrowed pointer; never destroy a focus/default resource through this query.
def public keyboard_focus() {
    var value = SDL_GetKeyboardFocus()
    if (value == null) { return none(type<SDL_Window?>) }
    return <- move_some(value)
}
// Borrowed pointer; never destroy a focus/default resource through this query.
def public mouse_focus() {
    var value = SDL_GetMouseFocus()
    if (value == null) { return none(type<SDL_Window?>) }
    return <- move_some(value)
}
// Borrowed pointer; never destroy a focus/default resource through this query.
def public current_cursor() {
    var value = SDL_GetCursor()
    if (value == null) { return none(type<SDL_Cursor?>) }
    return <- move_some(value)
}
// Borrowed pointer; never destroy a focus/default resource through this query.
def public default_cursor() {
    var value = SDL_GetDefaultCursor()
    if (value == null) { return none(type<SDL_Cursor?>) }
    return <- move_some(value)
}
def public create_system_cursor(id : SDL_SystemCursor) {
    var value = SDL_CreateSystemCursor(id)
    if (value == null) { return err(sdl_error("SDL_CreateSystemCursor"), type<SDL_Cursor?>) }
    return <- move_ok(value, type<SdlError>)
}
def public create_color_cursor(surface : SDL_Surface?; hot_x, hot_y : int) {
    var value = SDL_CreateColorCursor(surface, hot_x, hot_y)
    if (value == null) { return err(sdl_error("SDL_CreateColorCursor"), type<SDL_Cursor?>) }
    return <- move_ok(value, type<SdlError>)
}
def public create_cursor(data, mask : array<uint8>; w, h, hot_x, hot_y : int) {
    var value = SDL_CreateCursorArray(data, mask, w, h, hot_x, hot_y)
    if (value == null) { return err(sdl_error("SDL_CreateCursorArray"), type<SDL_Cursor?>) }
    return <- move_ok(value, type<SdlError>)
}
// Owns this cursor only; it does not restore a previous selected cursor.
def public with_system_cursor(id : SDL_SystemCursor; body : block<(cursor : SDL_Cursor?) : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    let cursor = SDL_CreateSystemCursor(id)
    if (cursor == null) { return err(sdl_error("SDL_CreateSystemCursor"), type<TT>) }
    {
        defer() { SDL_DestroyCursor(cursor) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { scope_result = body(cursor) }
        else { scope_result <- body(cursor) }
    }
    return <- scope_result
}
// Owns this cursor only; it does not restore a previous selected cursor.
def public with_color_cursor(surface : SDL_Surface?; hot_x, hot_y : int; body : block<(cursor : SDL_Cursor?) : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    let cursor = SDL_CreateColorCursor(surface, hot_x, hot_y)
    if (cursor == null) { return err(sdl_error("SDL_CreateColorCursor"), type<TT>) }
    {
        defer() { SDL_DestroyCursor(cursor) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { scope_result = body(cursor) }
        else { scope_result <- body(cursor) }
    }
    return <- scope_result
}
// Owns this cursor only; it does not restore a previous selected cursor.
def public with_cursor(data, mask : array<uint8>; w, h, hot_x, hot_y : int; body : block<(cursor : SDL_Cursor?) : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    let cursor = SDL_CreateCursorArray(data, mask, w, h, hot_x, hot_y)
    if (cursor == null) { return err(sdl_error("SDL_CreateCursorArray"), type<TT>) }
    {
        defer() { SDL_DestroyCursor(cursor) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { scope_result = body(cursor) }
        else { scope_result <- body(cursor) }
    }
    return <- scope_result
}
// Preserve an existing input session; its properties are not overwritten.
def public with_text_input_properties(window : SDL_Window?; props : uint;
                                      body : block<() : $Result<auto(TT); SdlError>>) {
    var scope_result : $Result<TT; SdlError>
    let owned = !SDL_TextInputActive(window)
    if (owned && !SDL_StartTextInputWithProperties(window, props)) { return err(sdl_error("SDL_StartTextInputWithProperties"), type<TT>) }
    {
        defer() { if (owned && !SDL_StopTextInput(window) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_StopTextInput"), type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { scope_result = body() }
        else { scope_result <- body() }
    }
    return <- scope_result
}

def public global_mouse_state() : MouseState {
    var position : float2
    let buttons = global_mouse_state(position)
    return MouseState(position = position, buttons = buttons)
}
def public relative_mouse_state() : MouseState {
    var delta : float2
    let buttons = relative_mouse_state(delta)
    return MouseState(position = delta, buttons = buttons)
}
struct ScancodeMapping { scancode : SDL_Scancode; modifiers : uint }
def public scancode_from_key(key : uint) : ScancodeMapping {
    var modifiers : uint
    let scancode = scancode_from_key(key, modifiers)
    return ScancodeMapping(scancode = scancode, modifiers = modifiers)
}
struct TextInputArea { rect : SDL_Rect; cursor : int }
def public text_input_area(window : SDL_Window?) {
    var value : TextInputArea
    let status = text_input_area(window, value.rect, value.cursor)
    if (is_err(status)) { return err(unwrap_err(status), type<TextInputArea>) }
    return ok(value, type<SdlError>)
}
