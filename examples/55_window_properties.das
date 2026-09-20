options gen2
require dassdl3/sdl3_window_boost
require dassdl3/sdl3_properties_boost
[export]
def main(smoke : bool) : int {
    var ok=false
    let initialized=with_sdl() {
        let properties=with_properties() $(props : uint) {
            if(!SDL_SetStringProperty(props,"SDL.window.create.title","Window properties") ||
               !SDL_SetNumberProperty(props,"SDL.window.create.width",320l) ||
               !SDL_SetNumberProperty(props,"SDL.window.create.height",240l) ||
               !SDL_SetBooleanProperty(props,"SDL.window.create.hidden",true)) {return sdl_ok()}
            let owner=with_window_properties(props) $(window : SDL_Window?) {
                if(!SDL_SetWindowResizable(window,true)) {return err(sdl_error("55_window_properties"),type<SdlUnit>)}
                ok=with_popup_window(window,10,10,100,40,SDL_WINDOW_TOOLTIP|SDL_WINDOW_HIDDEN) $(popup : SDL_Window?) {
                    let title=unwrap_or(window_title(window), "")
                    print("{title}: popup created; child cleanup runs before parent cleanup\n")

                    return sdl_ok()
                } |> is_ok

                return sdl_ok()
            }
            if (is_err(owner)) {print("{unwrap_err(owner).message}\n"); return err(unwrap_err(owner),type<SdlUnit>) }

            return sdl_ok()
        }
        if (is_err(properties)) {print("{unwrap_err(properties).message}\n"); return err(unwrap_err(properties),type<SdlUnit>) }

        return sdl_ok()
    }
    return is_ok(initialized) && ok ? 0 : 1
}
