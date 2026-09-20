options gen2
require dassdl3/sdl3_properties_boost
[export]
def main(smoke : bool) : int {
    var result=1
    let initialized=with_sdl(0u) {
        let owned=with_properties() $(props : uint) {
            if(!SDL_SetStringProperty(props,"title","SDL / daslang")) {return err(sdl_error("51_properties"),type<SdlUnit>)}
            if(!SDL_SetNumberProperty(props,"width",800l)) {return err(sdl_error("51_properties"),type<SdlUnit>)}
            if(!SDL_SetBooleanProperty(props,"resizable",true)) {return err(sdl_error("51_properties"),type<SdlUnit>)}
            var names : array<string>
            var operation_result_1 <- property_names(props,names)
            if (is_err(operation_result_1)) { return err(unwrap_err(operation_result_1),type<SdlUnit>) }
            let title=unwrap_or(property_string(props,"title"), "")
            let width=SDL_GetNumberProperty(props,"width",0l)
            print("{title}: {width}\n")
            for(name in names) { print("property: {name}\n") }
            result=0

            return sdl_ok()
        }
        if (is_err(owned)) { result=1 ; return err(unwrap_err(owned),type<SdlUnit>) }

        return sdl_ok()
    }
    if(!is_ok(initialized) || result!=0) { print("Properties failed: {is_err(initialized) ? unwrap_err(initialized).message : SDL_GetErrorCopy()}\n");return 1 }
    return 0
}
