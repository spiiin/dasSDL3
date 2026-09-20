options gen2
require daslib/defer
module sdl3_texture_state_boost shared public
require dassdl3/sdl3_renderer_state_boost public
require dassdl3/sdl3_properties_boost public

def public with_texture(renderer : SDL_Renderer?; format : SDL_PixelFormat; access : SDL_TextureAccess; w,h : int; blk : block<(texture : SDL_Texture?) : void>) : bool {
    let texture=SDL_CreateTexture(renderer,format,access,w,h)
    if(texture==null) {return false}
    {defer(){SDL_DestroyTexture(texture)};blk(texture);return true}
}
def public with_texture_properties(renderer : SDL_Renderer?; props : uint; blk : block<(texture : SDL_Texture?) : void>) : bool {
    let texture=SDL_CreateTextureWithProperties(renderer,props)
    if(texture==null) {return false}
    {defer(){SDL_DestroyTexture(texture)};blk(texture);return true}
}
def public texture_color_mod(texture : SDL_Texture?; var r,g,b : float&) : bool {return SDL_GetTextureColorModFloatRef(texture,r,g,b)}
def public texture_alpha_mod(texture : SDL_Texture?; var a : float&) : bool {return SDL_GetTextureAlphaModFloatRef(texture,a)}
def public texture_scale_mode(texture : SDL_Texture?; var mode : SDL_ScaleMode&) : bool {return SDL_GetTextureScaleModeRef(texture,mode)}
