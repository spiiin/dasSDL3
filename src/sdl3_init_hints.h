#pragma once
#include "daScript/daScript.h"
#include <SDL3/SDL.h>
#include <limits>
// Caller must serialize setters with lookup AND copying. SDL exposes no lock
// spanning this operation; a copied result only extends lifetime after return.
namespace sdl3_init_hints {
inline char * copy(const char * value,das::Context * context,das::LineInfoArg * at) {
    if(!value)return nullptr;
    const size_t size=SDL_strlen(value);
    if(size>std::numeric_limits<uint32_t>::max()) {
        SDL_SetError("SDL string exceeds daScript string length"); return nullptr;
    }
    return context->allocateString(value,uint32_t(size),at);
}
}
inline char * SDL_GetHintCopy(const char * name,das::Context * context,das::LineInfoArg * at) {
    return sdl3_init_hints::copy(SDL_GetHint(name),context,at);
}
inline char * SDL_GetAppMetadataPropertyCopy(const char * name,das::Context * context,das::LineInfoArg * at) {
    return sdl3_init_hints::copy(SDL_GetAppMetadataProperty(name),context,at);
}
inline bool SDL_ClearAppMetadataProperty(const char * name) {
    return SDL_SetAppMetadataProperty(name,nullptr);
}
