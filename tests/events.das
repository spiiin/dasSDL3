options gen2
require dassdl3/sdl3_events
require daslib/match

def check(event : SdlEvent) : int {
    match (event) {
        if (SdlEvent(quit=$v(value))) {
            verify(value.timestamp == 0xfedcba9876543210ul)
            return 0
        }
        if (SdlEvent(key_down=$v(key))) {
            verify(key.window_id == 42u && key.which == 4242u && key.scancode == SDL_SCANCODE_A)
            verify(key.keycode == 97u && uint(key.modifiers) == SDL_KMOD_CTRL && key.raw == uint16(30) && key.repeat)
            verify(key.timestamp == 0xfedcba9876543210ul)
            return 1
        }
        if (SdlEvent(key_up=$v(key))) { verify(!key.repeat && key.window_id == 42u); return 2 }
        if (SdlEvent(mouse_motion=$v(mouse))) {
            verify(mouse.window_id == 42u && mouse.which == 4242u && mouse.buttons == SDL_BUTTON_LMASK)
            verify(mouse.position == float2(12.5,24.5) && mouse.delta == float2(-2.0,3.0))
            return 3
        }
        if (SdlEvent(mouse_button_down=$v(button))) {
            verify(button.window_id == 42u && button.which == 4242u && uint(button.button) == SDL_BUTTON_LEFT)
            verify(button.clicks == uint8(2) && button.position == float2(12.5,24.5)); return 4
        }
        if (SdlEvent(mouse_button_up=$v(button))) { verify(button.clicks == uint8(2)); return 5 }
        if (SdlEvent(mouse_wheel=$v(wheel))) {
            verify(wheel.window_id == 42u && wheel.which == 4242u && wheel.flipped)
            verify(wheel.delta == float2(1.5,-2.5) && wheel.integer_delta == int2(1,-2))
            verify(wheel.position == float2(12.5,24.5)); return 6
        }
        if (SdlEvent(text_input=$v(input))) {
            verify(input.window_id == 42u && input.text == "Привет 🌍" && input.timestamp == 0xfedcba9876543210ul); return 7
        }
        if (SdlEvent(text_editing=$v(edit))) {
            verify(edit.window_id == 42u && edit.text == "日本" && edit.start == 1 && edit.length == 1); return 8
        }
        if (SdlEvent(window=$v(window))) {
            verify(window.window_id == 42u && window.event_type == SDL_EVENT_WINDOW_CLOSE_REQUESTED && window.data == int2(-17,29)); return 9
        }
        if (SdlEvent(unknown=$v(value))) {
            verify(value.event_type == 0xffffu && value.timestamp == 0xfedcba9876543210ul); return 10
        }
        if (_) { verify(false); return -1 }
    }
}

[export]
def main(smoke : bool) : int {
    let kinds <- array<uint>(SDL_EVENT_QUIT,SDL_EVENT_KEY_DOWN,SDL_EVENT_KEY_UP,SDL_EVENT_MOUSE_MOTION,
        SDL_EVENT_MOUSE_BUTTON_DOWN,SDL_EVENT_MOUSE_BUTTON_UP,SDL_EVENT_MOUSE_WHEEL,SDL_EVENT_TEXT_INPUT,
        SDL_EVENT_TEXT_EDITING,SDL_EVENT_WINDOW_CLOSE_REQUESTED,0xffffu)
    var saved : array<SdlEvent>
    for (i in 0 .. length(kinds)) {
        let raw = SDLTestInputEvent(kinds[i],42u)
        let event = decode_event(raw)
        verify(check(event) == i)
        push(saved,event)
    }
    // Unknown and Quit must never dereference the poisoned inactive union member.
    var poisoned = SDLTestPoisonEvent()
    verify(decode_event(poisoned) is quit)
    poisoned.event_type = 0xffffu
    verify(decode_event(poisoned) is unknown)
    var empty = SDL_MakeEvent()
    empty.event_type = SDL_EVENT_TEXT_INPUT
    match (decode_event(empty)) {
        if (SdlEvent(text_input=$v(input))) { verify(input.text == "" && input.window_id == 0u) }
        if (_) { verify(false) }
    }
    let result = with_sdl() {
        var queued : array<SdlEvent>
        var retained = none(type<SdlEvent>)
        while (is_some(poll_event())) { }
        for (kind in kinds) {
            var raw = SDLTestInputEvent(kind,42u)
            verify(push_event(raw))
        }
        for (i in 0 .. length(kinds)) {
            let next = poll_event()
            verify(is_some(next) && check(unwrap(next)) == i)
            push(queued,unwrap(next))
            if (i == 7) { retained = next }
        }
        SDLTestMutateInputText()
        SDL_PumpEvents()
        for (i in 0 .. length(saved)) { verify(check(saved[i]) == i) }
        for (i in 0 .. length(queued)) { verify(check(queued[i]) == i) }
        verify(check(unwrap(retained)) == 7)
        // Even a stale SDL error cannot turn an empty queue into an error or event.
        set_title(null,"expected failure")
        while (is_some(poll_event())) { }
        verify(is_none(poll_event()))
        return sdl_ok()
    }
    verify(is_ok(result))
    print("Owned event variants, match, UTF-8 lifetime and Option polling PASS\n")
    return 0
}
