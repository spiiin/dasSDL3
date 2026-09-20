options gen2
module sdl3_surface_state_boost shared public
require dassdl3/sdl3_window_io_boost public

def public surface_color_key(surface : SDL_Surface?; var key : uint&) : bool {return SDL_GetSurfaceColorKeyRef(surface,key)}
def public surface_color_mod(surface : SDL_Surface?; var r,g,b : uint&) : bool {return SDL_GetSurfaceColorModRef(surface,r,g,b)}
def public surface_alpha_mod(surface : SDL_Surface?; var a : uint&) : bool {return SDL_GetSurfaceAlphaModRef(surface,a)}
def public surface_blend_mode(surface : SDL_Surface?; var mode : uint&) : bool {return SDL_GetSurfaceBlendModeRef(surface,mode)}
def public surface_clip(surface : SDL_Surface?; var rect : SDL_Rect) : bool {return SDL_GetSurfaceClipRectRef(surface,rect)}
def public set_surface_clip(surface : SDL_Surface?; rect : SDL_Rect) : bool {return SDL_SetSurfaceClipRectRef(surface,rect)}
def public reset_surface_clip(surface : SDL_Surface?) : bool {return SDL_ResetSurfaceClipRect(surface)}
