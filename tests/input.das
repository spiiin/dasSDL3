options gen2
require dassdl3/sdl3_boost
require daslib/rtti
require daslib/strings_boost

def queue_input(kind, id : uint) {
    var event = SDLTestInputEvent(kind, id)
    push_event(event)
}

[export]
def main(smoke : bool) : int {
    verify(smoke)
    let scope_ok_0 = with_sdl() {
        let scope_ok_1 = with_window("input tests", 128, 128, SDL_WINDOW_HIDDEN) $(window) {
            let id = SDL_GetWindowID(window)
            verify(!SDL_TextInputActive(window))
            for (mode in range(3)) {
                var caught = false
                var error = ""
                {
                    let scope_ok_2 = with_text_input(window) {
                        verify(SDL_TextInputActive(window))
                        // Inner scope must not stop a session owned by the outer one.
                        let scope_ok_3 = with_text_input(window) { verify(SDL_TextInputActive(window)) }
                        verify(scope_ok_3)
                        verify(SDL_TextInputActive(window))
                        if (mode == 1) { return }
                        if (mode == 2) { caught = !set_title(null,"expected SDL failure"); return }
                    }
                    verify(scope_ok_2)
                }
                verify(caught == (mode == 2))

                verify(!SDL_TextInputActive(window), "text input survived its scope")
                verify(SDL_GetWindowID(window) == id, "outer block argument corrupted")
            }
            verify(SDL_StartTextInput(window))
            let scope_ok_4 = with_text_input(window) { verify(SDL_TextInputActive(window)) }
            verify(scope_ok_4)
            verify(SDL_TextInputActive(window), "borrowed text session stopped")
            verify(SDL_StopTextInput(window))
            let scope_ok_5 = with_text_input(window) {
                var caught = false
                { with_text_input(window) { caught = !set_title(null,"expected SDL failure"); return } }
                verify(caught && SDL_TextInputActive(window), "inner return stopped outer input")
                verify(SDL_GetWindowID(window) == id, "nested return corrupted window")
            }
            verify(scope_ok_5)
            verify(!SDL_TextInputActive(window))

            var key : SDL_KeyboardEvent
            var motion : SDL_MouseMotionEvent
            var button : SDL_MouseButtonEvent
            var wheel : SDL_MouseWheelEvent
            var text = ""
            var editing = ""
            var start, length : int
            var event = SDL_MakeEvent()
            let direct = SDLTestInputEvent(SDL_EVENT_TEXT_INPUT, id)
            verify(SDL_ReadTextInput(direct, text))
            if (text != "Привет 🌍") { panic("direct text: [{text}]") }
            verify(text_input_event(direct, text))
            if (text != "Привет 🌍") { panic("wrapped text: [{text}]") }
            text = ""
            // Drain platform startup events before injecting deterministic input.
            while (poll_event(event)) { }
            let scope_ok_6 = with_text_input(window) {
                queue_input(SDL_EVENT_KEY_DOWN, id)
                queue_input(SDL_EVENT_KEY_UP, id)
                queue_input(SDL_EVENT_MOUSE_MOTION, id)
                queue_input(SDL_EVENT_MOUSE_BUTTON_DOWN, id)
                queue_input(SDL_EVENT_MOUSE_BUTTON_UP, id)
                queue_input(SDL_EVENT_MOUSE_WHEEL, id)
                queue_input(SDL_EVENT_TEXT_INPUT, id)
                queue_input(SDL_EVENT_TEXT_EDITING, id)
                var seen = 0
                while (poll_event(event)) {
                    if (input_window_id(event) != id) { continue }
                    if (key_event(event, key)) {
                        verify(key.which == 4242u)
                        verify(key_scancode(key) == SDL_SCANCODE_A)
                        verify(uint(key.mod) == SDL_KMOD_CTRL && uint(key.raw) == 30u)
                        verify(key.down == (event.event_type == SDL_EVENT_KEY_DOWN))
                        verify(key.repeat == key.down)
                        seen += key.down ? 1 : 2
                    }
                    if (mouse_motion_event(event, motion)) {
                        verify(motion.x == 12.5 && motion.y == 24.5)
                        verify(motion.xrel == -2.0 && motion.yrel == 3.0)
                        verify(motion.state == SDL_BUTTON_LMASK)
                        seen += 4
                    }
                    if (mouse_button_event(event, button)) {
                        verify(uint(button.button) == SDL_BUTTON_LEFT && uint(button.clicks) == 2u)
                        verify(button.x == 12.5 && button.y == 24.5)
                        verify(button.down == (event.event_type == SDL_EVENT_MOUSE_BUTTON_DOWN))
                        seen += button.down ? 8 : 16
                    }
                    if (mouse_wheel_event(event, wheel)) {
                        let delta = wheel_delta(wheel)
                        verify(delta.x == -1.5 && delta.y == 2.5)
                        verify(wheel.integer_x == 1 && wheel.integer_y == -2)
                        verify(wheel.mouse_x == 12.5 && wheel.mouse_y == 24.5)
                        seen += 32
                    }
                    // Decode only these types here: mismatches deliberately clear output.
                    if (event.event_type == SDL_EVENT_TEXT_INPUT) {
                        verify(text_input_event(event, text))
                        if (text != "Привет 🌍") { panic("unexpected input: [{text}]") }
                        seen += 64
                    }
                    if (event.event_type == SDL_EVENT_TEXT_EDITING) {
                        verify(text_editing_event(event, editing, start, length))
                        if (editing != "日本" || start != 1 || length != 1) { panic("editing [{editing}] start={start} length={length}") }
                        seen += 128
                    }
                }
                verify(seen == 255, "input queue lost or duplicated events")
            }
            verify(scope_ok_6)
            // Native event text memory changes; retained script strings must not change.
            SDLTestMutateInputText()
            verify(text == "Привет 🌍" && editing == "日本", "event text was borrowed")
            var wrong = SDLTestPoisonEvent()
            key.key = 999u
            motion.x = 99.0
            button.x = 99.0
            wheel.y = 99.0
            verify(!key_event(wrong, key) && key.key == 0u)
            verify(!mouse_motion_event(wrong, motion) && motion.x == 0.0)
            verify(!mouse_button_event(wrong, button) && button.x == 0.0)
            verify(!mouse_wheel_event(wrong, wheel) && wheel.y == 0.0)
            verify(!text_input_event(wrong, text) && text == "")
            verify(!text_editing_event(wrong, editing, start, length))
            verify(editing == "" && start == 0 && length == 0)
            verify(input_window_id(wrong) == 0u && should_close(wrong, window))
            verify(!key_down(-1) && !key_down(SDL_SCANCODE_COUNT))
            var position = float2(-1000000.0, -1000000.0)
            let buttons = mouse_state(position)
            verify(position.x != -1000000.0 && position.y != -1000000.0, "mouse output passed by value")
            window |> set_title("input tests complete")
            let scope_ok_7 = with_window("other window", 64, 64, SDL_WINDOW_HIDDEN) $(other) {
                let close = SDLTestInputEvent(SDL_EVENT_WINDOW_CLOSE_REQUESTED, SDL_GetWindowID(other))
                verify(!should_close(close, window) && should_close(close, other))
            }
            verify(scope_ok_7)
        }
        verify(scope_ok_1)
    }
    verify(scope_ok_0)
    verify(SDL_WasInit(SDL_INIT_VIDEO) == 0u)
    print("Input: typed events, UTF-8 copy, union guards, routing and scoped text input: OK\n")
    return 0
}
