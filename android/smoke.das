options gen2
require sdl3

// Different colors let the host check each execution mode independently.
[export]
def paint(renderer : SDL_Renderer?; blue : uint) : bool {
    return SDL_SetRenderDrawColor(renderer, 24u, 96u, blue, 255u) && SDL_RenderClear(renderer)
}
