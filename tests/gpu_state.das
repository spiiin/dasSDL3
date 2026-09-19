options gen2
require sdl3
[export]
def main(smoke : bool) : int {
    verify(smoke)
    if (!SDLTestGPUStateContracts()) { panic("{SDL_GetError()}") }
    print("GPU clear state/error contracts passed (no GPU required).\n")
    return 0
}
