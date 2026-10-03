options gen2
require dassdl3/sdl3_filesystem_boost
require dassdl3/sdl3_try
require daslib/defer
require daslib/safe_addr

def contains(values : array<string>; expected : string) : bool {
    for (value in values) { if (value == expected) { return true } }
    return false
}
[export]
def main(smoke : bool) : int {
    verify(length(SDL_GetBasePath()) > 0)
    let base = base_path() |> unwrap
    verify(length(base) > 0)
    var no_app : string
    unsafe {
        let cwd = SDL_GetCurrentDirectory()
        verify(length(cwd) > 0)
        SDL_free(reinterpret<void?>(cwd))
        let pref = SDL_GetPrefPath("", no_app)
        if (SDL_GetPlatform() == "macOS") {verify(length(pref) > 0)}
        else {verify(length(pref) == 0)}
        SDL_free(reinterpret<void?>(pref))
    }
    // Pinned Cocoa accepts an empty application name; Windows rejects it.
    verify(is_ok(pref_path("", no_app)) == (SDL_GetPlatform() == "macOS"))
    let home = SDL_GetUserFolder(SDL_Folder.FOLDER_HOME)
    let copied_home = user_folder(SDL_Folder.FOLDER_HOME)
    if (length(home) > 0) { verify(is_ok(copied_home) && unwrap(copied_home) == home) }
    else { verify(is_err(copied_home)); print("Home folder unavailable: {unwrap_err(copied_home).message}\n") }
    verify(is_err(user_folder(SDL_Folder.FOLDER_COUNT)))
    let root = "filesystem-test-{SDL_GetTicksNS()}"
    verify(SDL_CreateDirectory(root))
    {
        defer() { SDL_RemovePath("{root}/source-é.txt"); SDL_RemovePath("{root}/copy.txt"); SDL_RemovePath("{root}/renamed.txt"); SDL_RemovePath("{root}/sub"); SDL_RemovePath(root) }
        verify(is_ok(create_directory(root)))
        verify(SDLTestFilesystemFile("{root}/source-é.txt", true))
        verify(SDL_CopyFile("{root}/source-é.txt", "{root}/copy.txt"))
        verify(SDLTestFilesystemFile("{root}/copy.txt", false))
        verify(is_ok(rename_path("{root}/copy.txt", "{root}/renamed.txt")))
        var info : SDL_PathInfo
        verify(SDL_GetPathInfo("{root}/renamed.txt", safe_addr(info)))
        verify(info.path_type == SDL_PathType.PATHTYPE_FILE && info.size == 20ul)
        verify(is_ok(create_directory("{root}/sub")))
        var entries <- enumerate_directory(root) |> unwrap
        verify(length(entries) == 3 && contains(entries, "source-é.txt") && contains(entries, "renamed.txt") && contains(entries, "sub"))
        var matches <- glob_directory(root, "*.TXT", SDL_GLOB_CASEINSENSITIVE) |> unwrap
        verify(length(matches) == 2)
        var no_matches <- glob_directory(root, "*.missing") |> unwrap
        verify(length(no_matches) == 0)
        unsafe {
            var count = 0
            let raw = SDL_GlobDirectory(root, "*.txt", 0u, addr(count))
            verify(raw != null && count == 2)
            SDL_free(raw)
        }
        verify(SDL_EnumerateDirectory(root, SDLTestFilesystemCallback(0), SDLTestFilesystemUserdata()))
        verify(SDLTestFilesystemCount() == 3)
        verify(SDL_EnumerateDirectory(root, SDLTestFilesystemCallback(1), SDLTestFilesystemUserdata()))
        verify(SDLTestFilesystemCount() == 1)
        verify(!SDL_EnumerateDirectory(root, SDLTestFilesystemCallback(2), SDLTestFilesystemUserdata()))
        verify(SDLTestFilesystemCount() == 1)
        verify(!SDL_RemovePath(root)) // nonempty, never recursive
        verify(is_err(copy_file("{root}/absent", "{root}/copy.txt")))
        verify(is_err(rename_path("{root}/absent", "{root}/copy.txt")))
        var failure <- enumerate_directory("{root}/absent")
        verify(is_err(failure))
        let saved = unwrap_err(failure)
        SDL_ClearError()
        verify(length(saved.message) > 0 && saved.operation == "SDL_EnumerateDirectory")
        verify(is_err(glob_directory("{root}/absent", "*")))
        verify(is_ok(remove_path("{root}/source-é.txt")))
        verify(SDL_RemovePath("{root}/renamed.txt"))
        verify(SDL_RemovePath("{root}/sub"))
        verify(length(entries) == 3 && contains(entries, "source-é.txt"))// copied names survive removal
        verify(is_ok(path_info(root)))
        var empty <- enumerate_directory(root) |> unwrap
        verify(length(empty) == 0)
        var stale : array<string>
        push(stale, "stale")
        verify(!SDL_EnumerateDirectoryCopy("{root}/absent", stale) && length(stale) == 0)
        push(stale, "stale")
        verify(!SDL_GlobDirectoryCopy("{root}/absent", "*", 0u, stale) && length(stale) == 0)
        verify(is_ok(path_info(root))) // previous error text must not turn success into Err
    }
    var missing : SDL_PathInfo
    verify(!SDL_GetPathInfoRef(root, missing))
    print("Filesystem: paths, raw calls, copied lists, callbacks and errors passed.\n")
    return 0
}
