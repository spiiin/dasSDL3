#pragma once
#include <string>
#include <SDL3/SDL.h>
#include "imgui.h"
#include "backends/imgui_impl_sdl3.h"
#include "backends/imgui_impl_sdlrenderer3.h"
#include "backends/imgui_impl_sdlgpu3.h"

// Upstream registers this helper but omits its declaration from aot_dasIMGUI.h.
// Keep the compatibility declaration here; do not modify the daScript submodule.
namespace das { void DisableIniPersistence(); }

// ImGui backend functions use the current context and borrow SDL resources.
inline bool ImGui_SDL3_Init(SDL_Window* window, SDL_Renderer* renderer) {
    if (!ImGui::GetCurrentContext() || !window || !renderer || SDL_GetRenderWindow(renderer) != window)
        return SDL_SetError("ImGui requires a current context and a renderer belonging to the window");
    if (ImGui::GetIO().BackendPlatformUserData || ImGui::GetIO().BackendRendererUserData)
        return SDL_SetError("ImGui context already has a backend");
    if (!ImGui_ImplSDL3_InitForSDLRenderer(window, renderer)) return false;
    if (!ImGui_ImplSDLRenderer3_Init(renderer)) {
        const auto error = std::string(SDL_GetError());
        ImGui_ImplSDL3_Shutdown();
        return SDL_SetError("%s", error.c_str());
    }
    return true;
}
inline bool ImGui_SDL3_ProcessEvent(const SDL_Event& event) {
    return ImGui_ImplSDL3_ProcessEvent(&event);
}
inline void ImGui_SDL3_Render(SDL_Renderer* renderer) {
    ImGui_ImplSDLRenderer3_RenderDrawData(ImGui::GetDrawData(), renderer);
}
inline bool ImGui_SDL3_WantCaptureMouse() { return ImGui::GetIO().WantCaptureMouse; }
inline bool ImGui_SDL3_WantCaptureKeyboard() { return ImGui::GetIO().WantCaptureKeyboard; }

// The window must already be claimed by this device. Render into its swapchain format.
inline bool ImGui_SDL3_GPU_Init(SDL_Window* window, SDL_GPUDevice* device) {
    if (!ImGui::GetCurrentContext() || !window || !device)
        return SDL_SetError("ImGui requires a current context, window and GPU device");
    if (ImGui::GetIO().BackendPlatformUserData || ImGui::GetIO().BackendRendererUserData)
        return SDL_SetError("ImGui context already has a backend");
    ImGui_ImplSDLGPU3_InitInfo info{};
    info.Device = device;
    info.ColorTargetFormat = SDL_GetGPUSwapchainTextureFormat(device, window);
    if (info.ColorTargetFormat == SDL_GPU_TEXTUREFORMAT_INVALID) return false;
    if (!ImGui_ImplSDL3_InitForSDLGPU(window)) return false;
    if (!ImGui_ImplSDLGPU3_Init(&info)) {
        const auto error = std::string(SDL_GetError());
        ImGui_ImplSDL3_Shutdown();
        return SDL_SetError("%s", error.c_str());
    }
    return true;
}
// Call after ImGui::Render, before beginning the overlay render pass.
inline void ImGui_SDL3_GPU_Prepare(SDL_GPUCommandBuffer* command) {
    ImGui_ImplSDLGPU3_PrepareDrawData(ImGui::GetDrawData(), command);
}
inline void ImGui_SDL3_GPU_Render(SDL_GPUCommandBuffer* command, SDL_GPURenderPass* pass) {
    ImGui_ImplSDLGPU3_RenderDrawData(ImGui::GetDrawData(), command, pass);
}
