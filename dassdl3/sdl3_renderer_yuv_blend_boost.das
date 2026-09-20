options gen2
module sdl3_renderer_yuv_blend_boost shared public
require dassdl3/sdl3_texture_transfer_boost public

def public render_draw_color(renderer : SDL_Renderer?; var r,g,b,a : float&) : bool {return SDL_GetRenderDrawColorFloatRef(renderer,r,g,b,a)}
def public render_draw_color_bytes(renderer : SDL_Renderer?; var r,g,b,a : uint&) : bool {return SDL_GetRenderDrawColorRef(renderer,r,g,b,a)}
def public render_color_scale(renderer : SDL_Renderer?; var scale : float&) : bool {return SDL_GetRenderColorScaleRef(renderer,scale)}
def public render_draw_blend_mode(renderer : SDL_Renderer?; var mode : uint&) : bool {return SDL_GetRenderDrawBlendModeRef(renderer,mode)}
def public update_yuv_texture(texture : SDL_Texture?; y : array<uint8>; yp : int; u : array<uint8>; up : int; v : array<uint8>; vp : int) : bool {return SDL_UpdateYUVTextureArrays(texture,y,yp,u,up,v,vp)}
def public update_nv_texture(texture : SDL_Texture?; y : array<uint8>; yp : int; uv : array<uint8>; uvp : int) : bool {return SDL_UpdateNVTextureArrays(texture,y,yp,uv,uvp)}
