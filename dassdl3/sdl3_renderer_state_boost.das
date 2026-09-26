options gen2
module sdl3_renderer_state_boost shared public
require dassdl3/sdl3_renderer_primitives_boost public

def public render_output_size(renderer : SDL_Renderer?; var w, h : int&) {
    return sdl_status(SDL_GetRenderOutputSizeRef(renderer, w, h), "render_output_size")
}
def public current_render_output_size(renderer : SDL_Renderer?; var w, h : int&) {
    return sdl_status(SDL_GetCurrentRenderOutputSizeRef(renderer, w, h), "current_render_output_size")
}
def public render_scale(renderer : SDL_Renderer?; var x, y : float&) {
    return sdl_status(SDL_GetRenderScaleRef(renderer, x, y), "render_scale")
}

def public render_output_size(renderer : SDL_Renderer?) {
    var w : int
    var h : int
    let status = render_output_size(renderer, w, h)
    if (is_err(status)) { return err(unwrap_err(status), type<int2>) }
    var value = int2(w, h)
    return <- move_ok(value, type<SdlError>)
}

def public current_render_output_size(renderer : SDL_Renderer?) {
    var w : int
    var h : int
    let status = current_render_output_size(renderer, w, h)
    if (is_err(status)) { return err(unwrap_err(status), type<int2>) }
    var value = int2(w, h)
    return <- move_ok(value, type<SdlError>)
}

def public render_scale(renderer : SDL_Renderer?) {
    var x : float
    var y : float
    let status = render_scale(renderer, x, y)
    if (is_err(status)) { return err(unwrap_err(status), type<float2>) }
    var value = float2(x, y)
    return <- move_ok(value, type<SdlError>)
}
