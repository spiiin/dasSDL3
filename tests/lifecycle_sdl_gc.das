options gen2
options gc
options persistent_heap
require dassdl3/sdl3_boost
var window : SDL_Window?
var renderer : SDL_Renderer?
var keep : array<int>
var text = ""
var frames = 0
[export]
def init() {
    verify(SDL_Init(SDL_INIT_VIDEO))
    window = SDL_CreateWindow("SDL roots with GC", 640, 480, 0ul)
    verify(window != null)
    renderer = SDL_CreateRenderer(window, "")
    verify(renderer != null)
    resize(keep, 4)
    keep[0] = 123
}
[export]
def update() : bool {
    verify(keep[0] == 123)
    var junk : array<float>
    resize(junk, 16384)
    junk[0] = float(frames)
    text = "frame {frames}"
    keep[1] = int(junk[0]) + length(text)
    verify(SDL_SetRenderDrawColor(renderer, 70u, 200u, 160u, 255u))
    verify(SDL_RenderClear(renderer))
    verify(SDL_RenderPresent(renderer))
    frames++
    return frames < 400
}
[export]
def shutdown() {
    if (renderer != null) { SDL_DestroyRenderer(renderer); renderer = null }
    if (window != null) { SDL_DestroyWindow(window); window = null }
    SDL_Quit()
    verify(frames == 400 && keep[0] == 123 && length(text) > 0)
    print("SDL GC frames={frames} heap={heap_bytes_allocated()}\n")
    verify(heap_bytes_allocated() < 1048576ul)
    print("SDL resources and GC roots PASS\n")
}
