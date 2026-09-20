#pragma once
#include <SDL3/SDL.h>
#include <string>

inline bool SDL_SetErrorMessage(const char * message) { return SDL_SetError("%s",message); }

inline SDL_Texture * SDL_LoadBMPTextureOwned(SDL_Renderer * renderer,const char * path) {
    if (!renderer) { SDL_SetError("load_texture: null renderer"); return nullptr; }
    auto * surface=SDL_LoadBMP(path); if (!surface) return nullptr;
    auto * texture=SDL_CreateTextureFromSurface(renderer,surface);
    // Destruction must not replace a creation failure's SDL error.
    if (!texture) {
        const std::string error=SDL_GetError();
        SDL_DestroySurface(surface); SDL_SetError("%s",error.c_str());
    } else SDL_DestroySurface(surface);
    return texture;
}
