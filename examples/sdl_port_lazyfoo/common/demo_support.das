options gen2
module demo_support shared public
require strings public
require math public
require daslib/defer public
require daslib/match public
require dassdl3/sdl3_init_boost public
require dassdl3/sdl3_scope public
require dassdl3/sdl3_events public
require dassdl3/sdl3_keyboard_mouse_boost public
require dassdl3/sdl3_renderer_operations_boost public
require dassdl3/sdl3_image_boost public
require dassdl3/sdl3_ttf_boost public

def public asset(name : string) : string { return "{SDL_GetBasePath()}assets/lazyfoo/{name}" }
def public report(result : $Result<SdlUnit; SdlError>) : int {
    if (is_err(result)) {
        let error = unwrap_err(result)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    print("Lesson completed; scopes released.\n")
    return 0
}
def public with_keyed_texture(renderer : SDL_Renderer?; surface : SDL_Surface?;
    body : block<(texture : SDL_Texture?) : $Result<auto(T); SdlError>>) {
    var created <- create_texture(renderer,surface)
    if(is_err(created)){return err(unwrap_err(created),type<T>)}
    let texture=move_unwrap(created)
    {
        defer(){SDL_DestroyTexture(texture)}
        return <- invoke(body,texture)
    }
}
def public box(renderer : SDL_Renderer?; x,y,w,h : float; color : uint4) {
    renderer |> set_color(color) |> sdl_try
    renderer |> fill_rect(SDL_FRect(x=x,y=y,w=w,h=h)) |> sdl_try
    return sdl_ok()
}
// Application-only loop: examples own their resources and all lesson behavior.
// Deterministic smoke input traverses the same owned-event handlers as real input.
def public lesson_loop(window : SDL_Window?; renderer : SDL_Renderer?; smoke : bool;
    handle : block<(event : SdlEvent) : $Result<SdlUnit; SdlError>>;
    draw : block<(frame : int; dt : float) : $Result<SdlUnit; SdlError>>) {
    let test_clipboard = smoke && (hint_string("DASSDL3_LAZYFOO_TEST_CLIPBOARD") |> unwrap_or("")) == "1"
    var frame = 0
    var previous = SDL_GetTicksNS()
    while (true) {
        for (event in poll_events()) {
            if (should_close(event,window)) { return sdl_ok() }
            invoke(handle,event) |> sdl_try
        }
        if (smoke) {
            // Space/start, pause, resume, motion, click, UTF-8 input, return/menu.
            let keys = fixed_array<uint>(SDLK_SPACE,SDLK_P,SDLK_P,SDLK_RIGHT,SDLK_DOWN,SDLK_RETURN)
            if (frame < 6) {
                invoke(handle,SdlEvent(key_down=KeyEvent(keycode=keys[frame]))) |> sdl_try
            }
            if (frame == 6) {
                invoke(handle,SdlEvent(mouse_motion=MouseMotionEvent(position=float2(120,130)))) |> sdl_try
                invoke(handle,SdlEvent(mouse_button_down=MouseButtonEvent(position=float2(120,130),button=1u8))) |> sdl_try
                invoke(handle,SdlEvent(text_input=TextInputEvent(text="caf\u00e9"))) |> sdl_try
            }
            if (frame == 7) {
                invoke(handle,SdlEvent(mouse_button_up=MouseButtonEvent(position=float2(120,130),button=1u8))) |> sdl_try
            }
        }
        if (test_clipboard) {
            if(frame==8){invoke(handle,SdlEvent(key_down=KeyEvent(keycode=SDLK_C,modifiers=uint16(SDL_KMOD_CTRL)))) |> sdl_try}
            if(frame==9){invoke(handle,SdlEvent(key_down=KeyEvent(keycode=SDLK_BACKSPACE))) |> sdl_try}
            if(frame==10){invoke(handle,SdlEvent(key_down=KeyEvent(keycode=SDLK_V,modifiers=uint16(SDL_KMOD_CTRL)))) |> sdl_try}
        }
        let now = SDL_GetTicksNS()
        let dt = smoke ? 1.0/60.0 : min(float(now-previous)*1.0e-9,0.1)
        previous = now
        renderer |> clear(uint4(24u,30u,45u,255u)) |> sdl_try
        invoke(draw,frame,dt) |> sdl_try
        if (smoke && frame == 11) {
            let path = hint_string("DASSDL3_LAZYFOO_CAPTURE") |> unwrap_or("")
            if (path != "") {
                renderer |> with_read_pixels(SDL_Rect(w=640,h=480)) $(surface : SDL_Surface?) {
                    return sdl_status(SDL_SaveBMP(surface,path),"SDL_SaveBMP")
                } |> sdl_try
            }
        }
        renderer |> present() |> sdl_try
        frame++
        if (smoke && frame == 12) { print("Frames: {frame}\n"); return sdl_ok() }
        if (!smoke) { SDL_Delay(1u) }
    }
    return sdl_ok()
}
