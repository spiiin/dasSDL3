options gen2
module sdl3_imgui_widgets shared public
require dassdl3/sdl3_imgui public
require imgui/imgui_boost_v2 public
require imgui/imgui_widgets_builtin public
require imgui/imgui_containers_builtin public

// Current context and its SDL backend must be initialized. Does not own resources.
def public imgui_widgets_process_event(event : SDL_Event) : bool {
    if (!user_control_enabled()) {
        let keyboard = event.event_type >= SDL_EVENT_KEY_DOWN && event.event_type <= SDL_EVENT_TEXT_EDITING_CANDIDATES
        let mouse = event.event_type >= SDL_EVENT_MOUSE_MOTION && event.event_type <= SDL_EVENT_MOUSE_REMOVED
        if (keyboard || mouse) { return false }
    }
    return ImGui_SDL3_ProcessEvent(event)
}

def public imgui_widgets_new_frame() {
    begin_frame()
    ImGui_ImplSDLRenderer3_NewFrame()
    ImGui_ImplSDL3_NewFrame()
    advance_coroutines()
    imgui_synth_tick()
    NewFrame()
}

// Finish widget hooks before Render; clear/present remain the application's choice.
def public imgui_widgets_render(renderer : SDL_Renderer?) {
    end_of_frame()
    Render()
    ImGui_SDL3_Render(renderer)
}
