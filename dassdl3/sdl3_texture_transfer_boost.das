options gen2
require daslib/defer
module sdl3_texture_transfer_boost shared public
require dassdl3/sdl3_texture_state_boost public

def public texture_color_mod_bytes(texture : SDL_Texture?; var r,g,b : uint&) : bool {return SDL_GetTextureColorModRef(texture,r,g,b)}
def public texture_alpha_mod_byte(texture : SDL_Texture?; var a : uint&) : bool {return SDL_GetTextureAlphaModRef(texture,a)}
def public texture_blend_mode(texture : SDL_Texture?; var mode : uint&) : bool {return SDL_GetTextureBlendModeRef(texture,mode)}
def public update_texture_rgba8(texture : SDL_Texture?; rect : SDL_Rect; bytes : array<uint8>; pitch : int) : bool {return SDL_UpdateTextureRGBA8(texture,rect,bytes,pitch)}
// Borrowed, write-only surface. Initialize the entire locked region before unlock.
def public with_texture_surface(texture : SDL_Texture?; rect : SDL_Rect; blk : block<(surface : SDL_Surface?) : void>) : bool {
    var surface : SDL_Surface?
    if(!SDL_LockTextureToSurfaceRef(texture,rect,surface)) {return false}
    {defer(){SDL_UnlockTexture(texture)};blk(surface);return true}
}
