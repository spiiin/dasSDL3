options gen2
module sdl3_filesystem_boost shared public
require dassdl3/sdl3_result public

def public base_path() {
    let value = SDL_GetBasePathCopy()
    if (length(value) == 0) { return err(sdl_error("SDL_GetBasePath"),type<string>) }
    return ok(value,type<SdlError>)
}
def public pref_path(org,app : string) {
    let value = SDL_GetPrefPathCopy(org,app)
    if (length(value) == 0) { return err(sdl_error("SDL_GetPrefPath"),type<string>) }
    return ok(value,type<SdlError>)
}
def public user_folder(folder : SDL_Folder) {
    let value = SDL_GetUserFolderCopy(folder)
    if (length(value) == 0) { return err(sdl_error("SDL_GetUserFolder"),type<string>) }
    return ok(value,type<SdlError>)
}
def public current_directory() {
    let value = SDL_GetCurrentDirectoryCopy()
    if (length(value) == 0) { return err(sdl_error("SDL_GetCurrentDirectory"),type<string>) }
    return ok(value,type<SdlError>)
}
def public create_directory(path : string) { return sdl_status(SDL_CreateDirectory(path),"SDL_CreateDirectory") }
def public remove_path(path : string) { return sdl_status(SDL_RemovePath(path),"SDL_RemovePath") }
def public rename_path(oldpath,newpath : string) { return sdl_status(SDL_RenamePath(oldpath,newpath),"SDL_RenamePath") }
def public copy_file(oldpath,newpath : string) { return sdl_status(SDL_CopyFile(oldpath,newpath),"SDL_CopyFile") }
def public path_info(path : string) {
    var value : SDL_PathInfo
    if (!SDL_GetPathInfoRef(path,value)) { return err(sdl_error("SDL_GetPathInfo"),type<SDL_PathInfo>) }
    return ok(value,type<SdlError>)
}
def public glob_directory(path : string; pattern : string = "*"; flags : uint = 0u) {
    var values : array<string>
    if (!SDL_GlobDirectoryCopy(path,pattern,flags,values)) { return err(sdl_error("SDL_GlobDirectory"),type<array<string>>) }
    return <- move_ok(values,type<SdlError>)
}
def public enumerate_directory(path : string) {
    var values : array<string>
    if (!SDL_EnumerateDirectoryCopy(path,values)) { return err(sdl_error("SDL_EnumerateDirectory"),type<array<string>>) }
    return <- move_ok(values,type<SdlError>)
}
