options gen2
require daslib/defer
module sdl3_pixels_boost shared public
require dassdl3/sdl3_boost public


// Positive dimensions; byte pitch includes optional row padding. Maximum INT_MAX.
def public rgba8_buffer_size(width, height, pitch : int) {
    let size = SDL_RGBA8BufferSize(width, height, pitch)
    let value = size
    if (value < 0) { return err(sdl_error("rgba8_buffer_size"), type<int>) }
    return ok(value,type<SdlError>)
}

def private with_rgba8_texture(renderer : SDL_Renderer?; width, height : int; target : bool;
                              blk : block<(texture : SDL_Texture?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let texture = SDL_CreateRGBA8Texture(renderer, width, height, target)
    if (texture == null) { return err(sdl_error("with_rgba8_texture"), type<TT>) }
    {
        defer() { SDL_DestroyTexture(texture) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(texture) } else { scope_result <- blk(texture) }
    }

    return <- scope_result
}

def public with_streaming_texture(renderer : SDL_Renderer?; width, height : int;
                                 blk : block<(texture : SDL_Texture?) : $Result<auto(TT); SdlError> >) {
    return <- with_rgba8_texture(renderer, width, height, false, blk)
}

def public with_target_texture(renderer : SDL_Renderer?; width, height : int;
                              blk : block<(texture : SDL_Texture?) : $Result<auto(TT); SdlError> >) {
    return <- with_rgba8_texture(renderer, width, height, true, blk)
}

// Copies the whole image synchronously; no pointer or lock escapes to script.
def public upload_rgba8(texture : SDL_Texture?; bytes : array<uint8>; pitch : int) {
    return sdl_status(SDL_UploadRGBA8(texture, bytes, pitch), "upload_rgba8")
}

// Nest inside the lifetime of both targets; null selects the window.
// SDL restores per-target viewport/clip/scale; draw color is not scope-owned.
def public with_render_target(renderer : SDL_Renderer?; texture : SDL_Texture?;
                              blk : block<() : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let previous = SDL_GetRenderTarget(renderer)
    if (!SDL_SetRenderTarget(renderer, texture)) { return err(sdl_error("with_render_target"),type<TT>) }
    {
        defer() { if (!SDL_SetRenderTarget(renderer,previous) && is_ok(scope_result)) { scope_result <- err(sdl_error("SDL_SetRenderTarget"),type<TT>) } }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk() } else { scope_result <- blk() }
    }

    return <- scope_result
}

// Owns the readback surface. For the window call before present().
def public with_read_pixels(renderer : SDL_Renderer?; blk : block<(surface : SDL_Surface?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let surface = SDL_ReadPixelsOwned(renderer)
    if (surface == null) { return err(sdl_error("with_read_pixels"), type<TT>) }
    {
        defer() { SDL_DestroySurface(surface) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(surface) } else { scope_result <- blk(surface) }
    }

    return <- scope_result
}

def public surface_size(surface : SDL_Surface?; var size : int2&) {
    var width, height : int
    if (!SDL_SurfaceSizeRef(surface, width, height)) { return err(sdl_error("surface_size"), type<SdlUnit>) }
    size = int2(width, height)
    return sdl_ok()
}

// Converts to byte RGBA and copies into caller-owned storage; padding is untouched.
def public copy_surface_rgba8(surface : SDL_Surface?; var bytes : array<uint8>; pitch : int) {
    return sdl_status(SDL_CopySurfaceRGBA8(surface, bytes, pitch), "copy_surface_rgba8")
}

def public surface_size(surface : SDL_Surface?) {
    var size : int2
    let status = surface_size(surface,size)
    if (is_err(status)) { return err(unwrap_err(status),type<int2>) }
    var value = size
    return <- move_ok(value,type<SdlError>)
}
