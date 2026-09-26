options gen2
require sdl3
require sdl3_image

// Native fixture observes actual SDL_IOStream close callbacks after this call.
[export]
def consume(io : SDL_IOStream?; renderer : SDL_Renderer?; mode : int; closeio : bool) : bool {
    if (mode < 2) {
        var surface = mode == 0 ? IMG_Load_IO(io, closeio) : IMG_LoadTyped_IO(io, closeio, "PNG")
        let success = surface != null
        if (success) { SDL_DestroySurface(surface) }
        return success
    }
    if (mode < 4) {
        var texture = mode == 2 ? IMG_LoadTexture_IO(renderer, io, closeio) : IMG_LoadTextureTyped_IO(renderer, io, closeio, "PNG")
        let success = texture != null
        if (success) { SDL_DestroyTexture(texture) }
        return success
    }
    var animation = mode == 4 ? IMG_LoadAnimation_IO(io, closeio) : IMG_LoadAnimationTyped_IO(io, closeio, "GIF")
    let success = animation != null
    if (success) { IMG_FreeAnimation(animation) }
    return success
}
