options gen2
require imgui

// Called by the native input fixture with real SDL events fed to the backend.
[export]
def draw : bool {
    SetNextWindowPos(ImVec2(0.0, 0.0), ImGuiCond.Always, ImVec2(0.0, 0.0))
    SetNextWindowSize(ImVec2(300.0, 200.0), ImGuiCond.Always)
    var clicked = false
    if (Begin("Input test")) {
        clicked = Button("SDL click", ImVec2(120.0, 50.0))
    }
    End()
    return clicked
}
