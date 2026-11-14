#pragma once

#include <SDL3/SDL.h>
#include <functional>

enum class ImGuiInputFrame { Inactive, Active, Passed, Failed };
using ImGuiInputDraw = std::function<ImGuiInputFrame(SDL_Renderer *, const SDL_FRect &, bool, SDL_FRect &)>;

bool startImGuiInput(ImGuiInputDraw draw = {});
bool passImGuiInputEvent(const SDL_Event &event);
SDL_AppResult drawImGuiInput();
void stopImGuiInput();
