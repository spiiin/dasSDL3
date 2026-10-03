options gen2
require dassdl3/sdl3_process_loadso
require dassdl3/sdl3_scope

// argv is passed directly to the executable; loaded exports remain C addresses.
[export]
def main(smoke : bool) : int {
    let mac = SDL_GetPlatform() == "macOS"
    var args <- array<string>(mac ? "/bin/hostname" : "hostname.exe")
    let result = sdl_scope() {
        let process : SDL_Process? = with_process(args, true) |> sdl_use
        var output <- read_process(process) |> sdl_try
        if (output.exit_code != 0) {return err(SdlError(operation = "hostname process", message = "Child exited with code {output.exit_code}"), type<SdlUnit>)}
        print("Process exit: {output.exit_code}; output bytes: {length(output.bytes)}\n")
        let library : SDL_SharedObject? = with_object(mac ? "/usr/lib/libSystem.B.dylib" : "kernel32.dll") |> sdl_use
        let address = load_function(library, mac ? "getpid" : "GetCurrentProcessId") |> sdl_try
        print("Native export found: {address.address!=null}\n")
        // An address is not a script function. Never call it with an unknown ABI.
        return sdl_ok()
    }
    if (is_err(result)) {
        let error = unwrap_err(result); print("{error.operation}: {error.message}\n"); return 1
    }
    return 0
}
