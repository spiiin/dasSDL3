options gen2
require dassdl3/sdl3_properties_boost
[export]
def main(smoke : bool) : int {
    var result=1
    let initialized=with_sdl(0u) {
        let owned=with_properties() $(props) {
            if(!SDL_SetStringProperty(props,"title","SDL / daslang")) { return }
            if(!SDL_SetNumberProperty(props,"width",800l)) { return }
            if(!SDL_SetBooleanProperty(props,"resizable",true)) { return }
            var names : array<string>
            if(!property_names(props,names)) { return }
            let title=property_string(props,"title")
            let width=SDL_GetNumberProperty(props,"width",0l)
            print("{title}: {width}\n")
            for(name in names) { print("property: {name}\n") }
            result=0
        }
        if(!owned) { result=1 }
    }
    if(!initialized || result!=0) { print("Properties failed: {SDL_GetError()}\n");return 1 }
    return 0
}
