options gen2
require daslib/defer
module sdl3_texture_transfer_boost shared public
require dassdl3/sdl3_texture_state_boost public

def public texture_color_mod_bytes(texture : SDL_Texture?; var r,g,b : uint&) {return sdl_status(SDL_GetTextureColorModRef(texture,r,g,b), "texture_color_mod_bytes")}
def public texture_alpha_mod_byte(texture : SDL_Texture?; var a : uint&) {return sdl_status(SDL_GetTextureAlphaModRef(texture,a), "texture_alpha_mod_byte")}
def public texture_blend_mode(texture : SDL_Texture?; var mode : uint&) {return sdl_status(SDL_GetTextureBlendModeRef(texture,mode), "texture_blend_mode")}
def public update_texture_rgba8(texture : SDL_Texture?; rect : SDL_Rect; bytes : array<uint8>; pitch : int) {
    return sdl_status(SDL_UpdateTextureRGBA8(texture,rect,bytes,pitch),"update_texture_rgba8")
}
// Borrowed, write-only surface. Initialize the entire locked region before unlock.
def public with_texture_surface(texture : SDL_Texture?; rect : SDL_Rect; blk : block<(surface : SDL_Surface?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    var surface : SDL_Surface?
    if(!SDL_LockTextureToSurfaceRef(texture,rect,surface)) {return err(sdl_error("with_texture_surface"), type<TT>)}
    {defer(){SDL_UnlockTexture(texture)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(surface) } else { scope_result <- blk(surface) }}

    return <- scope_result
}

def public texture_color_mod_bytes(texture : SDL_Texture?) {
    var r : uint
    var g : uint
    var b : uint
    let status = texture_color_mod_bytes(texture,r,g,b)
    if (is_err(status)) { return err(unwrap_err(status),type<uint3>) }
    var value = uint3(r,g,b)
    return <- move_ok(value,type<SdlError>)
}

def public texture_alpha_mod_byte(texture : SDL_Texture?) {
    var a : uint
    let status = texture_alpha_mod_byte(texture,a)
    if (is_err(status)) { return err(unwrap_err(status),type<uint>) }
    var value = a
    return <- move_ok(value,type<SdlError>)
}

def public texture_blend_mode(texture : SDL_Texture?) {
    var mode : uint
    let status = texture_blend_mode(texture,mode)
    if (is_err(status)) { return err(unwrap_err(status),type<uint>) }
    var value = mode
    return <- move_ok(value,type<SdlError>)
}
