#pragma once
#include "daScript/daScript.h"
#include <SDL3_image/SDL_image.h>
static_assert(SDL_IMAGE_VERSION == 3002004, "Review bindings when updating SDL_image");

// Returned frame is borrowed from the animation, never destroyed separately.
inline SDL_Surface* IMG_AnimationFrame(IMG_Animation* animation, int index) {
    if (!animation || index < 0 || index >= animation->count || !animation->frames) {
        SDL_SetError("Animation frame index out of bounds"); return nullptr;
    }
    return animation->frames[index];
}
inline int IMG_AnimationDelay(IMG_Animation* animation, int index) {
    if (!animation || index < 0 || index >= animation->count || !animation->delays) {
        SDL_SetError("Animation delay index out of bounds"); return -1;
    }
    return animation->delays[index];
}
