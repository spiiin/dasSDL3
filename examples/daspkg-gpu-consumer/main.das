options gen2
require daslib/clargs
require sdl3
require ./texture_bindings.das as validation
require ./gpu_renderer.das as demo

[export]
def main : int {
    // Reuse the existing GPU pixel oracle before opening the interactive renderer.
    if (validation::main(false) != 0) {return 1}
    var smoke = false
    for (arg in get_user_args()) {if (arg == "--smoke") {smoke = true}}
    let result = demo::main(smoke)
    verify(SDL_WasInit(0u) == 0u)
    if (result == 0) {print("Standalone GPU: texture pixels verified; resources released.\n")}
    return result
}
