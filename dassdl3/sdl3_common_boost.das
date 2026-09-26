options gen2
module sdl3_common_boost shared public
require dassdl3/sdl3_result public
require daslib/option public

def public platform_name() {return SDL_GetPlatform()}
def public sdl_revision() {return SDL_GetRevision()}
// Preserve SDL's permissive, non-error parsing (zero padding/truncation).
def public guid_from_string(text : string) {return SDL_StringToGUIDText(text)}
def public guid_string(guid : SDL_GUID) {return SDL_GUIDString(guid)}
def public open_url(url : string) {return sdl_status(SDL_OpenURLText(url),"SDL_OpenURL")}
def public show_simple_message_box(flags : uint; title,message : string; window : SDL_Window? = null) {
    return sdl_status(SDL_ShowSimpleMessageBox(flags,title,message,window),"SDL_ShowSimpleMessageBox")
}
def private message_box_result(success : bool; selected : int) {
    if(!success) {return err(sdl_error("SDL_ShowMessageBox"),type<$Option<int>>)}
    return ok(selected == -1 ? none(type<int>) : some(selected),type<SdlError>)
}
def public show_message_box(flags : uint; title,message : string; buttons : array<SDL_MessageBoxButtonData>; window : SDL_Window? = null) {
    var selected=-1
    let success=SDL_ShowMessageBoxArray(flags,title,message,buttons,window,null,selected)
    return message_box_result(success,selected)
}
def public show_message_box(flags : uint; title,message : string; buttons : array<SDL_MessageBoxButtonData>; colors : SDL_MessageBoxColorScheme; window : SDL_Window? = null) {
    var selected=-1
    let success=SDL_ShowMessageBoxColors(flags,title,message,buttons,window,colors,selected)
    return message_box_result(success,selected)
}
