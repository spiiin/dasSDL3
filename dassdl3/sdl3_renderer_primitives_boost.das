options gen2
require daslib/defer
module sdl3_renderer_primitives_boost shared public
require dassdl3/sdl3_window_io_boost public

// The caller keeps the surface alive until this renderer has been destroyed.
def public with_software_renderer(surface : SDL_Surface?; blk : block<(renderer : SDL_Renderer?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let renderer=SDL_CreateSoftwareRenderer(surface)
    if(renderer==null) {return err(sdl_error("with_software_renderer"), type<TT>)}
    {defer(){SDL_DestroyRenderer(renderer)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(renderer) } else { scope_result <- blk(renderer) }}

    return <- scope_result
}
