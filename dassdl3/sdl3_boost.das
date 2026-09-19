options gen2
module sdl3_boost shared public
require sdl3 public
require daslib/rtti
require daslib/strings_boost

// Synchronous helpers. Raw pointers are borrowed inside the with_* blocks.
def private check_sdl(ok : bool; operation : string) {
    if (!ok) { panic("{operation}: {SDL_GetError()}") }
}
def public sdl_init(flags : uint = SDL_INIT_VIDEO) {
    check_sdl(SDL_Init(flags), "SDL_Init")
}
def public create_window(title : string; width, height : int;
                         flags : uint64 = SDL_WINDOW_RESIZABLE) {
    var window = SDL_CreateWindow(title, width, height, flags)
    if (window == null) { panic("SDL_CreateWindow: {SDL_GetError()}") }
    return window
}
def public create_renderer(window : SDL_Window?; driver : string = "") {
    verify(window != null, "create_renderer: null window")
    var renderer = SDL_CreateRenderer(window, driver)
    if (renderer == null) { panic("SDL_CreateRenderer: {SDL_GetError()}") }
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
    check_sdl(SDL_PushEventRef(event), "SDL_PushEvent")
}
def public should_close(event : SDL_Event) : bool {
    return SDL_EventIsQuit(event) || SDL_EventIsEscape(event)
}
def public set_color(renderer : SDL_Renderer?; rgba : uint4) {
    verify(renderer != null, "set_color: null renderer")
    verify(rgba.x <= 255u && rgba.y <= 255u && rgba.z <= 255u && rgba.w <= 255u,
           "set_color: components must be in 0..255")
    check_sdl(SDL_SetRenderDrawColor(renderer, rgba.x, rgba.y, rgba.z, rgba.w), "SDL_SetRenderDrawColor")
}
def public clear(renderer : SDL_Renderer?; rgba : uint4 = uint4(24u, 28u, 40u, 255u)) {
    renderer |> set_color(rgba)
    check_sdl(SDL_RenderClear(renderer), "SDL_RenderClear")
}
def public fill_rect(renderer : SDL_Renderer?; rect : SDL_FRect) {
    verify(renderer != null, "fill_rect: null renderer")
    check_sdl(SDL_RenderFillRectRef(renderer, rect), "SDL_RenderFillRect")
}
def public present(renderer : SDL_Renderer?) {
    verify(renderer != null, "present: null renderer")
    check_sdl(SDL_RenderPresent(renderer), "SDL_RenderPresent")
}

// In the pinned daScript version panic skips defer/finally. Recover locally,
// preserve the message, release the resource, then propagate the panic.
def public with_sdl(flags : uint; blk : block<() : void>) {
    sdl_init(flags)
    var failed = false
    var error = ""
    try { SDL_InvokeScope(blk) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    SDL_Quit()
    if (failed) { panic(error) }
}

def public with_sdl(blk : block<() : void>) {
    with_sdl(SDL_INIT_VIDEO, blk)
}

def public with_window(title : string; width, height : int; flags : uint64;
                       blk : block<(window : SDL_Window?) : void>) {
    var window = create_window(title, width, height, flags)
    var failed = false
    var error = ""
    try { SDL_InvokeWindow(blk, window) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    destroy_window(window)
    if (failed) { panic(error) }
}

def public with_renderer(window : SDL_Window?; blk : block<(renderer : SDL_Renderer?) : void>) {
    var renderer = create_renderer(window)
    var failed = false
    var error = ""
    try { SDL_InvokeRenderer(blk, renderer) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    destroy_renderer(renderer)
    if (failed) { panic(error) }
}

def public load_bmp(path : string) {
    var surface = SDL_LoadBMP(path)
    if (surface == null) { panic("SDL_LoadBMP({path}): {SDL_GetError()}") }
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
    verify(renderer != null, "create_texture: null renderer")
    verify(surface != null, "create_texture: null surface")
    var texture = SDL_CreateTextureFromSurface(renderer, surface)
    if (texture == null) { panic("SDL_CreateTextureFromSurface: {SDL_GetError()}") }
    return texture
}

def public texture_size(texture : SDL_Texture?) : float2 {
    verify(texture != null, "texture_size: null texture")
    var w, h : float
    check_sdl(SDL_GetTextureSizeRef(texture, w, h), "SDL_GetTextureSize")
    return float2(w, h)
}

// No rectangles: use the whole source and current rendering target.
def public draw_texture(renderer : SDL_Renderer?; texture : SDL_Texture?) {
    verify(renderer != null && texture != null, "draw_texture: null handle")
    check_sdl(SDL_RenderTexture(renderer, texture, null, null), "SDL_RenderTexture")
}

// One rectangle: whole source scaled to destination. Two: source crop + destination.
def public draw_texture(renderer : SDL_Renderer?; texture : SDL_Texture?; dst : SDL_FRect) {
    verify(renderer != null && texture != null, "draw_texture: null handle")
    check_sdl(SDL_RenderTextureToRect(renderer, texture, dst), "SDL_RenderTexture")
}

def public draw_texture(renderer : SDL_Renderer?; texture : SDL_Texture?;
                        src, dst : SDL_FRect) {
    verify(renderer != null && texture != null, "draw_texture: null handle")
    check_sdl(SDL_RenderTextureRects(renderer, texture, src, dst), "SDL_RenderTexture")
}

def public with_bmp(path : string; blk : block<(surface : SDL_Surface?) : void>) {
    var surface = load_bmp(path)
    var failed = false
    var error = ""
    try { SDL_InvokeSurface(blk, surface) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    destroy_surface(surface)
    if (failed) { panic(error) }
}

// Release the temporary CPU surface before returning the owned GPU texture.
def public load_texture(renderer : SDL_Renderer?; path : string) {
    var texture : SDL_Texture?
    with_bmp(path) $(surface) {
        texture = create_texture(renderer, surface)
    }
    return texture
}

def public with_texture(renderer : SDL_Renderer?; path : string;
                        blk : block<(texture : SDL_Texture?) : void>) {
    var texture = load_texture(renderer, path)
    var failed = false
    var error = ""
    try { SDL_InvokeTexture(blk, texture) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    destroy_texture(texture)
    if (failed) { panic(error) }
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
    verify(window != null, "should_close: null window")
    if (SDL_EventIsQuit(event)) { return true }
    return (input_window_id(event) == SDL_GetWindowID(window) &&
           (SDL_EventIsEscape(event) || event.event_type == SDL_EVENT_WINDOW_CLOSE_REQUESTED))
}
def public set_title(window : SDL_Window?; title : string) {
    verify(window != null, "set_title: null window")
    check_sdl(SDL_SetWindowTitle(window, title), "SDL_SetWindowTitle")
}

// Preserve an already-active session. Do not start/stop input manually in the block.
def public with_text_input(window : SDL_Window?; blk : block<() : void>) {
    verify(window != null, "with_text_input: null window")
    let owned = !SDL_TextInputActive(window)
    if (owned) { check_sdl(SDL_StartTextInput(window), "SDL_StartTextInput") }
    var failed = false
    var error = ""
    try { SDL_InvokeScope(blk) } recover {
        failed = true
        error := rtrim(this_context().last_exception)
    }
    let stopped = owned ? SDL_StopTextInput(window) : true
    if (failed) { panic(error) }
    check_sdl(stopped, "SDL_StopTextInput")
}
