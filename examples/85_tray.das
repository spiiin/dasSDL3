options gen2
require dassdl3/sdl3_platform_services
require dassdl3/sdl3_scope

[export]
def main(smoke : bool) : int {
    let result=sdl_scope() {
        with_sdl() |> sdl_use
        let tray : SDL_Tray? = with_tray(null,"dasSDL3 tray example") |> sdl_use
        let menu=create_tray_menu(tray) |> sdl_try
        let checked=insert_tray_entry(menu,-1,"Example checkbox",SDL_TRAYENTRY_CHECKBOX) |> sdl_try
        SDL_SetTrayEntryChecked(checked,true)
        let group=insert_tray_entry(menu,-1,"More",SDL_TRAYENTRY_SUBMENU) |> sdl_try
        let submenu=create_tray_submenu(group) |> sdl_try
        insert_tray_entry(submenu,-1,"Native callbacks only",SDL_TRAYENTRY_BUTTON | SDL_TRAYENTRY_DISABLED) |> sdl_try
        let until=SDL_GetTicks()+(smoke ? 1ul : 5000ul)
        while(SDL_GetTicks()<until) {SDL_PumpEvents();SDL_UpdateTrays();SDL_Delay(16u)}
        print("Tray checkbox: {SDL_GetTrayEntryChecked(checked)}\n")
        return sdl_ok()
    }
    if(is_err(result)) {let error=unwrap_err(result);print("{error.operation}: {error.message}\n");return 1}
    return 0
}
