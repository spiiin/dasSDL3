options gen2
require daslib/defer
module sdl3_boost shared public
require dassdl3/sdl3_result public

// Synchronous helpers. Raw pointers are borrowed inside the with_* blocks.
def public sdl_init(flags : uint = SDL_INIT_VIDEO) {
    return sdl_status(SDL_Init(flags), "sdl_init")
}
def public create_window(title : string; width, height : int;
                         flags : uint64 = SDL_WINDOW_RESIZABLE) {
    var window = SDL_CreateWindow(title, width, height, flags)
    var value = window
    if (value == null) { return err(sdl_error("create_window"), type<SDL_Window?>) }
    return <- move_ok(value,type<SdlError>)
}
def public create_renderer(window : SDL_Window?; driver : string = "") {
    var renderer = SDL_CreateRenderer(window, driver)
    var value = renderer
    if (value == null) { return err(sdl_error("create_renderer"), type<SDL_Renderer?>) }
    return <- move_ok(value,type<SdlError>)
}
def public destroy_renderer(renderer : SDL_Renderer?) {
    if (renderer != null) { SDL_DestroyRenderer(renderer) }
}
def public destroy_window(window : SDL_Window?) {
    if (window != null) { SDL_DestroyWindow(window) }
}
def public poll_event(var event : SDL_Event) {
    if (!SDL_PollEventRef(event)) { return none(type<SdlUnit>) }
    return some(SdlUnit())
}
// SDL false conflates filtering and queue failure; preserve acceptance as a predicate.
// Do not turn a filter rejection plus a stale SDL error string into SdlError.
def public push_event(var event : SDL_Event) : bool {
    return SDL_PushEventRef(event)
}
def public should_close(event : SDL_Event) : bool {
    return SDL_EventIsQuit(event) || SDL_EventIsEscape(event)
}
def public set_color(renderer : SDL_Renderer?; rgba : uint4) {
    if (rgba.x > 255u || rgba.y > 255u || rgba.z > 255u || rgba.w > 255u) {
        SDL_SetErrorMessage("set_color: components must be in 0..255")
        return err(sdl_error("set_color"),type<SdlUnit>)
    }
    return sdl_status(SDL_SetRenderDrawColor(renderer,rgba.x,rgba.y,rgba.z,rgba.w),"SDL_SetRenderDrawColor")
}
def public clear(renderer : SDL_Renderer?; rgba : uint4 = uint4(24u,28u,40u,255u)) {
    var color = set_color(renderer,rgba)
    if (is_err(color)) { return <- color }
    return sdl_status(SDL_RenderClear(renderer),"SDL_RenderClear")
}
def public fill_rect(renderer : SDL_Renderer?; rect : SDL_FRect) {
    return sdl_status(SDL_RenderFillRectRef(renderer, rect), "fill_rect")
}
def public present(renderer : SDL_Renderer?) {
    return sdl_status(SDL_RenderPresent(renderer), "present")
}

// Successful scopes defer cleanup on normal and early return; acquisition errors skip the block.
def public with_sdl(flags : uint; blk : block<() : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    if (!SDL_Init(flags)) { return err(sdl_error("with_sdl"), type<TT>) }
    {
        defer() { SDL_Quit() }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk() } else { scope_result <- blk() }
    }

    return <- scope_result
}

def public with_sdl(blk : block<() : $Result<auto(TT); SdlError> >) {
    return <- with_sdl(SDL_INIT_VIDEO, blk)
}

def public with_window(title : string; width, height : int; flags : uint64;
                       blk : block<(window : SDL_Window?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var window = SDL_CreateWindow(title, width, height, flags)
    if (window == null) { return err(sdl_error("with_window"), type<TT>) }
    {
        defer() { SDL_DestroyWindow(window) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(window) } else { scope_result <- blk(window) }
    }

    return <- scope_result
}

def public with_renderer(window : SDL_Window?; blk : block<(renderer : SDL_Renderer?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var renderer = SDL_CreateRenderer(window, "")
    if (renderer == null) { return err(sdl_error("with_renderer"), type<TT>) }
    {
        defer() { SDL_DestroyRenderer(renderer) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(renderer) } else { scope_result <- blk(renderer) }
    }

    return <- scope_result
}

def public load_bmp(path : string) {
    var surface = SDL_LoadBMP(path)
    var value = surface
    if (value == null) { return err(sdl_error("load_bmp"), type<SDL_Surface?>) }
    return <- move_ok(value,type<SdlError>)
}

def public destroy_surface(surface : SDL_Surface?) {
    if (surface != null) { SDL_DestroySurface(surface) }
}

def public destroy_texture(texture : SDL_Texture?) {
    if (texture != null) { SDL_DestroyTexture(texture) }
}

// SDL copies the pixels; the caller still owns the surface.
def public create_texture(renderer : SDL_Renderer?; surface : SDL_Surface?) {
    var texture = SDL_CreateTextureFromSurface(renderer, surface)
    var value = texture
    if (value == null) { return err(sdl_error("create_texture"), type<SDL_Texture?>) }
    return <- move_ok(value,type<SdlError>)
}

def public texture_size(texture : SDL_Texture?; var size : float2&) {
    var w, h : float
    if (!SDL_GetTextureSizeRef(texture, w, h)) { return err(sdl_error("texture_size"), type<SdlUnit>) }
    size = float2(w, h)
    return sdl_ok()
}

// No rectangles: use the whole source and current rendering target.
def public draw_texture(renderer : SDL_Renderer?; texture : SDL_Texture?) {
    return sdl_status(SDL_RenderTexture(renderer, texture, null, null), "draw_texture")
}

// One rectangle: whole source scaled to destination. Two: source crop + destination.
def public draw_texture(renderer : SDL_Renderer?; texture : SDL_Texture?; dst : SDL_FRect) {
    return sdl_status(SDL_RenderTextureToRect(renderer, texture, dst), "draw_texture")
}

def public draw_texture(renderer : SDL_Renderer?; texture : SDL_Texture?;
                        src, dst : SDL_FRect) {
    return sdl_status(SDL_RenderTextureRects(renderer, texture, src, dst), "draw_texture")
}

def public with_bmp(path : string; blk : block<(surface : SDL_Surface?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var surface = SDL_LoadBMP(path)
    if (surface == null) { return err(sdl_error("with_bmp"), type<TT>) }
    {
        defer() { SDL_DestroySurface(surface) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(surface) } else { scope_result <- blk(surface) }
    }

    return <- scope_result
}

// Release the temporary CPU surface before returning the owned GPU texture.
def public load_texture(renderer : SDL_Renderer?; path : string) {
    let surface=SDL_LoadBMP(path)
    if (surface==null) {return err(sdl_error("SDL_LoadBMP"),type<SDL_Texture?>)}
    {
        defer(){SDL_DestroySurface(surface)}
        var texture=SDL_CreateTextureFromSurface(renderer,surface)
        if(texture==null){return err(sdl_error("SDL_CreateTextureFromSurface"),type<SDL_Texture?>)}
        return <- move_ok(texture,type<SdlError>)
    }
}

def public with_texture(renderer : SDL_Renderer?; path : string;
                        blk : block<(texture : SDL_Texture?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var created <- load_texture(renderer,path)
    if (is_err(created)) { return err(unwrap_err(created),type<TT>) }
    var texture = move_unwrap(created)
    {
        defer() { SDL_DestroyTexture(texture) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(texture) } else { scope_result <- blk(texture) }
    }

    return <- scope_result
}

// Input reads are snapshots; poll events (or pump them) before querying key state.
def public key_event(event : SDL_Event; var key : SDL_KeyboardEvent) {
    if (!SDL_ReadKeyEvent(event, key)) { return none(type<SdlUnit>) }
    return some(SdlUnit())
}
def public key_scancode(key : SDL_KeyboardEvent) : int { return SDL_KeyScancode(key) }
def public key_down(scancode : int) : bool { return SDL_IsScancodeDown(scancode) }
def public mouse_motion_event(event : SDL_Event; var motion : SDL_MouseMotionEvent) {
    if (!SDL_ReadMouseMotionEvent(event, motion)) { return none(type<SdlUnit>) }
    return some(SdlUnit())
}
def public mouse_button_event(event : SDL_Event; var button : SDL_MouseButtonEvent) {
    if (!SDL_ReadMouseButtonEvent(event, button)) { return none(type<SdlUnit>) }
    return some(SdlUnit())
}
def public mouse_wheel_event(event : SDL_Event; var wheel : SDL_MouseWheelEvent) {
    if (!SDL_ReadMouseWheelEvent(event, wheel)) { return none(type<SdlUnit>) }
    return some(SdlUnit())
}
// Normalize natural/reversed scrolling while preserving raw data in the snapshot.
def public wheel_delta(wheel : SDL_MouseWheelEvent) : float2 {
    let sign = SDL_MouseWheelFlipped(wheel) ? -1.0 : 1.0
    return float2(wheel.x * sign, wheel.y * sign)
}
def public mouse_state(var position : float2&) : uint {
    var x, y : float
    let buttons = SDL_GetMouseStateRef(x, y)
    position = float2(x, y)
    return buttons
}
def public text_input_event(event : SDL_Event; var text : string&) {
    if (!SDL_ReadTextInput(event, text)) { return none(type<SdlUnit>) }
    return some(SdlUnit())
}
def public text_editing_event(event : SDL_Event; var text : string&; var start, length : int&) {
    if (!SDL_ReadTextEditing(event, text, start, length)) { return none(type<SdlUnit>) }
    return some(SdlUnit())
}
def public input_window_id(event : SDL_Event) : uint { return SDL_InputWindowID(event) }

// Global Quit applies to all windows; Escape and close requests match this window.
def public should_close(event : SDL_Event; window : SDL_Window?) : bool {
    if (SDL_EventIsQuit(event)) { return true }
    return (input_window_id(event) == SDL_GetWindowID(window) &&
           (SDL_EventIsEscape(event) || event.event_type == SDL_EVENT_WINDOW_CLOSE_REQUESTED))
}
def public set_title(window : SDL_Window?; title : string) {
    return sdl_status(SDL_SetWindowTitle(window, title), "set_title")
}

// Preserve an already-active session. Do not start/stop input manually in the block.
def public with_text_input(window : SDL_Window?; blk : block<() : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let owned = !SDL_TextInputActive(window)
    if (owned && !SDL_StartTextInput(window)) { return err(sdl_error("with_text_input"),type<TT>) }
    {
        defer() { if (owned) { if (!SDL_StopTextInput(window) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_StopTextInput"),type<TT>) } } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk() } else { scope_result <- blk() }
    }

    return <- scope_result
}

// SDL false conflates filtering and queue failure; preserve acceptance as a predicate.
// Do not turn a filter rejection plus a stale SDL error string into SdlError.


def public texture_size(texture : SDL_Texture?) {
    var size : float2
    let status = texture_size(texture,size)
    if (is_err(status)) { return err(unwrap_err(status),type<float2>) }
    var value = size
    return <- move_ok(value,type<SdlError>)
}

def public key_event(event : SDL_Event) {
    var key : SDL_KeyboardEvent
    let status = key_event(event,key)
    if (is_none(status)) { return none(type<SDL_KeyboardEvent>) }
    var value = key
    return <- move_some(value)
}

def public mouse_motion_event(event : SDL_Event) {
    var motion : SDL_MouseMotionEvent
    let status = mouse_motion_event(event,motion)
    if (is_none(status)) { return none(type<SDL_MouseMotionEvent>) }
    var value = motion
    return <- move_some(value)
}

def public mouse_button_event(event : SDL_Event) {
    var button : SDL_MouseButtonEvent
    let status = mouse_button_event(event,button)
    if (is_none(status)) { return none(type<SDL_MouseButtonEvent>) }
    var value = button
    return <- move_some(value)
}

def public mouse_wheel_event(event : SDL_Event) {
    var wheel : SDL_MouseWheelEvent
    let status = mouse_wheel_event(event,wheel)
    if (is_none(status)) { return none(type<SDL_MouseWheelEvent>) }
    var value = wheel
    return <- move_some(value)
}

def public text_input_event(event : SDL_Event) {
    var text : string
    let status = text_input_event(event,text)
    if (is_none(status)) { return none(type<string>) }
    var value = text
    return <- move_some(value)
}

def public text_editing_event(event : SDL_Event) {
    var text : string
    var start : int
    var length : int
    let status = text_editing_event(event,text,start,length)
    if (is_none(status)) { return none(type<tuple<text:string; start:int; length:int>>) }
    var value = (text=text,start=start,length=length)
    return <- move_some(value)
}
