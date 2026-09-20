options gen2
module sdl3_geometry_boost shared public
require dassdl3/sdl3_boost public

// Positions in pixels; RGBA and UV in 0..1. Draw validates even directly edited vertices.
def public vertex(position : float2; rgba : float4; uv : float2 = float2(0.0)) : SDL_Vertex {
    return SDL_MakeVertex(position.x, position.y, rgba.x, rgba.y, rgba.z, rgba.w, uv.x, uv.y)
}

def public draw_geometry(renderer : SDL_Renderer?; vertices : array<SDL_Vertex>; texture : SDL_Texture? = null) {
    return SDL_RenderGeometryVertices(renderer, texture, vertices)
}

def public draw_geometry(renderer : SDL_Renderer?; vertices : array<SDL_Vertex>;
                         indices : array<int>; texture : SDL_Texture? = null) {
    return SDL_RenderGeometryIndices(renderer, texture, vertices, indices)
}
