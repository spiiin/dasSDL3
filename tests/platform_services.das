options gen2
require dassdl3/sdl3_platform_services
require dassdl3/sdl3_scope
require daslib/safe_addr

def system_queries {
    var seconds=-1;var percent=-1
    let state=SDL_GetPowerInfo(safe_addr(seconds),safe_addr(percent))
    verify(seconds>=-1 && percent>=-1 && percent<=100)
    var power <- power_info()
    if(is_ok(power)) {verify(unwrap(power).state!=SDL_PowerState.POWERSTATE_ERROR)}
    SDL_IsTablet();SDL_IsTV();SDL_GetSandbox()
    verify(SDL_SetHint("SDL_PREFERRED_LOCALES","en_US,fr"))
    var count=0
    let raw=SDL_GetPreferredLocales(safe_addr(count))
    verify(raw!=null && count==2);SDL_free(raw)
    var copied <- preferred_locales()
    verify(is_ok(copied));var locales <- move_unwrap(copied)
    SDL_ResetHint("SDL_PREFERRED_LOCALES")
    verify(length(locales)==2 && locales[0].language=="en" && locales[0].country=="US" && locales[1].language=="fr")
    var adapter=0;var output=0
    verify(SDL_GetDirect3D9AdapterIndex(0u)==-1)
    verify(!SDL_GetDXGIOutputInfo(0u,safe_addr(adapter),safe_addr(output)))
    var bad <- dxgi_output(0u);verify(is_err(bad))
    let display=SDL_GetPrimaryDisplay()
    verify(display!=0u)
    let dx9=SDL_GetDirect3D9AdapterIndex(display)
    let dxgi=SDL_GetDXGIOutputInfo(display,safe_addr(adapter),safe_addr(output))
    if(dxgi) {verify(adapter>=0 && output>=0)}
    if(dx9<0) {verify(SDL_GetError()!="")}
    SDL_SetWindowsMessageHook(SDLTestPlatformCallback(0),null)
    SDL_PumpEvents()
    verify(SDLTestPlatformPost())
    SDL_PumpEvents()
    SDL_SetWindowsMessageHook(null,null)
    verify(SDLTestPlatformCount(0)==1)
    SDL_SetX11EventHook(null,null) // Compiled Windows stub, not positive X11 validation.
    verify(SDL_AddEventWatch(SDLTestPlatformCallback(3),null))
    SDL_OnApplicationDidReceiveMemoryWarning()
    SDL_OnApplicationWillEnterBackground();SDL_OnApplicationDidEnterBackground()
    SDL_OnApplicationWillEnterForeground();SDL_OnApplicationDidEnterForeground()
    SDL_OnApplicationWillTerminate()
    SDL_RemoveEventWatch(SDLTestPlatformCallback(3),null)
    verify(SDLTestPlatformCount(3)==63)
    verify(!SDL_HasEvent(SDL_EVENT_LOW_MEMORY) && !SDL_HasEvent(SDL_EVENT_TERMINATING))
}
def dialogs {
    // Invalid filters take a synchronous native callback path without opening UI.
    var filter=SDL_MakeDialogFileFilter("Invalid","?")
    SDL_ShowOpenFileDialog(SDLTestPlatformCallback(2),null,null,safe_addr(filter),1,"",false)
    SDL_ShowSaveFileDialog(SDLTestPlatformCallback(2),null,null,safe_addr(filter),1,"")
    let props=SDL_CreateProperties()
    verify(SDL_SetPointerProperty(props,"SDL.filedialog.filters",safe_addr(filter)))
    verify(SDL_SetNumberProperty(props,"SDL.filedialog.nfilters",1l))
    SDL_ShowFileDialogWithProperties(SDL_FileDialogType.FILEDIALOG_OPENFILE,SDLTestPlatformCallback(2),null,props)
    SDL_DestroyProperties(props)
    verify(SDLTestPlatformCount(2)==3)
    SDL_ShowOpenFolderDialog(null,null,null,"",false) // Null callback is SDL's no-op path.
}
def trays {
    let tray=SDL_CreateTray(null,"dasSDL3 native tray test")
    verify(tray!=null)
    SDL_SetTrayIcon(tray,null);SDL_SetTrayTooltip(tray,"Updated tooltip")
    let menu=SDL_CreateTrayMenu(tray)
    verify(menu!=null && SDL_GetTrayMenu(tray)==menu)
    let entry=SDL_InsertTrayEntryAt(menu,-1,"Check",SDL_TRAYENTRY_CHECKBOX)
    let parent=SDL_InsertTrayEntryAt(menu,-1,"More",SDL_TRAYENTRY_SUBMENU)
    verify(entry!=null && parent!=null)
    let submenu=SDL_CreateTraySubmenu(parent)
    verify(submenu!=null && SDL_GetTraySubmenu(parent)==submenu)
    verify(SDL_GetTrayEntryParent(entry)==menu)
    verify(SDL_GetTrayMenuParentEntry(submenu)==parent && SDL_GetTrayMenuParentTray(menu)==tray)
    var count=0
    let entries=SDL_GetTrayEntries(menu,safe_addr(count))
    verify(entries!=null && count==2)
    SDL_SetTrayEntryLabel(entry,"Renamed")
    verify(SDL_GetTrayEntryLabel(entry)=="Renamed")
    var text_label <- tray_entry_label(entry);verify(is_ok(text_label))
    SDL_SetTrayEntryLabel(entry,"Later")
    verify(unwrap(text_label)=="Renamed")
    SDL_SetTrayEntryChecked(entry,true);verify(SDL_GetTrayEntryChecked(entry))
    SDL_SetTrayEntryEnabled(entry,false);verify(!SDL_GetTrayEntryEnabled(entry))
    SDL_SetTrayEntryEnabled(entry,true)
    SDL_SetTrayEntryCallback(entry,SDLTestPlatformCallback(1),null)
    SDL_ClickTrayEntry(entry)
    verify(SDLTestPlatformCount(1)==1 && !SDL_GetTrayEntryChecked(entry))
    SDL_SetTrayEntryCallback(entry,null,null)
    SDL_ClickTrayEntry(entry);verify(SDLTestPlatformCount(1)==1)
    SDL_RemoveTrayEntry(entry)
    var list <- tray_entries(menu);verify(is_ok(list))
    var values <- move_unwrap(list);verify(length(values)==1 && values[0]==parent)
    SDL_UpdateTrays();SDL_DestroyTray(tray)
    var scoped <- with_tray(null,"Scoped tray test") $(value : SDL_Tray?) {
        var menu_result <- create_tray_menu(value);verify(is_ok(menu_result))
        let child_menu=move_unwrap(menu_result)
        var empty <- tray_entries(child_menu);verify(is_ok(empty))
        var child <- insert_tray_entry(child_menu,-1,"Submenu",SDL_TRAYENTRY_SUBMENU)
        verify(is_ok(child));var sub <- create_tray_submenu(move_unwrap(child));verify(is_ok(sub))
        return err(SdlError(operation="tray body",message="preserved"),type<SdlUnit>)
    }
    verify(is_err(scoped) && unwrap_err(scoped).operation=="tray body")
    var created <- create_tray(null,"");verify(is_ok(created))
    var owned=move_unwrap(created);destroy_tray(owned);verify(owned==null)
}
[export]
def main(smoke : bool) : int {
    SDLTestPlatformReset()
    verify(SDL_Init(SDL_INIT_VIDEO))
    system_queries();dialogs();trays()
    SDL_Quit()
    print("System, Power, Locale, Dialog and Tray contracts passed.\n")
    return 0
}
