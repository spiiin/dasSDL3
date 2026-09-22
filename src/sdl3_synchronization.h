#pragma once
#include <SDL3/SDL.h>
// State must stay at a stable address across initialization transitions.
inline bool SDL_ShouldInitRef(SDL_InitState & state) {return SDL_ShouldInit(&state);}
inline bool SDL_ShouldQuitRef(SDL_InitState & state) {return SDL_ShouldQuit(&state);}
inline void SDL_SetInitializedRef(SDL_InitState & state,bool initialized) {SDL_SetInitialized(&state,initialized);}
