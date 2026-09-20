options gen2
module sdl3_renderer_final_boost shared public
require dassdl3/sdl3_renderer_operations_boost public

def public convert_event_to_render(renderer : SDL_Renderer?; var event : SDL_Event) {return sdl_status(SDL_ConvertEventToRenderCoordinatesRef(renderer,event), "convert_event_to_render")}
def public render_geometry_raw(renderer : SDL_Renderer?; texture : SDL_Texture?; xy : array<SDL_FPoint>; colors : array<SDL_FColor>; uv : array<SDL_FPoint>) {return sdl_status(SDL_RenderGeometryRawArrays(renderer,texture,xy,colors,uv), "render_geometry_raw")}
def public render_geometry_raw(renderer : SDL_Renderer?; texture : SDL_Texture?; xy : array<SDL_FPoint>; colors : array<SDL_FColor>; uv : array<SDL_FPoint>; indices : array<int>) {return sdl_status(SDL_RenderGeometryRawIndexedArrays(renderer,texture,xy,colors,uv,indices), "render_geometry_raw")}
