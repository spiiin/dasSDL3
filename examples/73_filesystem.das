options gen2
require dassdl3/sdl3_filesystem_boost
require dassdl3/sdl3_try

def inspect_directory() : SdlStatus {
    let cwd = current_directory() |> sdl_try
    let base = base_path() |> sdl_try
    let info = path_info(cwd) |> sdl_try
    let entries <- enumerate_directory(cwd) |> sdl_try
    let scripts <- glob_directory(cwd, "*.das") |> sdl_try
    print("Current directory: {cwd}\nApplication base: {base}\n")
    print("Path type: {info.path_type}; entries: {length(entries)}; scripts: {length(scripts)}\n")
    for (entry in entries) { print("  {entry}\n") }
    return sdl_ok()
}
[export]
def main(smoke : bool) : int {
    let result = inspect_directory()
    if (is_err(result)) {let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1}
    return 0
}
