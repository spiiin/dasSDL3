options gen2
module sdl3_image_boost shared public
require sdl3_image public
require dassdl3/sdl3_result public
require daslib/defer

// IO overloads borrow the stream (closeio=false). Use an outer with_io scope.
// Path/factory results are owned by the caller; with_* scopes destroy them.

def public load_image(path : string) {
    var value = IMG_Load(path)
    if (value == null) { return err(sdl_error("IMG_Load"),type<SDL_Surface?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_image(path : string; blk : block<(value : SDL_Surface?) : $Result<auto(TT); SdlError>>) {
    var loaded = load_image(path)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TT>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TT; SdlError>
    {
        defer() { SDL_DestroySurface(value) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public load_image(io : SDL_IOStream?; kind : string = "") {
    var value = (kind == "" ? IMG_Load_IO(io,false) : IMG_LoadTyped_IO(io,false,kind))
    if (value == null) { return err(sdl_error("IMG_Load"),type<SDL_Surface?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_image(io : SDL_IOStream?; blk : block<(value : SDL_Surface?) : $Result<auto(TT); SdlError>>) {
    var loaded = load_image(io)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TT>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TT; SdlError>
    {
        defer() { SDL_DestroySurface(value) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public load_image_texture(renderer : SDL_Renderer?; path : string) {
    var value = IMG_LoadTexture(renderer,path)
    if (value == null) { return err(sdl_error("IMG_LoadTexture"),type<SDL_Texture?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_image_texture(renderer : SDL_Renderer?; path : string; blk : block<(value : SDL_Texture?) : $Result<auto(TT); SdlError>>) {
    var loaded = load_image_texture(renderer,path)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TT>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TT; SdlError>
    {
        defer() { SDL_DestroyTexture(value) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public load_image_texture(renderer : SDL_Renderer?; io : SDL_IOStream?; kind : string = "") {
    var value = (kind == "" ? IMG_LoadTexture_IO(renderer,io,false) : IMG_LoadTextureTyped_IO(renderer,io,false,kind))
    if (value == null) { return err(sdl_error("IMG_LoadTexture"),type<SDL_Texture?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_image_texture(renderer : SDL_Renderer?; io : SDL_IOStream?; blk : block<(value : SDL_Texture?) : $Result<auto(TT); SdlError>>) {
    var loaded = load_image_texture(renderer,io)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TT>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TT; SdlError>
    {
        defer() { SDL_DestroyTexture(value) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public load_image_animation(path : string) {
    var value = IMG_LoadAnimation(path)
    if (value == null) { return err(sdl_error("IMG_LoadAnimation"),type<IMG_Animation?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_image_animation(path : string; blk : block<(value : IMG_Animation?) : $Result<auto(TT); SdlError>>) {
    var loaded = load_image_animation(path)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TT>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TT; SdlError>
    {
        defer() { IMG_FreeAnimation(value) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public load_image_animation(io : SDL_IOStream?; kind : string = "") {
    var value = (kind == "" ? IMG_LoadAnimation_IO(io,false) : IMG_LoadAnimationTyped_IO(io,false,kind))
    if (value == null) { return err(sdl_error("IMG_LoadAnimation"),type<IMG_Animation?>) }
    return <- move_ok(value,type<SdlError>)
}

def public with_image_animation(io : SDL_IOStream?; blk : block<(value : IMG_Animation?) : $Result<auto(TT); SdlError>>) {
    var loaded = load_image_animation(io)
    if (is_err(loaded)) { return err(unwrap_err(loaded),type<TT>) }
    var value <- move_unwrap(loaded)
    var result : $Result<TT; SdlError>
    {
        defer() { IMG_FreeAnimation(value) }
        static_if (typeinfo can_copy(type<$Result<TT; SdlError>>)) { result = blk(value) }
        else { result <- blk(value) }
    }
    return <- result
}

def public save_image_png(surface : SDL_Surface?; path : string) {
    return sdl_status(IMG_SavePNG(surface,path),"IMG_SavePNG")
}

def public save_image_png(surface : SDL_Surface?; io : SDL_IOStream?) {
    return sdl_status(IMG_SavePNG_IO(surface,io,false),"IMG_SavePNG")
}

def public save_image_jpg(surface : SDL_Surface?; path : string; quality : int = 90) {
    return sdl_status(IMG_SaveJPG(surface,path,quality),"IMG_SaveJPG")
}

def public save_image_jpg(surface : SDL_Surface?; io : SDL_IOStream?; quality : int = 90) {
    return sdl_status(IMG_SaveJPG_IO(surface,io,false,quality),"IMG_SaveJPG")
}

def public save_image_avif(surface : SDL_Surface?; path : string; quality : int = 90) {
    return sdl_status(IMG_SaveAVIF(surface,path,quality),"IMG_SaveAVIF")
}

def public save_image_avif(surface : SDL_Surface?; io : SDL_IOStream?; quality : int = 90) {
    return sdl_status(IMG_SaveAVIF_IO(surface,io,false,quality),"IMG_SaveAVIF")
}

// Frame lifetime is bounded by the animation. Never destroy it separately.
def public image_animation_frame(animation : IMG_Animation?; index : int) {
    var frame = IMG_AnimationFrame(animation,index)
    if (frame == null) { return err(sdl_error("IMG_AnimationFrame"),type<SDL_Surface?>) }
    return <- move_ok(frame,type<SdlError>)
}
def public image_animation_delay(animation : IMG_Animation?; index : int) {
    let delay = IMG_AnimationDelay(animation,index)
    if (delay < 0) { return err(sdl_error("IMG_AnimationDelay"),type<int>) }
    return ok(delay,type<SdlError>)
}
