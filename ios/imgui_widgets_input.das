options gen2
require dassdl3/sdl3_imgui_widgets

var expected : string
var erased = false

[export]
def input_frame(renderer : SDL_Renderer?; bounds : SDL_FRect const&; focus : bool; var field : SDL_FRect&) : int {
    imgui_widgets_new_frame()
    SetNextWindowPos(ImVec2(bounds.x, bounds.y), ImGuiCond.Always, ImVec2(0.0, 0.0))
    SetNextWindowSize(ImVec2(bounds.w, bounds.h), ImGuiCond.Always)
    var active = false
    var passed = false
    window(KEYBOARD, (text = "dasImgui v2 keyboard", closable = false,
                      flags = ImGuiWindowFlags.NoMove | ImGuiWindowFlags.NoResize | ImGuiWindowFlags.NoCollapse)) {
        text("Type caféx or приветт.")
        text("Press Backspace, then Return.")
        if (focus) { SetKeyboardFocusHere(0) }
        input_text_multiline(WORD, (text = "##word", size = float2(-1.0, 64.0)))
        active = IsItemActive()
        let low = GetItemRectMin()
        let high = GetItemRectMax()
        field.x = low.x
        field.y = low.y
        field.w = high.x - low.x
        field.h = high.y - low.y
        let value = WORD.value
        if (value == "caféx" || value == "приветт") {
            if (empty(expected)) { print("dasImgui v2 widget received the full UTF-8 sample\n") }
            expected = value == "caféx" ? "café" : "привет"
            erased = false
        } elif (!empty(expected)) {
            if (value == expected && !erased) {
                erased = true
                print("dasImgui v2 widget removed the final character\n")
            }
            passed = erased && value == expected + "\n"
        }
    }
    imgui_widgets_render(renderer)
    // Match ImGuiInputFrame: Inactive, Active, Passed.
    return passed ? 2 : (active ? 1 : 0)
}
