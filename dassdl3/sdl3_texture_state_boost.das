options gen2
require daslib/defer
module sdl3_texture_state_boost shared public
require dassdl3/sdl3_renderer_state_boost public
require dassdl3/sdl3_properties_boost public

def public with_texture(renderer : SDL_Renderer?; format : SDL_PixelFormat; access : SDL_TextureAccess; w,h : int; blk : block<(texture : SDL_Texture?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let texture=SDL_CreateTexture(renderer,format,access,w,h)
    if(texture==null) {return err(sdl_error("with_texture"), type<TT>)}
    {defer(){SDL_DestroyTexture(texture)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(texture) } else { scope_result <- blk(texture) }}

    return <- scope_result
}
def public with_texture_properties(renderer : SDL_Renderer?; props : uint; blk : block<(texture : SDL_Texture?) : $Result<auto(TT); SdlError> >) {
    var scope_result : $Result<TT; SdlError>

    let texture=SDL_CreateTextureWithProperties(renderer,props)
    if(texture==null) {return err(sdl_error("with_texture_properties"), type<TT>)}
    {defer(){SDL_DestroyTexture(texture)};static_if (typeinfo can_copy(type<$Result<TT; SdlError> >)) { scope_result = blk(texture) } else { scope_result <- blk(texture) }}

    return <- scope_result
}
def public texture_color_mod(texture : SDL_Texture?; var r,g,b : float&) {return sdl_status(SDL_GetTextureColorModFloatRef(texture,r,g,b), "texture_color_mod")}
def public texture_alpha_mod(texture : SDL_Texture?; var a : float&) {return sdl_status(SDL_GetTextureAlphaModFloatRef(texture,a), "texture_alpha_mod")}
def public texture_scale_mode(texture : SDL_Texture?; var mode : SDL_ScaleMode&) {return sdl_status(SDL_GetTextureScaleModeRef(texture,mode), "texture_scale_mode")}

def public texture_color_mod(texture : SDL_Texture?) {
    var r : float
    var g : float
    var b : float
    let status = texture_color_mod(texture,r,g,b)
    if (is_err(status)) { return err(unwrap_err(status),type<float3>) }
    var value = float3(r,g,b)
    return <- move_ok(value,type<SdlError>)
}

def public texture_alpha_mod(texture : SDL_Texture?) {
    var a : float
    let status = texture_alpha_mod(texture,a)
    if (is_err(status)) { return err(unwrap_err(status),type<float>) }
    var value = a
    return <- move_ok(value,type<SdlError>)
}

def public texture_scale_mode(texture : SDL_Texture?) {
    var mode : SDL_ScaleMode
    let status = texture_scale_mode(texture,mode)
    if (is_err(status)) { return err(unwrap_err(status),type<SDL_ScaleMode>) }
    var value = mode
    return <- move_ok(value,type<SdlError>)
}
