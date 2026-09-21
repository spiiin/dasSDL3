options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_window_boost
require dassdl3/sdl3_properties_boost
def show_popup(window : SDL_Window?) : $Result<SdlUnit; SdlError> {
    if(!SDL_SetWindowResizable(window,true)) {return err(sdl_error("55_window_properties"),type<SdlUnit>)}
    return sdl_scope() {
        let popup : SDL_Window? = with_popup_window(window,10,10,100,40,SDL_WINDOW_TOOLTIP|SDL_WINDOW_HIDDEN) |> sdl_use
        let title=window_title(window) |> sdl_try
        print("{title}: popup created; child cleanup runs before parent cleanup\n")

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let initialized=sdl_scope() {
        with_sdl() |> sdl_use
        let props : uint = with_properties() |> sdl_use
        if(!SDL_SetStringProperty(props,"SDL.window.create.title","Window properties") ||
           !SDL_SetNumberProperty(props,"SDL.window.create.width",320l) ||
           !SDL_SetNumberProperty(props,"SDL.window.create.height",240l) ||
           !SDL_SetBooleanProperty(props,"SDL.window.create.hidden",true)) {return err(sdl_error("window properties"),type<SdlUnit>)}
        let window : SDL_Window? = with_window_properties(props) |> sdl_use
        return show_popup(window)
    }
    if(is_err(initialized)) {
        let error=unwrap_err(initialized)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
