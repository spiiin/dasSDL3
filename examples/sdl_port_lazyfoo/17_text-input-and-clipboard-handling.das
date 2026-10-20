options gen2
require ./common/demo_support.das
require dassdl3/sdl3_rect_clipboard_boost
require ./common/text_editing.das
// Independent dasSDL3 example for the topic of:
// https://lazyfoo.net/tutorials/SDL3/17-text-input-and-clipboard-handling/index.php
[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl(SDL_INIT_VIDEO) |> sdl_use
        let window : SDL_Window? = with_window("17 text input and clipboard handling",640,480,smoke ? SDL_WINDOW_HIDDEN : 0ul) |> sdl_use
        let renderer : SDL_Renderer? = window |> with_renderer() |> sdl_use
        with_ttf() |> sdl_use
        let font : TTF_Font? = with_font("{SDL_GetBasePath()}assets/libraries/JetBrainsMono-Regular.ttf",22.0) |> sdl_use
        let engine : TTF_TextEngine? = renderer |> with_renderer_text_engine() |> sdl_use
        let text : TTF_Text? = engine |> with_text(font,"") |> sdl_use
        with_text_input(window) |> sdl_use
        var input=""
        lesson_loop(window,renderer,smoke, $(event) {
            match(event) {
                if(SdlEvent(text_input=$v(typed))) {input="{input}{typed.text}"}
                if(SdlEvent(key_down=$v(key))) {
                    if(key.keycode==SDLK_BACKSPACE && length(input)>0){input=slice(input,0,utf8_previous(input))}
                    if((uint(key.modifiers)&SDL_KMOD_CTRL)!=0u){
                        if(key.keycode==SDLK_C){sdl_status(SDL_SetClipboardText(input),"SDL_SetClipboardText") |> sdl_try}
                        if(key.keycode==SDLK_V){input=clipboard_text() |> sdl_try}
                    }
                }
                if(_) {}
            }
            return sdl_ok()
        }) $(frame,dt) {
            text |> set_text("Type here: {input}
Ctrl+C: copy; Ctrl+V: replace; Backspace: delete") |> sdl_try
            text |> draw_text(20.0,180.0) |> sdl_try
            return sdl_ok()
        } |> sdl_try
        if(smoke){verify(input=="café")}
        return sdl_ok()
    }
    return report(result)
}
