options gen2
module sdl3_renderer_presentation_boost shared public
require dassdl3/sdl3_renderer_state_boost public

def public render_driver(index : int) : string {return SDL_GetRenderDriverCopy(index)}
def public renderer_name(renderer : SDL_Renderer?) : string {return SDL_GetRendererNameCopy(renderer)}
def public render_logical_presentation(renderer : SDL_Renderer?; var w,h : int&; var mode : SDL_RendererLogicalPresentation&) : bool {
    return SDL_GetRenderLogicalPresentationRef(renderer,w,h,mode)
}
def public render_from_window(renderer : SDL_Renderer?; wx,wy : float; var x,y : float&) : bool {
    return SDL_RenderCoordinatesFromWindowRef(renderer,wx,wy,x,y)
}
def public render_to_window(renderer : SDL_Renderer?; x,y : float; var wx,wy : float&) : bool {
    return SDL_RenderCoordinatesToWindowRef(renderer,x,y,wx,wy)
}
