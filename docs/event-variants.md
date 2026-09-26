# Owned event variants

For lazy owned iteration use `poll_events()` and `should_close(event,window)`; see [event iteration](api-ergonomics.md#lazy-events).

`require dassdl3/sdl3_events` provides `SdlEvent`, `decode_event(raw)` and
`poll_event() : Option<SdlEvent>`. Import `daslib/match` to use pattern matching.
The design follows the tagged-event/owned-text idiom in the
[Rust SDL3 wrapper](https://docs.rs/sdl3/latest/sdl3/event/enum.Event.html), with
fields taken from this project's pinned SDL 3.2.18 headers.

```daslang
var next <- poll_event()
if (is_some(next)) {
    let event <- move_unwrap(next)
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
| `text_editing_candidates` | `TextEditingCandidatesEvent`: window_id, candidates:array<string>, selected_candidate, horizontal |
| `clipboard_update` | `ClipboardEvent`: owner, mime_types:array<string> |
| `text_editing` | `TextEditingEvent`: window_id, text, start, length |
| `window` | `WindowEvent`: event_type, window_id, data (SDL data1/data2) |
| `drop_begin`, `drop_file`, `drop_text`, `drop_complete`, `drop_position` | `DropEvent`: window_id, position, source, data; copied strings |
| `user` | `UserEvent`: event_type, window_id, code; metadata without application pointers |
| `unknown` | `UnknownEvent`: event_type, timestamp |

Every payload has a uint64 nanosecond timestamp. Key down/up and mouse button
down/up are separate tags, so no duplicate down flag is needed. Scancode/keycode
remain the SDL numeric values; text is supplied by text events, not derived from
keys. Wheel delta is the original SDL value; `flipped` is preserved instead of
silently normalizing it. IME selection start/length retain SDL character units,
including negative values. Empty or null native text becomes an empty string.

Strings live in daScript's managed string storage and are independent of SDL
payload memory. SdlEvent is now move-only because the IME/MIME alternatives
contain arrays. Explicit cloning creates independent arrays and may share managed
strings; see [list ownership and migration](event-list-payloads.md). No raw pointer
or C union member escapes through SdlEvent. Unknown events preserve type/timestamp
for unprojected categories (for example audio/camera and keyboard/mouse device
hotplug) and malformed list shapes. User metadata is decoded, while data1/data2
are accessible only through the explicit borrowed raw-pointer adapters.
Raw queue calls preserve opaque SDL_Event data.
The first/default variant is unknown, so zero initialization is not a Quit event.

Polling follows SDL's main-thread/event-pump rules. This adds no event dispatcher,
callbacks, exceptions or application state. `with_text_input` still owns the text
input session separately.

Example: [67_event_variants.das](../examples/67_event_variants.das). It uses English
messages and pattern matching for Quit, keys, mouse, text, composition and window
close. Tests in [events.das](../tests/events.das) cover the initial input variants, UTF-8 copies
retained in arrays/Option across subsequent polls and source mutation, poisoned
inactive union members, null text, unknown tags and empty queues. Existing raw
input readers remain covered by `tests/input.das`. The [event queue package](event-queue.md)
adds batch/wait decoding and tests the six additional drop/user tags in
`tests/event_queue.das`; that package brought the variant to 53 alternatives.

## Joystick and gamepad events

All 21 tags in SDL 3.2.18 are projected. Each payload contains `timestamp : uint64`
and `which : uint` (SDL_JoystickID, including added/removed events, never an array index).

| Tags (variant field names) | Additional fields |
| --- | --- |
| `joystick_axis_motion` | axis:uint8, value:int16 |
| `joystick_ball_motion` | ball:uint8, delta:int2 (signed relative movement) |
| `joystick_hat_motion` | hat:uint8, value:uint8 (SDL_HAT_* mask) |
| `joystick_button_down`, `joystick_button_up` | button:uint8 |
| `joystick_added`, `joystick_removed`, `joystick_update_complete` | none |
| `joystick_battery_updated` | state:SDL_PowerState, percent:int (-1 remains unknown) |
| `gamepad_axis_motion` | axis:SDL_GamepadAxis, value:int16 |
| `gamepad_button_down`, `gamepad_button_up` | button:SDL_GamepadButton |
| `gamepad_added`, `gamepad_removed`, `gamepad_remapped`, `gamepad_update_complete`, `gamepad_steam_handle_updated` | none |
| `gamepad_touchpad_down`, `gamepad_touchpad_motion`, `gamepad_touchpad_up` | touchpad:int, finger:int, position:float2, pressure:float |
| `gamepad_sensor_update` | sensor:SDL_SensorType, data:float3, sensor_timestamp:uint64 |

Axes are not normalized or dead-zone filtered. Button direction is the variant tag.
Sensor data is copied inline; its device timestamp is independent of the common
event timestamp (both nanoseconds). These events contain no retained pointers.
Decoding does not look up or reopen a device: removal events remain usable after
the device is detached. Gamepads can produce both joystick and gamepad events.
The eleven `SDL_Read*Event` native adapters copy only matching active members and
zero their output on tag mismatch. Their selected native fields are generated
from the pinned SDL headers.

[controller_events.das](../tests/controller_events.das) covers all tags, signed
axis/ball boundaries, IDs above INT_MAX, both 64-bit timestamps, battery -1,
touch coordinates, inline sensor copies, mismatch clearing and queue decoding.
[71_virtual_gamepad.das](../examples/71_virtual_gamepad.das) demonstrates owned
`match` on actual virtual-device axis/button events without test-native fixtures.
Synthetic tests cover rare event kinds; physical-device delivery is not certified.

Local validation (2026-09-21, Windows x64/MSVC): the new controller test and
updated virtual-device example passed in the production interpreter, baseline,
CppGenBind and strict AOT. Existing Events, Queue and Callbacks regressions passed
in those backends too; metadata parity passed. Generation/inventory/boundary
checks passed (6 main + 4 standalone). The generator-free, no-LLVM consumer ran
example 71 successfully; SDLTestControllerEvent was confirmed unavailable there.

## Touch, Pen and standalone Sensor

Thirteen additional tags are supported, all with `timestamp : uint64`:

| Tags | Payload fields |
| --- | --- |
| `finger_down`, `finger_up`, `finger_motion`, `finger_canceled` | touch_id:uint64, finger_id:uint64, window_id:uint, position/delta:float2, pressure:float |
| `pen_proximity_in`, `pen_proximity_out` | which:uint, window_id:uint, pen_state:uint |
| `pen_motion` | which, window_id, pen_state:uint; position:float2 |
| `pen_down`, `pen_up` | motion fields plus eraser:bool |
| `pen_button_down`, `pen_button_up` | motion fields plus button:uint8 |
| `pen_axis` | motion fields plus axis:SDL_PenAxis, value:float |
| `sensor_update` | which:uint, data:float[6], sensor_timestamp:uint64 |

Touch position/delta retain SDL normalized units, including values outside the
usual range. Pen positions are window-relative pixels; axis values retain their
axis-specific units, flags are not filtered, and proximity IDs are not permanent
pen identities. Sensor data is copied inline, with its independent sensor clock.
No pointer to the original SDL_Event survives. See [peripheral contracts](peripherals.md)
and [payload tests](../tests/peripheral_events.das). Hardware event delivery is
separate from the synthetic decode/queue checks.

## Device lifecycle events (SDL 3.4 audit)

Eleven keyboard/mouse/audio/camera tags bring SdlEvent to 64 alternatives.
See [payloads and validation limits](script-accessibility.md). IDs are copied
values and do not own devices. Pen proximity also preserves pen_state.
