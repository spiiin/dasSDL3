options gen2
module sdl3_storage_boost shared public
require dassdl3/sdl3_result public
require daslib/defer
// Readiness is a predicate; false is not inferred to be an SDL error.
def public storage_ready(storage : SDL_Storage?) : bool {return SDL_StorageReady(storage)}
// Zero is ambiguous (no space, unsupported or failure); preserve the raw value.
def public storage_space_remaining(storage : SDL_Storage?) : uint64 {return SDL_GetStorageSpaceRemaining(storage)}
def public close_storage(var storage : SDL_Storage?&) {return sdl_status(SDL_CloseStorageRef(storage), "SDL_CloseStorage")}
def public open_file_storage(path : string) {
    var storage = SDL_OpenFileStorage(path)
    if (storage == null) {return err(sdl_error("SDL_OpenFileStorage"), type<SDL_Storage?>)}
    return <- move_ok(storage, type<SdlError>)
}
def public open_title_storage(path : string; props : uint = 0u) {
    var storage = SDL_OpenTitleStorage(path, props)
    if (storage == null) {return err(sdl_error("SDL_OpenTitleStorage"), type<SDL_Storage?>)}
    return <- move_ok(storage, type<SdlError>)
}
def public open_user_storage(org, app : string; props : uint = 0u) {
    var storage = SDL_OpenUserStorage(org, app, props)
    if (storage == null) {return err(sdl_error("SDL_OpenUserStorage"), type<SDL_Storage?>)}
    return <- move_ok(storage, type<SdlError>)
}
def public open_storage(iface : SDL_StorageInterface; userdata : void?) {
    var storage = SDL_OpenStorageRef(iface, userdata)
    if (storage == null) {return err(sdl_error("SDL_OpenStorageRef"), type<SDL_Storage?>)}
    return <- move_ok(storage, type<SdlError>)
}
def public storage_file_size(storage : SDL_Storage?; path : string) {
    var value : uint64
    if (!SDL_GetStorageFileSizeRef(storage, path, value)) {return err(sdl_error("SDL_GetStorageFileSizeRef"), type<uint64>)}
    return ok(value, type<SdlError>)
}
def public storage_path_info(storage : SDL_Storage?; path : string) {
    var value : SDL_PathInfo
    if (!SDL_GetStoragePathInfoRef(storage, path, value)) {return err(sdl_error("SDL_GetStoragePathInfoRef"), type<SDL_PathInfo>)}
    return ok(value, type<SdlError>)
}
def public read_storage_file(storage : SDL_Storage?; path : string; var bytes : array<uint8>; count : uint64) {return sdl_status(SDL_ReadStorageFileArray(storage, path, bytes, count), "SDL_ReadStorageFileArray")}
def public write_storage_file(storage : SDL_Storage?; path : string; bytes : array<uint8>) {return sdl_status(SDL_WriteStorageFileArray(storage, path, bytes, uint64(length(bytes))), "SDL_WriteStorageFileArray")}
def public create_storage_directory(storage : SDL_Storage?; path : string) {return sdl_status(SDL_CreateStorageDirectory(storage, path), "SDL_CreateStorageDirectory")}
def public remove_storage_path(storage : SDL_Storage?; path : string) {return sdl_status(SDL_RemoveStoragePath(storage, path), "SDL_RemoveStoragePath")}
def public rename_storage_path(storage : SDL_Storage?; oldpath, newpath : string) {return sdl_status(SDL_RenameStoragePath(storage, oldpath, newpath), "SDL_RenameStoragePath")}
def public copy_storage_file(storage : SDL_Storage?; oldpath, newpath : string) {return sdl_status(SDL_CopyStorageFile(storage, oldpath, newpath), "SDL_CopyStorageFile")}
def public load_storage_file(storage : SDL_Storage?; path : string) {
    var values : array<uint8>
    if (!SDL_LoadStorageFileCopy(storage, path, values)) {return err(sdl_error("SDL_LoadStorageFileCopy"), type<array<uint8>>)}
    return <- move_ok(values, type<SdlError>)
}
def public enumerate_storage_directory(storage : SDL_Storage?; path : string = "") {
    var values : array<string>
    if (!SDL_EnumerateStorageDirectoryCopy(storage, path, values)) {return err(sdl_error("SDL_EnumerateStorageDirectoryCopy"), type<array<string>>)}
    return <- move_ok(values, type<SdlError>)
}
def public glob_storage_directory(storage : SDL_Storage?; path : string; pattern : string = "*"; flags : uint = 0u) {
    var values : array<string>
    if (!SDL_GlobStorageDirectoryCopy(storage, path, pattern, flags, values)) {return err(sdl_error("SDL_GlobStorageDirectoryCopy"), type<array<string>>)}
    return <- move_ok(values, type<SdlError>)
}
def public with_storage(storage : SDL_Storage?; body : block<(store : SDL_Storage?) : $Result<auto(TT); SdlError>>) {
    if (storage == null) {return err(SdlError(operation = "with_storage", message = "Null storage"), type<TT>)}
    var result : $Result<TT; SdlError>
    {
        defer() {
            let closed = SDL_CloseStorage(storage)
            if (!closed && is_ok(result)) {result <- err(sdl_error("SDL_CloseStorage"), type<TT>)}
        }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) {result = body(storage)}
        else {result <- body(storage)}
    }
    return <- result
}
def public with_file_storage(path : string; body : block<(store : SDL_Storage?) : $Result<auto(TT); SdlError>>) {
    let storage = SDL_OpenFileStorage(path)
    if (storage == null) {return err(sdl_error("SDL_OpenFileStorage"), type<TT>)}
    return <- with_storage(storage, body)
}
def public with_title_storage(path : string; props : uint; body : block<(store : SDL_Storage?) : $Result<auto(TT); SdlError>>) {
    let storage = SDL_OpenTitleStorage(path, props)
    if (storage == null) {return err(sdl_error("SDL_OpenTitleStorage"), type<TT>)}
    return <- with_storage(storage, body)
}
def public with_user_storage(org, app : string; props : uint; body : block<(store : SDL_Storage?) : $Result<auto(TT); SdlError>>) {
    let storage = SDL_OpenUserStorage(org, app, props)
    if (storage == null) {return err(sdl_error("SDL_OpenUserStorage"), type<TT>)}
    return <- with_storage(storage, body)
}
