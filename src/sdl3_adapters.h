#pragma once
#include <SDL3/SDL.h>

// SDL uses these addresses only for the duration of each synchronous call.
// References avoid taking addresses of borrowed script arguments with safe_addr.
inline bool SDL_PollEventRef(SDL_Event & event) { return SDL_PollEvent(&event); }
inline bool SDL_PushEventRef(SDL_Event & event) { return SDL_PushEvent(&event); }
inline bool SDL_RenderFillRectRef(SDL_Renderer * renderer, const SDL_FRect & rect) {
    return SDL_RenderFillRect(renderer, &rect);
}
inline bool SDL_GetTextureSizeRef(SDL_Texture * texture, float & w, float & h) {
    return SDL_GetTextureSize(texture, &w, &h);
}
inline bool SDL_RenderTextureToRect(SDL_Renderer * renderer, SDL_Texture * texture,
                                    const SDL_FRect & dst) {
    return SDL_RenderTexture(renderer, texture, nullptr, &dst);
}
inline bool SDL_RenderTextureRects(SDL_Renderer * renderer, SDL_Texture * texture,
                                   const SDL_FRect & src, const SDL_FRect & dst) {
    return SDL_RenderTexture(renderer, texture, &src, &dst);
}

// Value factories avoid uninitialized union storage in scripts.
inline SDL_Event SDL_MakeEvent() { return SDL_Event{}; }
inline SDL_FRect SDL_MakeFRect(float x, float y, float w, float h) { return {x, y, w, h}; }
inline bool SDL_EventIsQuit(const SDL_Event & event) { return event.type == SDL_EVENT_QUIT; }
inline bool SDL_EventIsEscape(const SDL_Event & event) {
    return event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_ESCAPE;
}
inline SDL_Event SDL_MakeKeyEvent(uint32_t type, uint32_t key) {
    SDL_Event event{};
    event.type = type;
    if (type == SDL_EVENT_KEY_DOWN || type == SDL_EVENT_KEY_UP) event.key.key = key;
    return event;
}
