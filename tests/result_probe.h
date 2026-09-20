#pragma once
namespace sdl3_test {
inline void result_states(bool pending,bool unavailable) {
    SDL_TestReadbackPending=pending;SDL_TestSwapchainUnavailable=unavailable;
}
}
