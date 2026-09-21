options gen2
require dassdl3/sdl3_storage_boost
require dassdl3/sdl3_scope
require daslib/defer
require daslib/safe_addr

def interface() : SDL_StorageInterface {
    var value=SDL_MakeStorageInterface()
    SDL_SetStorageInterface_close(value,SDLTestStorageCallback(0))
    SDL_SetStorageInterface_ready(value,SDLTestStorageCallback(1))
    SDL_SetStorageInterface_enumerate(value,SDLTestStorageCallback(2))
    SDL_SetStorageInterface_info(value,SDLTestStorageCallback(3))
    SDL_SetStorageInterface_read_file(value,SDLTestStorageCallback(4))
    SDL_SetStorageInterface_write_file(value,SDLTestStorageCallback(5))
    SDL_SetStorageInterface_mkdir(value,SDLTestStorageCallback(6))
    SDL_SetStorageInterface_remove(value,SDLTestStorageCallback(7))
    SDL_SetStorageInterface_rename(value,SDLTestStorageCallback(8))
    SDL_SetStorageInterface_copy(value,SDLTestStorageCallback(9))
    SDL_SetStorageInterface_space_remaining(value,SDLTestStorageCallback(10))
    return value
}
def exercise(storage : SDL_Storage?) {
    verify(SDL_CreateStorageDirectory(storage,"sub"))
    var bytes <- array<uint8>(17,0,255,42)
    unsafe { verify(SDL_WriteStorageFile(storage,"sub/é.bin",addr(bytes[0]),4ul)) }
    var size=0ul
    verify(SDL_GetStorageFileSize(storage,"sub/é.bin",safe_addr(size)) && size==4ul)
    var info : SDL_PathInfo
    verify(SDL_GetStoragePathInfo(storage,"sub/é.bin",safe_addr(info)) && info.size==4ul && info.path_type==SDL_PathType.PATHTYPE_FILE)
    var out <- array<uint8>(99,99,99,99,99)
    unsafe { verify(SDL_ReadStorageFile(storage,"sub/é.bin",addr(out[0]),4ul)) }
    verify(out[0]==17 && out[1]==0 && out[2]==255 && out[3]==42 && out[4]==99)
    verify(is_err(read_storage_file(storage,"sub/é.bin",out,6ul)))
    verify(!SDL_WriteStorageFileArray(storage,"sub/never.bin",bytes,5ul))
    verify(is_err(read_storage_file(storage,"sub/é.bin",out,5ul))) // short source
    var loaded <- load_storage_file(storage,"sub/é.bin") |> unwrap
    verify(length(loaded)==4 && loaded[2]==255)
    verify(SDL_CopyStorageFile(storage,"sub/é.bin","sub/copy.bin"))
    verify(SDL_RenameStoragePath(storage,"sub/copy.bin","sub/renamed.bin"))
    verify(SDL_EnumerateStorageDirectory(storage,"sub",SDLTestFilesystemCallback(0),SDLTestFilesystemUserdata()))
    verify(SDLTestFilesystemCount()==2)
    verify(SDL_EnumerateStorageDirectory(storage,"sub",SDLTestFilesystemCallback(1),SDLTestFilesystemUserdata()))
    verify(SDLTestFilesystemCount()==1)
    verify(!SDL_EnumerateStorageDirectory(storage,"sub",SDLTestFilesystemCallback(2),SDLTestFilesystemUserdata()))
    var names <- enumerate_storage_directory(storage,"sub") |> unwrap
    verify(length(names)==2)
    unsafe {
        var count=0
        let glob=SDL_GlobStorageDirectory(storage,"sub","*.bin",0u,addr(count))
        verify(glob!=null && count==2)
        SDL_free(glob)
    }
    var matches <- glob_storage_directory(storage,"sub","*.BIN",SDL_GLOB_CASEINSENSITIVE) |> unwrap
    verify(length(matches)==2)
    var absent <- glob_storage_directory(storage,"sub","*.missing") |> unwrap
    verify(length(absent)==0)
    verify(!SDL_RemoveStoragePath(storage,"sub"))
    verify(is_err(storage_path_info(storage,"../outside")))
    verify(is_err(create_storage_directory(storage,"sub/../outside")))
    verify(is_err(create_storage_directory(storage,"sub\\outside")))
    let failed=storage_file_size(storage,"missing")
    verify(is_err(failed))
    let saved=unwrap_err(failed)
    SDL_ClearError()
    verify(length(saved.message)>0)
    verify(storage_file_size(storage,"sub/é.bin") |> unwrap == 4ul)
    verify(SDL_RemoveStoragePath(storage,"sub/renamed.bin"))
    verify(is_ok(remove_storage_path(storage,"sub/é.bin")))
    verify(SDL_RemoveStoragePath(storage,"sub"))
    verify(length(names)==2 && length(matches)==2)
    var empty : array<uint8>
    verify(is_ok(write_storage_file(storage,"empty",empty)))
    var zero <- load_storage_file(storage,"empty") |> unwrap
    verify(length(zero)==0)
    verify(is_ok(remove_storage_path(storage,"empty")))
    SDL_GetStorageSpaceRemaining(storage)
}
[export]
def main(smoke : bool) : int {
    let root="storage-test-{SDL_GetTicksNS()}"
    verify(SDL_CreateDirectory(root))
    {
        defer() {SDL_RemovePath(root)}
        let file=SDL_OpenFileStorage(root)
        verify(file!=null && SDL_StorageReady(file))
        exercise(file)
        verify(SDL_CloseStorage(file))
        let title=SDL_OpenTitleStorage(root,0u)
        verify(title!=null && SDL_StorageReady(title))
        var bytes <- array<uint8>(1)
        verify(is_err(write_storage_file(title,"forbidden",bytes)))
        verify(SDL_CloseStorage(title))
        var no_app : string
        verify(SDL_OpenUserStorage("",no_app,0u)==null)
        var iface=interface()
        let custom=SDL_OpenStorage(safe_addr(iface),SDLTestStorageReset(root,false))
        verify(custom!=null)
        iface.version=0u
        verify(!storage_ready(custom))
        verify(storage_ready(custom))
        exercise(custom)
        verify(storage_space_remaining(custom)==0ul)
        verify(SDL_CloseStorage(custom))
        verify(SDLTestStorageCloses()==1 && SDLTestStorageMask()==2047u)
        verify(is_err(open_storage(iface,null)))
        iface=interface()
        var created <- open_storage(iface,SDLTestStorageReset(root,true))
        var owned=move_unwrap(created)
        verify(is_err(close_storage(owned)) && owned==null && SDLTestStorageCloses()==1)
        let fail=with_storage(SDL_OpenStorageRef(iface,SDLTestStorageReset(root,true))) $(store : SDL_Storage?) {return sdl_ok()}
        verify(is_err(fail) && unwrap_err(fail).operation=="SDL_CloseStorage" && SDLTestStorageCloses()==1)
        let primary=with_storage(SDL_OpenStorageRef(iface,SDLTestStorageReset(root,true))) $(store : SDL_Storage?) {
            return err(SdlError(operation="body",message="primary"),type<SdlUnit>)
        }
        verify(is_err(primary) && unwrap_err(primary).operation=="body" && SDLTestStorageCloses()==1)
        var moved <- with_file_storage(root) $(store : SDL_Storage?) {return <- enumerate_storage_directory(store)}
        verify(is_ok(moved) && length(unwrap(moved))==0)
        var called=false
        let skipped=with_user_storage("",no_app,0u) $(store : SDL_Storage?) {called=true;return sdl_ok()}
        verify(is_err(skipped) && !called)
    }
    print("Storage: file/title/custom APIs, copied arrays, native callbacks and cleanup passed.\n")
    return 0
}
