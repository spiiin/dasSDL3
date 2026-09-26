options gen2
module sdl3_surface_state_boost shared public
require dassdl3/sdl3_window_io_boost public

def public surface_color_key(surface : SDL_Surface?) {
    if (SDL_GetSurfaceProperties(surface) == 0u) { return err(sdl_error("SDL_GetSurfaceColorKey"), type<$Option<uint> >) }
    if (!SDL_SurfaceHasColorKey(surface)) { return ok(none(type<uint>), type<SdlError>) }
    var key : uint
    if (!SDL_GetSurfaceColorKeyRef(surface, key)) { return err(sdl_error("SDL_GetSurfaceColorKey"), type<$Option<uint> >) }
    return ok(some(key), type<SdlError>)
}
def public surface_color_mod(surface : SDL_Surface?; var r, g, b : uint&) {return sdl_status(SDL_GetSurfaceColorModRef(surface, r, g, b), "surface_color_mod")}
def public surface_alpha_mod(surface : SDL_Surface?; var a : uint&) {return sdl_status(SDL_GetSurfaceAlphaModRef(surface, a), "surface_alpha_mod")}
def public surface_blend_mode(surface : SDL_Surface?; var mode : uint&) {return sdl_status(SDL_GetSurfaceBlendModeRef(surface, mode), "surface_blend_mode")}
def public surface_clip(surface : SDL_Surface?; var rect : SDL_Rect) {return sdl_status(SDL_GetSurfaceClipRectRef(surface, rect), "surface_clip")}
def public set_surface_clip(surface : SDL_Surface?; rect : SDL_Rect) {
    if (SDL_GetSurfaceProperties(surface) == 0u) { return err(sdl_error("set_surface_clip"), type<bool>) }
    return ok(SDL_SetSurfaceClipRectRef(surface, rect), type<SdlError>)
}
def public reset_surface_clip(surface : SDL_Surface?) {
    if (SDL_GetSurfaceProperties(surface) == 0u) { return err(sdl_error("reset_surface_clip"), type<bool>) }
    return ok(SDL_ResetSurfaceClipRect(surface), type<SdlError>)
}

def public surface_color_mod(surface : SDL_Surface?) {
    var r : uint
    var g : uint
    var b : uint
    let status = surface_color_mod(surface, r, g, b)
    if (is_err(status)) { return err(unwrap_err(status), type<uint3>) }
    var value = uint3(r, g, b)
    return <- move_ok(value, type<SdlError>)
}

def public surface_alpha_mod(surface : SDL_Surface?) {
    var a : uint
    let status = surface_alpha_mod(surface, a)
    if (is_err(status)) { return err(unwrap_err(status), type<uint>) }
    var value = a
    return <- move_ok(value, type<SdlError>)
}

def public surface_blend_mode(surface : SDL_Surface?) {
    var mode : uint
    let status = surface_blend_mode(surface, mode)
    if (is_err(status)) { return err(unwrap_err(status), type<uint>) }
    var value = mode
    return <- move_ok(value, type<SdlError>)
}

def public surface_clip(surface : SDL_Surface?) {
    var rect : SDL_Rect
    let status = surface_clip(surface, rect)
    if (is_err(status)) { return err(unwrap_err(status), type<SDL_Rect>) }
    var value = rect
    return <- move_ok(value, type<SdlError>)
}

def public surface_color_key(surface : SDL_Surface?; var key : uint&) {
    key = 0u
    let value = surface_color_key(surface)
    if (is_err(value)){return err(unwrap_err(value), type<bool>)}
    let present = unwrap(value)
    if (is_none(present)){return ok(false, type<SdlError>)}
    key = unwrap(present)
    return ok(true, type<SdlError>)
}
