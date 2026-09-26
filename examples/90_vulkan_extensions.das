options gen2
require dassdl3/sdl3_vulkan_metal
require dassdl3/sdl3_boost
require dassdl3/sdl3_scope
[export]
def main(smoke : bool) : int {
    let result = sdl_scope() {
        with_sdl() |> sdl_use
        with_vulkan_library("") |> sdl_use
        var names <- vulkan_instance_extensions() |> sdl_try
        print("Required Vulkan instance extensions:\n")
        for (name in names) {print("  {name}\n")}
        // Pass these names to a native Vulkan instance creator. SDL owns windows
        // and surfaces; Vulkan owns the instance, device and rendering commands.
        return sdl_ok()
    }
    if (is_err(result)) {let e = unwrap_err(result); print("{e.operation}: {e.message}\n"); return 1}
    return 0
}
