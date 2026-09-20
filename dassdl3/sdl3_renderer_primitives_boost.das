options gen2
require daslib/defer
module sdl3_renderer_primitives_boost shared public
require dassdl3/sdl3_window_io_boost public

// The caller keeps the surface alive until this renderer has been destroyed.
def public with_software_renderer(surface : SDL_Surface?; blk : block<(renderer : SDL_Renderer?) : void>) : bool {
    let renderer=SDL_CreateSoftwareRenderer(surface)
    if(renderer==null) {return false}
    {defer(){SDL_DestroyRenderer(renderer)};blk(renderer);return true}
}
