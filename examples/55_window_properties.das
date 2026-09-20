options gen2
require dassdl3/sdl3_try
require dassdl3/sdl3_window_boost
require dassdl3/sdl3_properties_boost
def show_popup(window : SDL_Window?) : $Result<SdlUnit; SdlError> {
    if(!SDL_SetWindowResizable(window,true)) {return err(sdl_error("55_window_properties"),type<SdlUnit>)}
    return with_popup_window(window,10,10,100,40,SDL_WINDOW_TOOLTIP|SDL_WINDOW_HIDDEN) $(popup : SDL_Window?) {
        let title=window_title(window) |> sdl_try
        print("{title}: popup created; child cleanup runs before parent cleanup\n")

        return sdl_ok()
    }
}

[export]
def main(smoke : bool) : int {
    let initialized=with_sdl() {
        return with_properties() $(props : uint) {
            if(!SDL_SetStringProperty(props,"SDL.window.create.title","Window properties") ||
               !SDL_SetNumberProperty(props,"SDL.window.create.width",320l) ||
               !SDL_SetNumberProperty(props,"SDL.window.create.height",240l) ||
               !SDL_SetBooleanProperty(props,"SDL.window.create.hidden",true)) {return err(sdl_error("window properties"),type<SdlUnit>)}
            return with_window_properties(props) $(window : SDL_Window?) {
                return show_popup(window)
            }
        }
    }
    if(is_err(initialized)) {
        let error=unwrap_err(initialized)
        print("{error.operation}: {error.message}\n")
        return 1
    }
    return 0
}
