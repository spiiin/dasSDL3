#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <cmath>
int main(int, char**) {
    if (!SDL_Init(SDL_INIT_VIDEO)) { SDL_Log("%s", SDL_GetError()); return 1; }
    SDL_Window* window = nullptr;
    SDL_Renderer* renderer = nullptr;
    if (!SDL_CreateWindowAndRenderer("SDL3 test - Escape to exit", 800, 600, SDL_WINDOW_RESIZABLE, &window, &renderer)) {
        SDL_Log("%s", SDL_GetError()); SDL_Quit(); return 1;
    }
    bool running = true;
    while (running) {
        SDL_Event event;
        while (SDL_PollEvent(&event)) {
            if (event.type == SDL_EVENT_QUIT || (event.type == SDL_EVENT_KEY_DOWN && event.key.key == SDLK_ESCAPE)) running = false;
        }
        SDL_SetRenderDrawColor(renderer, 24, 28, 40, 255);
        SDL_RenderClear(renderer);
        SDL_FRect square{360.0f + 200.0f * std::sin(static_cast<float>(SDL_GetTicks()) / 1000.0f), 260.0f, 80.0f, 80.0f};
        SDL_SetRenderDrawColor(renderer, 70, 200, 160, 255);
        SDL_RenderFillRect(renderer, &square);
        SDL_RenderPresent(renderer);
        SDL_Delay(16);
    }
    SDL_DestroyRenderer(renderer);
    SDL_DestroyWindow(window);
    SDL_Quit();
    return 0;
}
