options gen2
module sdl3_pixels_boost shared public
require dassdl3/sdl3_boost public

[inline]
def private pixel_check(ok : bool; operation : string) {
    if (!ok) { panic("{operation}: {SDL_GetError()}") }
}

// Positive dimensions; byte pitch includes optional row padding. Maximum INT_MAX.
def public rgba8_buffer_size(width, height, pitch : int) : int {
    let size = SDL_RGBA8BufferSize(width, height, pitch)
    pixel_check(size >= 0, "rgba8_buffer_size")
    return size
}

def private with_rgba8_texture(renderer : SDL_Renderer?; width, height : int; target : bool;
                              blk : block<(texture : SDL_Texture?) : void>) {
    let texture = SDL_CreateRGBA8Texture(renderer, width, height, target)
    pixel_check(texture != null, "create_rgba8_texture")
    SDL_ScopeTexture(texture,blk)
}

def public with_streaming_texture(renderer : SDL_Renderer?; width, height : int;
                                 blk : block<(texture : SDL_Texture?) : void>) {
    with_rgba8_texture(renderer, width, height, false, blk)
}

def public with_target_texture(renderer : SDL_Renderer?; width, height : int;
                              blk : block<(texture : SDL_Texture?) : void>) {
    with_rgba8_texture(renderer, width, height, true, blk)
}

// Copies the whole image synchronously; no pointer or lock escapes to script.
def public upload_rgba8(texture : SDL_Texture?; bytes : array<uint8>; pitch : int) {
    pixel_check(SDL_UploadRGBA8(texture, bytes, pitch), "upload_rgba8")
}

// Nest inside the lifetime of both targets; null selects the window.
// SDL restores per-target viewport/clip/scale; draw color is not scope-owned.
def public with_render_target(renderer : SDL_Renderer?; texture : SDL_Texture?;
                              blk : block<() : void>) {
    verify(renderer != null, "with_render_target: null renderer")
    let previous = SDL_GetRenderTarget(renderer)
    pixel_check(SDL_SetRenderTarget(renderer, texture), "SDL_SetRenderTarget")
    SDL_ScopeRenderTarget(renderer,previous,blk)
}

// Owns the readback surface. For the window call before present().
def public with_read_pixels(renderer : SDL_Renderer?; blk : block<(surface : SDL_Surface?) : void>) {
    let surface = SDL_ReadPixelsOwned(renderer)
    pixel_check(surface != null, "SDL_RenderReadPixels")
    SDL_ScopeSurface(surface,blk)
}

def public surface_size(surface : SDL_Surface?) : int2 {
    var width, height : int
    pixel_check(SDL_SurfaceSizeRef(surface, width, height), "surface_size")
    return int2(width, height)
}

// Converts to byte RGBA and copies into caller-owned storage; padding is untouched.
def public copy_surface_rgba8(surface : SDL_Surface?; var bytes : array<uint8>; pitch : int) {
    pixel_check(SDL_CopySurfaceRGBA8(surface, bytes, pitch), "copy_surface_rgba8")
}
