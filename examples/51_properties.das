options gen2
require dassdl3/sdl3_scope
require dassdl3/sdl3_properties_boost
[export]
def main(smoke : bool) : int {
    var result=1
    let initialized=sdl_scope() {
        with_sdl(0u) |> sdl_use
        let props : uint = with_properties() |> sdl_use
        if(!SDL_SetStringProperty(props,"title","SDL / daslang")) {return err(sdl_error("51_properties"),type<SdlUnit>)}
        if(!SDL_SetNumberProperty(props,"width",800l)) {return err(sdl_error("51_properties"),type<SdlUnit>)}
        if(!SDL_SetBooleanProperty(props,"resizable",true)) {return err(sdl_error("51_properties"),type<SdlUnit>)}
        var names : array<string>
        property_names(props,names) |> sdl_try
        let title=property_string(props,"title") |> sdl_try
        let width=SDL_GetNumberProperty(props,"width",0l)
        print("{title}: {width}\n")
        for(name in names) { print("property: {name}\n") }
        result=0

        return sdl_ok()
    }
    if(!is_ok(initialized) || result!=0) { print("Properties failed: {is_err(initialized) ? unwrap_err(initialized).message : SDL_GetErrorCopy()}\n");return 1 }
    return 0
}
