#pragma once
// Test-only observers: SDL property destruction records actual resource cleanup.
// Never query a stale handle. These symbols are absent with BUILD_TESTING=OFF.
namespace sdl3_test {
inline int trace = 0;
inline int surface_tag = 1;
inline int texture_tag = 2;
inline void SDLCALL destroyed(void * userdata, void *) {
    trace = trace * 10 + *static_cast<int *>(userdata);
}
inline void reset() { trace = 0; }
inline int cleanup_trace() { return trace; }
inline bool watch_surface(SDL_Surface * surface) {
    return SDL_SetPointerPropertyWithCleanup(SDL_GetSurfaceProperties(surface),
        "dassdl3.test.cleanup", &surface_tag, destroyed, &surface_tag);
}
inline bool watch_texture(SDL_Texture * texture) {
    return SDL_SetPointerPropertyWithCleanup(SDL_GetTextureProperties(texture),
        "dassdl3.test.cleanup", &texture_tag, destroyed, &texture_tag);
}
inline bool check_corner(SDL_Renderer * renderer) {
    SDL_Surface * pixels = SDL_RenderReadPixels(renderer, nullptr);
    if (!pixels) return false;
    Uint8 r = 0, g = 0, b = 0, a = 0;
    bool ok = SDL_ReadSurfacePixel(pixels, 0, 0, &r, &g, &b, &a);
    SDL_DestroySurface(pixels);
    return ok && r == 245 && g == 190 && b == 60;
}
}
