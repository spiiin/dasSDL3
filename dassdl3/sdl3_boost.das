options gen2
require daslib/defer
module sdl3_boost shared public
require sdl3 public

// Synchronous helpers. Raw pointers are borrowed inside the with_* blocks.
def public sdl_init(flags : uint = SDL_INIT_VIDEO) {
    return SDL_Init(flags)
}
def public create_window(title : string; width, height : int;
                         flags : uint64 = SDL_WINDOW_RESIZABLE) {
    var window = SDL_CreateWindow(title, width, height, flags)
    return window
}
def public create_renderer(window : SDL_Window?; driver : string = "") {
    var renderer = SDL_CreateRenderer(window, driver)
    return renderer
}
def public destroy_renderer(renderer : SDL_Renderer?) {
    if (renderer != null) { SDL_DestroyRenderer(renderer) }
}
def public destroy_window(window : SDL_Window?) {
    if (window != null) { SDL_DestroyWindow(window) }
}
def public poll_event(var event : SDL_Event) : bool {
    return SDL_PollEventRef(event)
}
def public push_event(var event : SDL_Event) {
    return SDL_PushEventRef(event)
}
def public should_close(event : SDL_Event) : bool {
    return SDL_EventIsQuit(event) || SDL_EventIsEscape(event)
}
def public set_color(renderer : SDL_Renderer?; rgba : uint4) {
    if (rgba.x > 255u || rgba.y > 255u || rgba.z > 255u || rgba.w > 255u) {
        return SDL_SetErrorMessage("set_color: components must be in 0..255")
    }
    return SDL_SetRenderDrawColor(renderer, rgba.x, rgba.y, rgba.z, rgba.w)
}
def public clear(renderer : SDL_Renderer?; rgba : uint4 = uint4(24u, 28u, 40u, 255u)) {
    if (!(renderer |> set_color(rgba))) { return false }
    return SDL_RenderClear(renderer)
}
def public fill_rect(renderer : SDL_Renderer?; rect : SDL_FRect) {
    return SDL_RenderFillRectRef(renderer, rect)
}
def public present(renderer : SDL_Renderer?) {
    return SDL_RenderPresent(renderer)
}

// Successful scopes defer cleanup on normal and early return; false skips the block.
def public with_sdl(flags : uint; blk : block<() : void>) {
    if (!sdl_init(flags)) { return false }
    {
        defer() { SDL_Quit() }
        blk()
        return true
    }
}

def public with_sdl(blk : block<() : void>) {
    return with_sdl(SDL_INIT_VIDEO, blk)
}

def public with_window(title : string; width, height : int; flags : uint64;
                       blk : block<(window : SDL_Window?) : void>) {
    var window = create_window(title, width, height, flags)
    if (window == null) { return false }
    {
        defer() { SDL_DestroyWindow(window) }
        blk(window)
        return true
    }
}

def public with_renderer(window : SDL_Window?; blk : block<(renderer : SDL_Renderer?) : void>) {
    var renderer = create_renderer(window)
    if (renderer == null) { return false }
    {
        defer() { SDL_DestroyRenderer(renderer) }
        blk(renderer)
        return true
    }
}

def public load_bmp(path : string) {
    var surface = SDL_LoadBMP(path)
    return surface
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
    return texture
}

def public texture_size(texture : SDL_Texture?; var size : float2&) : bool {
    var w, h : float
    if (!SDL_GetTextureSizeRef(texture, w, h)) { return false }
    size = float2(w, h)
    return true
}

// No rectangles: use the whole source and current rendering target.
def public draw_texture(renderer : SDL_Renderer?; texture : SDL_Texture?) {
    return SDL_RenderTexture(renderer, texture, null, null)
}

// One rectangle: whole source scaled to destination. Two: source crop + destination.
def public draw_texture(renderer : SDL_Renderer?; texture : SDL_Texture?; dst : SDL_FRect) {
    return SDL_RenderTextureToRect(renderer, texture, dst)
}

def public draw_texture(renderer : SDL_Renderer?; texture : SDL_Texture?;
                        src, dst : SDL_FRect) {
    return SDL_RenderTextureRects(renderer, texture, src, dst)
}

def public with_bmp(path : string; blk : block<(surface : SDL_Surface?) : void>) {
    var surface = load_bmp(path)
    if (surface == null) { return false }
    {
        defer() { SDL_DestroySurface(surface) }
        blk(surface)
        return true
    }
}

// Release the temporary CPU surface before returning the owned GPU texture.
def public load_texture(renderer : SDL_Renderer?; path : string) {
    var texture = SDL_LoadBMPTextureOwned(renderer,path)
    return texture
}

def public with_texture(renderer : SDL_Renderer?; path : string;
                        blk : block<(texture : SDL_Texture?) : void>) {
    var texture = load_texture(renderer, path)
    if (texture == null) { return false }
    {
        defer() { SDL_DestroyTexture(texture) }
        blk(texture)
        return true
    }
}

// Input reads are snapshots; poll events (or pump them) before querying key state.
def public key_event(event : SDL_Event; var key : SDL_KeyboardEvent) : bool {
    return SDL_ReadKeyEvent(event, key)
}
def public key_scancode(key : SDL_KeyboardEvent) : int { return SDL_KeyScancode(key) }
def public key_down(scancode : int) : bool { return SDL_IsScancodeDown(scancode) }
def public mouse_motion_event(event : SDL_Event; var motion : SDL_MouseMotionEvent) : bool {
    return SDL_ReadMouseMotionEvent(event, motion)
}
def public mouse_button_event(event : SDL_Event; var button : SDL_MouseButtonEvent) : bool {
    return SDL_ReadMouseButtonEvent(event, button)
}
def public mouse_wheel_event(event : SDL_Event; var wheel : SDL_MouseWheelEvent) : bool {
    return SDL_ReadMouseWheelEvent(event, wheel)
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
def public text_input_event(event : SDL_Event; var text : string&) : bool {
    return SDL_ReadTextInput(event, text)
}
def public text_editing_event(event : SDL_Event; var text : string&; var start, length : int&) : bool {
    return SDL_ReadTextEditing(event, text, start, length)
}
def public input_window_id(event : SDL_Event) : uint { return SDL_InputWindowID(event) }

// Global Quit applies to all windows; Escape and close requests match this window.
def public should_close(event : SDL_Event; window : SDL_Window?) : bool {
    if (SDL_EventIsQuit(event)) { return true }
    return (input_window_id(event) == SDL_GetWindowID(window) &&
           (SDL_EventIsEscape(event) || event.event_type == SDL_EVENT_WINDOW_CLOSE_REQUESTED))
}
def public set_title(window : SDL_Window?; title : string) {
    return SDL_SetWindowTitle(window, title)
}

// Preserve an already-active session. Do not start/stop input manually in the block.
def public with_text_input(window : SDL_Window?; blk : block<() : void>) {
    let owned = !SDL_TextInputActive(window)
    if (owned && !SDL_StartTextInput(window)) { return false }
    {
        defer() { if (owned) { SDL_StopTextInput(window) } }
        blk()
        return true
    }
}
