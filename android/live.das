options gen2
require sdl3
require live_host

[export]
def paint(renderer : SDL_Renderer?) : bool {
    var session : string
    if (get_reload_generation() == 0ul) {
        live_store_string("android.live.session", "started")
    } elif (!live_load_string("android.live.session", session) || session != "started") {
        return false
    }
    return SDL_SetRenderDrawColor(renderer, 24u, 96u, 64u, 255u) && SDL_RenderClear(renderer)
}
