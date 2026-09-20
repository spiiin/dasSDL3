options gen2
module sdl3_renderer_state_boost shared public
require dassdl3/sdl3_renderer_primitives_boost public

def public render_output_size(renderer : SDL_Renderer?; var w,h : int&) : bool {
    return SDL_GetRenderOutputSizeRef(renderer,w,h)
}
def public current_render_output_size(renderer : SDL_Renderer?; var w,h : int&) : bool {
    return SDL_GetCurrentRenderOutputSizeRef(renderer,w,h)
}
def public render_scale(renderer : SDL_Renderer?; var x,y : float&) : bool {
    return SDL_GetRenderScaleRef(renderer,x,y)
}
