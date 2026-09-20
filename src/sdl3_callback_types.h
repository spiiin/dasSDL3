#pragma once
#include <SDL3/SDL.h>
#include "daScript/daScript.h"
struct SDL_HitTestBinding {
    SDL_Window * window=nullptr;
    das::Block callback;
    das::Context * context=nullptr;
    das::LineInfoArg * at=nullptr;
    bool active=false;
};
