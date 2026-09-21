# Owned event variants

`require dassdl3/sdl3_events` provides `SdlEvent`, `decode_event(raw)` and
`poll_event() : Option<SdlEvent>`. Import `daslib/match` to use pattern matching.
The design follows the tagged-event/owned-text idiom in the
[Rust SDL3 wrapper](https://docs.rs/sdl3/latest/sdl3/event/enum.Event.html), with
fields taken from this project's pinned SDL 3.2.18 headers.

```daslang
let next = poll_event()
if (is_some(next)) {
    let event = unwrap(next)
    match (event) {
        if (SdlEvent(quit = _)) { print("Quit requested\n") }
        if (SdlEvent(key_down = $v(key))) { print("Key pressed: {key.scancode}\n") }
        if (SdlEvent(mouse_motion = $v(mouse))) { print("Mouse: {mouse.position}\n") }
        if (SdlEvent(text_input = $v(input))) { print("Text entered: {input.text}\n") }
        if (_) { }
    }
}
```

The module re-exports the existing boost API. `poll_event(var raw : SDL_Event)`
remains available with its original borrowed-payload contract. The no-argument
overload returns None for an empty queue; a stale SDL error string is irrelevant.
It copies the active payload immediately, before another poll/pump can invalidate
SDL's text pointers. `decode_event(raw)` must likewise be called while the raw
event's payload is valid. It does not consume or free caller-owned native memory.

| Variant | Payload |
| --- | --- |
| `quit` | `QuitEvent`: timestamp |
| `key_down`, `key_up` | `KeyEvent`: window_id, which, scancode, keycode, modifiers, raw, repeat |
| `mouse_motion` | `MouseMotionEvent`: window_id, which, buttons, position, delta |
| `mouse_button_down`, `mouse_button_up` | `MouseButtonEvent`: window_id, which, button, clicks, position |
| `mouse_wheel` | `MouseWheelEvent`: window_id, which, delta, integer_delta, position, flipped |
| `text_input` | `TextInputEvent`: window_id, text |
| `text_editing` | `TextEditingEvent`: window_id, text, start, length |
| `window` | `WindowEvent`: event_type, window_id, data (SDL data1/data2) |
| `unknown` | `UnknownEvent`: event_type, timestamp |

Every payload has a uint64 nanosecond timestamp. Key down/up and mouse button
down/up are separate tags, so no duplicate down flag is needed. Scancode/keycode
remain the SDL numeric values; text is supplied by text events, not derived from
keys. Wheel delta is the original SDL value; `flipped` is preserved instead of
silently normalizing it. IME selection start/length retain SDL character units,
including negative values. Empty or null native text becomes an empty string.

Strings live in daScript's managed string storage and are independent of SDL
payload memory. Variant/Option/array copies may share those managed strings;
no per-copy native allocation or ownership wrapper is required. No raw pointer
or C union member escapes through `SdlEvent`. Unknown events preserve only type
and timestamp: drop data, user pointers, joystick/gamepad/touch/pen/sensor and IME
candidate payloads are not decoded yet. Use the raw API for those contracts.
The first/default variant is unknown, so zero initialization is not a Quit event.

Polling follows SDL's main-thread/event-pump rules. This adds no event dispatcher,
callbacks, exceptions or application state. `with_text_input` still owns the text
input session separately.

Example: [67_event_variants.das](../examples/67_event_variants.das). It uses English
messages and pattern matching for Quit, keys, mouse, text, composition and window
close. Tests in [events.das](../tests/events.das) cover all variants, UTF-8 copies
retained in arrays/Option across subsequent polls and source mutation, poisoned
inactive union members, null text, unknown tags and empty queues. Existing raw
input readers remain covered by `tests/input.das`.
