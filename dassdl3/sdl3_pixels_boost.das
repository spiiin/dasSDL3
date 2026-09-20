options gen2
require daslib/defer
module sdl3_pixels_boost shared public
require dassdl3/sdl3_boost public


// Positive dimensions; byte pitch includes optional row padding. Maximum INT_MAX.
def public rgba8_buffer_size(width, height, pitch : int) : int {
    let size = SDL_RGBA8BufferSize(width, height, pitch)
    return size
}

def private with_rgba8_texture(renderer : SDL_Renderer?; width, height : int; target : bool;
                              blk : block<(texture : SDL_Texture?) : void>) {
    let texture = SDL_CreateRGBA8Texture(renderer, width, height, target)
    if (texture == null) { return false }
    {
        defer() { SDL_DestroyTexture(texture) }
        blk(texture)
        return true
    }
}

def public with_streaming_texture(renderer : SDL_Renderer?; width, height : int;
                                 blk : block<(texture : SDL_Texture?) : void>) {
    return with_rgba8_texture(renderer, width, height, false, blk)
}

def public with_target_texture(renderer : SDL_Renderer?; width, height : int;
                              blk : block<(texture : SDL_Texture?) : void>) {
    return with_rgba8_texture(renderer, width, height, true, blk)
}

// Copies the whole image synchronously; no pointer or lock escapes to script.
def public upload_rgba8(texture : SDL_Texture?; bytes : array<uint8>; pitch : int) {
    return SDL_UploadRGBA8(texture, bytes, pitch)
}

// Nest inside the lifetime of both targets; null selects the window.
// SDL restores per-target viewport/clip/scale; draw color is not scope-owned.
def public with_render_target(renderer : SDL_Renderer?; texture : SDL_Texture?;
                              blk : block<() : void>) {
    let previous = SDL_GetRenderTarget(renderer)
    if (!SDL_SetRenderTarget(renderer, texture)) { return false }
    {
        defer() { SDL_SetRenderTarget(renderer,previous) }
        blk()
        return true
    }
}

// Owns the readback surface. For the window call before present().
def public with_read_pixels(renderer : SDL_Renderer?; blk : block<(surface : SDL_Surface?) : void>) {
    let surface = SDL_ReadPixelsOwned(renderer)
    if (surface == null) { return false }
    {
        defer() { SDL_DestroySurface(surface) }
        blk(surface)
        return true
    }
}

def public surface_size(surface : SDL_Surface?; var size : int2&) : bool {
    var width, height : int
    if (!SDL_SurfaceSizeRef(surface, width, height)) { return false }
    size = int2(width, height)
    return true
}

// Converts to byte RGBA and copies into caller-owned storage; padding is untouched.
def public copy_surface_rgba8(surface : SDL_Surface?; var bytes : array<uint8>; pitch : int) {
    return SDL_CopySurfaceRGBA8(surface, bytes, pitch)
}
