options gen2
require dassdl3/sdl3_storage_boost
require dassdl3/sdl3_scope

def inspect_storage() : $Result<SdlUnit; SdlError> {
    return sdl_scope() {
        let storage : SDL_Storage? = with_file_storage(".") |> sdl_use
        if(!storage_ready(storage)) {print("Storage is not ready yet.\n");return sdl_ok()}
        let names <- storage |> enumerate_storage_directory() |> sdl_try
        print("Storage entries: {length(names)}\n")
        for(name in names) {print("  {name}\n")}
        return sdl_ok()
    }
}
[export]
def main(smoke : bool) : int {
    let result=inspect_storage()
    if(is_err(result)) {let e=unwrap_err(result);print("{e.operation}: {e.message}\n");return 1}
    return 0
}
