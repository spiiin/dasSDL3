options gen2
require dassdl3/sdl3_keyboard_mouse_boost
require dassdl3/sdl3_scope
require daslib/defer

def test_input(window : SDL_Window?) {
    let ids <- keyboards() |> sdl_try
    let mouse_ids <- mice() |> sdl_try
    for (id in ids) { keyboard_name(id) |> sdl_try }
    for (id in mouse_ids) { mouse_name(id) |> sdl_try }
    unsafe {
        var count : int
        let list = SDL_GetKeyboards(addr(count))
        verify(list != null && count == length(ids)); SDL_free(list)
        let mice_list = SDL_GetMice(addr(count))
        verify(mice_list != null && count == length(mouse_ids)); SDL_free(mice_list)
        let keys = SDL_GetKeyboardState(addr(count))
        verify(keys != null && count == int(SDL_Scancode.SCANCODE_COUNT))
    }
    let snapshot <- keyboard_state()
    verify(length(snapshot) == int(SDL_Scancode.SCANCODE_COUNT))
    let has_keyboard = SDL_HasKeyboard(); let has_mouse = SDL_HasMouse()
    verify(has_keyboard == (length(ids)>0) && has_mouse == (length(mouse_ids)>0))
    verify(SDL_GetKeyboardNameForID(0u)=="" && SDL_GetMouseNameForID(0u)=="")
    verify(is_err(keyboard_name(0u)) && is_err(mouse_name(0u)))
    var key_focus = SDL_GetKeyboardFocus(); var pointer_focus = SDL_GetMouseFocus()
    var key_option <- keyboard_focus(); var mouse_option <- mouse_focus()
    verify(is_some(key_option)==(key_focus!=null) && is_some(mouse_option)==(pointer_focus!=null))
    let mods=SDL_GetModState()
    {
        defer() { SDL_SetModState(uint(mods)) }
        SDL_SetModState(SDL_KMOD_SHIFT)
        verify(uint(SDL_GetModState())==SDL_KMOD_SHIFT)
        SDL_SetModState(0u)
        SDL_ResetKeyboard()
        verify(SDL_GetKeyFromScancode(SDL_Scancode.SCANCODE_RETURN,0u,false)==SDLK_RETURN)
        var inferred : uint
        var raw_mods : uint16
        unsafe { verify(SDL_GetScancodeFromKey(SDLK_RETURN,addr(raw_mods))==SDL_Scancode.SCANCODE_RETURN) }
        verify(scancode_from_key(SDLK_RETURN,inferred)==SDL_Scancode.SCANCODE_RETURN)
        verify(SDL_GetScancodeFromName("A")==SDL_Scancode.SCANCODE_A)
        verify(SDL_GetKeyFromName("A")==SDLK_A)
        // Reuse SDL's permanent built-in name; never lend a temporary string.
        let original=SDL_GetScancodeName(SDL_Scancode.SCANCODE_A)
        verify(SDL_SetScancodeName(SDL_Scancode.SCANCODE_A,original))
        verify(SDL_GetKeyName(SDLK_A)=="A" && key_name(SDLK_A)=="A")
        let saved_name=scancode_name(SDL_Scancode.SCANCODE_A)
        let other=key_name(SDLK_B)
        verify(saved_name=="A" && other=="B")
    }
    var x,y : float
    unsafe {
        SDL_GetMouseState(addr(x),addr(y))
        SDL_GetGlobalMouseState(addr(x),addr(y))
        SDL_GetRelativeMouseState(addr(x),addr(y))
    }
    var position,delta : float2
    global_mouse_state(position); relative_mouse_state(delta); mouse_state(position)
    // No desktop movement: warp globally to the current global coordinates.
    global_mouse_state(position)
    let warped=SDL_WarpMouseGlobal(position.x,position.y)
    var wx,wy : int
    verify(SDL_GetWindowPositionRef(window,wx,wy))
    SDL_WarpMouseInWindow(window,position.x-float(wx),position.y-float(wy))
    let warp_result=warp_mouse_global(position)
    verify(is_ok(warp_result)==warped)
    let relative=SDL_GetWindowRelativeMouseMode(window)
    verify(SDL_SetWindowRelativeMouseMode(window,false))
    verify(!SDL_GetWindowRelativeMouseMode(window))
    set_relative_mouse_mode(window,false) |> sdl_try
    let captured=SDL_CaptureMouse(false)
    let capture_result=capture_mouse(false)
    verify(is_ok(capture_result)==captured)
    let visible=SDL_CursorVisible()
    {
        defer() { if (visible) { SDL_ShowCursor() } else { SDL_HideCursor() } }
        verify(SDL_HideCursor() && !SDL_CursorVisible())
        hide_cursor() |> sdl_try
        show_cursor() |> sdl_try
        verify(SDL_ShowCursor() && SDL_CursorVisible())
    }
    var rect=SDL_Rect(x=2,y=3,w=40,h=20); var found=SDL_Rect();var caret : int
    unsafe {
        verify(SDL_SetTextInputArea(window,addr(rect),7))
        verify(SDL_GetTextInputArea(window,addr(found),addr(caret)))
    }
    verify(found.x==2 && found.y==3 && found.w==40 && found.h==20 && caret==7)
    set_text_input_area(window,rect,5) |> sdl_try
    text_input_area(window,found,caret) |> sdl_try
    verify(caret==5)
    verify(is_err(text_input_area(null,found,caret)) && caret==0 && found.w==0)
    let props=SDL_CreateProperties();verify(props!=0u)
    {
        defer() { SDL_DestroyProperties(props) }
        verify(SDL_SetNumberProperty(props,"SDL.textinput.type",int64(SDL_TextInputType.TEXTINPUT_TYPE_TEXT)))
        verify(SDL_StartTextInputWithProperties(window,props))
        verify(SDL_TextInputActive(window))
        with_text_input_properties(window,props) { return sdl_ok() } |> sdl_try
        verify(SDL_TextInputActive(window))
        SDL_ClearComposition(window)
        verify(SDL_StopTextInput(window))
        with_text_input_properties(window,props) { verify(SDL_TextInputActive(window));return sdl_ok() } |> sdl_try
        verify(!SDL_TextInputActive(window))
        let body_error=with_text_input_properties(window,props) { return err(SdlError(operation="body",message="primary"),type<SdlUnit>) }
        verify(is_err(body_error) && !SDL_TextInputActive(window))
    }
    let screen_supported=SDL_HasScreenKeyboardSupport();let screen_shown=SDL_ScreenKeyboardShown(window)
    verify(!screen_shown || screen_supported)
    return sdl_ok()
}

def test_cursors(window : SDL_Window?) {
    var previous=SDL_GetCursor();var fallback=SDL_GetDefaultCursor()
    var current <- current_cursor(); var default_value <- default_cursor()
    verify(is_some(current)==(previous!=null) && is_some(default_value)==(fallback!=null))
    var bits : array<uint8>;var mask : array<uint8>;resize(bits,8);resize(mask,8)
    for (i in 0 .. 8) { bits[i]=uint8(0);mask[i]=uint8(255) }
    var invalid : array<uint8>
    verify(is_err(create_cursor(invalid,invalid,8,8,0,0)))
    verify(is_err(create_cursor(bits,mask,7,8,0,0)))
    verify(is_err(create_cursor(bits,mask,8,8,8,0)))
    let native_driver=SDL_GetCurrentVideoDriver()!="dummy"
    var mono : SDL_Cursor?
    unsafe { mono=SDL_CreateCursor(addr(bits[0]),addr(mask[0]),8,8,0,0) }
    if (native_driver) { verify(mono!=null) }
    if (mono!=null) {
        defer() { SDL_DestroyCursor(mono) }
        verify(SDL_SetCursor(mono) && SDL_GetCursor()==mono)
        verify(SDL_SetCursor(previous))
    }
    let surface=SDL_CreateSurface(8,8,SDL_PixelFormat.PIXELFORMAT_RGBA32);verify(surface!=null)
    {
        defer() { SDL_DestroySurface(surface) }
        let color=SDL_CreateColorCursor(surface,0,0)
        if (native_driver) { verify(color!=null) }
        SDL_DestroyCursor(color)
        var created_color <- create_color_cursor(surface,0,0)
        if (is_ok(created_color)) { let cursor=move_unwrap(created_color);SDL_DestroyCursor(cursor) }
        let scoped=with_color_cursor(surface,0,0) $(cursor : SDL_Cursor?) { verify(cursor!=null);return sdl_ok() }
        if (native_driver) { verify(is_ok(scoped)) }
    }
    let system=SDL_CreateSystemCursor(SDL_SystemCursor.SYSTEM_CURSOR_DEFAULT)
    if (native_driver) { verify(system!=null) }
    SDL_DestroyCursor(system)
    let owned=with_system_cursor(SDL_SystemCursor.SYSTEM_CURSOR_CROSSHAIR) $(cursor : SDL_Cursor?) {
        set_cursor(cursor) |> sdl_try
        set_cursor(previous) |> sdl_try
        return err(SdlError(operation="body",message="cursor scope"),type<SdlUnit>)
    }
    if (native_driver) { verify(is_err(owned) && unwrap_err(owned).operation=="body") }
    let bitmap=with_cursor(bits,mask,8,8,0,0) $(cursor : SDL_Cursor?) { verify(cursor!=null); return sdl_ok() }
    if (native_driver) { verify(is_ok(bitmap)) }
    var created_bitmap <- create_cursor(bits,mask,8,8,0,0)
    if (is_ok(created_bitmap)) { let cursor=move_unwrap(created_bitmap);SDL_DestroyCursor(cursor) }
    // Factories transfer ownership; clean up after successful pointer extraction.
    var created <- create_system_cursor(SDL_SystemCursor.SYSTEM_CURSOR_DEFAULT)
    if (is_ok(created)) { let cursor=move_unwrap(created); SDL_DestroyCursor(cursor) }
    return sdl_ok()
}

[export]
def main(smoke : bool) : int {
    let result=sdl_scope() {
        with_sdl() |> sdl_use
        let window : SDL_Window?=with_window("Keyboard/mouse tests",64,64,SDL_WINDOW_HIDDEN) |> sdl_use
        test_input(window) |> sdl_try
        test_cursors(window) |> sdl_try
        return sdl_ok()
    }
    if (is_err(result)) { let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1 }
    print("Keyboard/mouse raw functions, copied queries, text input and cursors passed\n")
    return 0
}
