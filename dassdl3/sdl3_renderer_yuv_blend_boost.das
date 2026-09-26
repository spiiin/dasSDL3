options gen2
module sdl3_renderer_yuv_blend_boost shared public
require dassdl3/sdl3_texture_transfer_boost public

def public render_draw_color(renderer : SDL_Renderer?; var r, g, b, a : float&) {return sdl_status(SDL_GetRenderDrawColorFloatRef(renderer, r, g, b, a), "render_draw_color")}
def public render_draw_color_bytes(renderer : SDL_Renderer?; var r, g, b, a : uint&) {return sdl_status(SDL_GetRenderDrawColorRef(renderer, r, g, b, a), "render_draw_color_bytes")}
def public render_color_scale(renderer : SDL_Renderer?; var scale : float&) {return sdl_status(SDL_GetRenderColorScaleRef(renderer, scale), "render_color_scale")}
def public render_draw_blend_mode(renderer : SDL_Renderer?; var mode : uint&) {return sdl_status(SDL_GetRenderDrawBlendModeRef(renderer, mode), "render_draw_blend_mode")}
def public update_yuv_texture(texture : SDL_Texture?; y : array<uint8>; yp : int; u : array<uint8>; up : int; v : array<uint8>; vp : int) {return sdl_status(SDL_UpdateYUVTextureArrays(texture, y, yp, u, up, v, vp), "update_yuv_texture")}
def public update_nv_texture(texture : SDL_Texture?; y : array<uint8>; yp : int; uv : array<uint8>; uvp : int) {return sdl_status(SDL_UpdateNVTextureArrays(texture, y, yp, uv, uvp), "update_nv_texture")}

def public render_draw_color(renderer : SDL_Renderer?) {
    var r : float
    var g : float
    var b : float
    var a : float
    let status = render_draw_color(renderer, r, g, b, a)
    if (is_err(status)) { return err(unwrap_err(status), type<float4>) }
    var value = float4(r, g, b, a)
    return <- move_ok(value, type<SdlError>)
}

def public render_draw_color_bytes(renderer : SDL_Renderer?) {
    var r : uint
    var g : uint
    var b : uint
    var a : uint
    let status = render_draw_color_bytes(renderer, r, g, b, a)
    if (is_err(status)) { return err(unwrap_err(status), type<uint4>) }
    var value = uint4(r, g, b, a)
    return <- move_ok(value, type<SdlError>)
}

def public render_color_scale(renderer : SDL_Renderer?) {
    var scale : float
    let status = render_color_scale(renderer, scale)
    if (is_err(status)) { return err(unwrap_err(status), type<float>) }
    var value = scale
    return <- move_ok(value, type<SdlError>)
}

def public render_draw_blend_mode(renderer : SDL_Renderer?) {
    var mode : uint
    let status = render_draw_blend_mode(renderer, mode)
    if (is_err(status)) { return err(unwrap_err(status), type<uint>) }
    var value = mode
    return <- move_ok(value, type<SdlError>)
}
