options gen2
module sdl3_process_loadso shared public
require dassdl3/sdl3_boost public
require daslib/defer

struct public SdlProcessOutput {
    bytes : array<uint8>
    exit_code : int
}
def public create_process(args : array<string>; pipe_stdio : bool = true) {
    var value = SDL_CreateProcessArray(args, pipe_stdio)
    if (value == null) {return err(sdl_error("SDL_CreateProcess"), type<SDL_Process?>)}
    return <- move_ok(value, type<SdlError>)
}
def public create_process(props : uint) {
    var value = SDL_CreateProcessWithProperties(props)
    if (value == null) {return err(sdl_error("SDL_CreateProcessWithProperties"), type<SDL_Process?>)}
    return <- move_ok(value, type<SdlError>)
}
def public destroy_process(var process : SDL_Process?&) {SDL_DestroyProcess(process); process = null}
// Releases SDL tracking/pipes only. The body must choose whether to wait or kill.
def public with_process(args : array<string>; pipe_stdio : bool; blk : block<(process : SDL_Process?) : $Result<auto(T); SdlError>>) {
    let value = SDL_CreateProcessArray(args, pipe_stdio)
    if (value == null) {return err(sdl_error("SDL_CreateProcess"), type<T>)}
    var result : $Result<T; SdlError>
    {
        defer() {SDL_DestroyProcess(value)}
        static_if (typeinfo can_copy(type<$Result<T; SdlError>>)) {result = blk(value)} else {result <- blk(value)}
    }
    return <- result
}
def public read_process(process : SDL_Process?) {
    var output : SdlProcessOutput
    if (!SDL_ReadProcessCopy(process, output.bytes, output.exit_code)) {return err(sdl_error("SDL_ReadProcess"), type<SdlProcessOutput>)}
    return <- move_ok(output, type<SdlError>)
}
def public wait_process(process : SDL_Process?; blocking : bool = false) {
    var exit_code = 0
    let state = SDL_WaitProcessStateRef(process, blocking, exit_code)
    if (state < 0) {return err(sdl_error("SDL_WaitProcess"), type<$Option<int>>)}
    if (state == 0) {return ok(none(type<int>), type<SdlError>)}
    return ok(some(exit_code), type<SdlError>)
}
def public kill_process(process : SDL_Process?; force : bool = false) {return sdl_status(SDL_KillProcess(process, force), "SDL_KillProcess")}
def public load_object(path : string) {
    var value = SDL_LoadObject(path)
    if (value == null) {return err(sdl_error("SDL_LoadObject"), type<SDL_SharedObject?>)}
    return <- move_ok(value, type<SdlError>)
}
// A named payload avoids pinned daScript's void-pointer generic collision.
// This address borrows its library; it owns nothing and has no inferred ABI.
struct public SdlFunctionAddress {
    address : void?
}
def public load_function(object : SDL_SharedObject?; name : string) {
    let address = SDL_LoadFunction(object, name)
    if (address == null) {return err(sdl_error("SDL_LoadFunction"), type<SdlFunctionAddress>)}
    return ok(SdlFunctionAddress(address = address), type<SdlError>)
}
def public unload_object(var object : SDL_SharedObject?&) {SDL_UnloadObject(object); object = null}
def public with_object(path : string; blk : block<(object : SDL_SharedObject?) : $Result<auto(T); SdlError>>) {
    let value = SDL_LoadObject(path)
    if (value == null) {return err(sdl_error("SDL_LoadObject"), type<T>)}
    var result : $Result<T; SdlError>
    {
        defer() {SDL_UnloadObject(value)}
        static_if (typeinfo can_copy(type<$Result<T; SdlError>>)) {result = blk(value)} else {result <- blk(value)}
    }
    return <- result
}
