options gen2
require dassdl3/sdl3_window_boost
require dassdl3/sdl3_properties_boost
[export]
def main(smoke : bool) : int {
    var ok=false
    let initialized=with_sdl() {
        let properties=with_properties() $(props) {
            if(!SDL_SetStringProperty(props,"SDL.window.create.title","Window properties") ||
               !SDL_SetNumberProperty(props,"SDL.window.create.width",320l) ||
               !SDL_SetNumberProperty(props,"SDL.window.create.height",240l) ||
               !SDL_SetBooleanProperty(props,"SDL.window.create.hidden",true)) {return}
            let owner=with_window_properties(props) $(window) {
                if(!SDL_SetWindowResizable(window,true)) {return}
                ok=with_popup_window(window,10,10,100,40,SDL_WINDOW_TOOLTIP|SDL_WINDOW_HIDDEN) $(popup) {
                    let title=window_title(window)
                    print("{title}: popup created; child cleanup runs before parent cleanup\n")
                }
            }
            if(!owner) {print("{SDL_GetError()}\n")}
        }
        if(!properties) {print("{SDL_GetError()}\n")}
    }
    return initialized && ok ? 0 : 1
}
