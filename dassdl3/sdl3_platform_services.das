options gen2
module sdl3_platform_services shared public
require dassdl3/sdl3_boost public
require daslib/defer

struct public SdlPowerInfo {
    state : SDL_PowerState
    seconds : $Option<int>
    percent : $Option<int>
}
def public power_info() {
    var seconds = -1; var percent = -1
    let state = SDL_GetPowerInfoRef(seconds, percent)
    if (state == SDL_PowerState.POWERSTATE_ERROR) {return err(sdl_error("SDL_GetPowerInfo"), type<SdlPowerInfo>)}
    return ok(SdlPowerInfo(state = state, seconds = seconds < 0 ? none(type<int>) : some(seconds), percent = percent < 0 ? none(type<int>) : some(percent)), type<SdlError>)
}
// Array and strings own their copied storage. A null country remains null.
def public preferred_locales() {
    var locales : array<SDL_Locale>
    if (!SDL_GetPreferredLocalesCopy(locales)) {return err(sdl_error("SDL_GetPreferredLocales"), type<array<SDL_Locale>>)}
    return <- move_ok(locales, type<SdlError>)
}
def public dxgi_output(display : uint) {
    var adapter = 0; var output = 0
    if (!SDL_GetDXGIOutputInfoRef(display, adapter, output)) {return err(sdl_error("SDL_GetDXGIOutputInfo"), type<int2>)}
    return ok(int2(adapter, output), type<SdlError>)
}
def public create_tray(icon : SDL_Surface?; tooltip : string) {
    var value = SDL_CreateTrayText(icon, tooltip)
    if (value == null) {return err(sdl_error("SDL_CreateTray"), type<SDL_Tray?>)}
    return <- move_ok(value, type<SdlError>)
}
def public destroy_tray(var tray : SDL_Tray?&) {SDL_DestroyTray(tray); tray = null}
def public with_tray(icon : SDL_Surface?; tooltip : string; blk : block<(tray : SDL_Tray?) : $Result<auto(T); SdlError>>) {
    let tray = SDL_CreateTrayText(icon, tooltip)
    if (tray == null) {return err(sdl_error("SDL_CreateTray"), type<T>)}
    var result : $Result<T; SdlError>
    {
        defer() {SDL_DestroyTray(tray)}
        static_if (typeinfo can_copy(type<$Result<T; SdlError>>)) {result = blk(tray)} else {result <- blk(tray)}
    }
    return <- result
}
// Returned child is owned by its tray/menu.
def public create_tray_menu(tray : SDL_Tray?) {
    var value = SDL_CreateTrayMenu(tray)
    if (value == null) {return err(sdl_error("SDL_CreateTrayMenu"), type<SDL_TrayMenu?>)}
    return <- move_ok(value, type<SdlError>)
}
// Returned child is owned by its tray/menu.
def public create_tray_submenu(entry : SDL_TrayEntry?) {
    var value = SDL_CreateTraySubmenu(entry)
    if (value == null) {return err(sdl_error("SDL_CreateTraySubmenu"), type<SDL_TrayMenu?>)}
    return <- move_ok(value, type<SdlError>)
}
// Returned child is owned by its tray/menu.
def public insert_tray_entry(menu : SDL_TrayMenu?; pos : int; text_label : string; flags : uint) {
    var value = SDL_InsertTrayEntryAt(menu, pos, text_label, flags)
    if (value == null) {return err(sdl_error("SDL_InsertTrayEntryAt"), type<SDL_TrayEntry?>)}
    return <- move_ok(value, type<SdlError>)
}
// Copies only the list; entries remain borrowed until removal/tray destruction.
def public tray_entries(menu : SDL_TrayMenu?) {
    var entries : array<SDL_TrayEntry?>
    if (!SDL_GetTrayEntriesCopy(menu, entries)) {return err(sdl_error("SDL_GetTrayEntries"), type<array<SDL_TrayEntry?>>)}
    return <- move_ok(entries, type<SdlError>)
}
def public tray_entry_label(entry : SDL_TrayEntry?) {
    if (entry == null) {return err(SdlError(operation = "SDL_GetTrayEntryLabel", message = "Null tray entry"), type<string>)}
    return ok(SDL_GetTrayEntryLabelCopy(entry), type<SdlError>)
}
