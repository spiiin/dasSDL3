options gen2
module sdl3_renderer_presentation_boost shared public
require dassdl3/sdl3_renderer_state_boost public

def public render_driver(index : int) {
    var value : string
    if (!SDL_GetRenderDriverValue(index, value)) {return err(sdl_error("render_driver"), type<string>)}
    return ok(value, type<SdlError>)
}
def public renderer_name(renderer : SDL_Renderer?) {
    var value : string
    if (!SDL_GetRendererNameValue(renderer, value)) {return err(sdl_error("renderer_name"), type<string>)}
    return ok(value, type<SdlError>)
}
def public render_logical_presentation(renderer : SDL_Renderer?; var w, h : int&; var mode : SDL_RendererLogicalPresentation&) {
    return sdl_status(SDL_GetRenderLogicalPresentationRef(renderer, w, h, mode), "render_logical_presentation")
}
def public render_from_window(renderer : SDL_Renderer?; wx, wy : float; var x, y : float&) {
    return sdl_status(SDL_RenderCoordinatesFromWindowRef(renderer, wx, wy, x, y), "render_from_window")
}
def public render_to_window(renderer : SDL_Renderer?; x, y : float; var wx, wy : float&) {
    return sdl_status(SDL_RenderCoordinatesToWindowRef(renderer, x, y, wx, wy), "render_to_window")
}

def public render_logical_presentation(renderer : SDL_Renderer?) {
    var w : int
    var h : int
    var mode : SDL_RendererLogicalPresentation
    let status = render_logical_presentation(renderer, w, h, mode)
    if (is_err(status)) { return err(unwrap_err(status), type<tuple<w : int; h : int; mode : SDL_RendererLogicalPresentation>>) }
    var value = (w = w, h = h, mode = mode)
    return <- move_ok(value, type<SdlError>)
}

def public render_from_window(renderer : SDL_Renderer?; wx, wy : float) {
    var x : float
    var y : float
    let status = render_from_window(renderer, wx, wy, x, y)
    if (is_err(status)) { return err(unwrap_err(status), type<float2>) }
    var value = float2(x, y)
    return <- move_ok(value, type<SdlError>)
}

def public render_to_window(renderer : SDL_Renderer?; x, y : float) {
    var wx : float
    var wy : float
    let status = render_to_window(renderer, x, y, wx, wy)
    if (is_err(status)) { return err(unwrap_err(status), type<float2>) }
    var value = float2(wx, wy)
    return <- move_ok(value, type<SdlError>)
}
