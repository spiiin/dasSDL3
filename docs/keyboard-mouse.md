# Keyboard and mouse (SDL 3.4.16)

ID 0 denotes the global keyboard or mouse in SDL 3.4. Name queries return
"Keyboard" / "Mouse", and the copied boost getters return Ok. This differs from
the invalid-ID behavior in 3.2.18; both native and dummy-driver tests cover it.

All 24 Keyboard and 22 Mouse functions now have generated raw signatures:
40 were added to the previous six. SDL_Cursor is opaque; SDL_Scancode,
SDL_SystemCursor, SDL_TextInputType and SDL_Capitalization are generated enums.
Keycode/modifier and mouse button constants are generated from pinned headers.
Text-input property names remain the SDL string keys (for example
`SDL.textinput.type`); string property macros are not exported by this package.

Import `dassdl3/sdl3_keyboard_mouse_boost` for copied queries, reference adapters,
Result cursor factories and defer scopes. [Example 70](../examples/70_keyboard_mouse.das)
uses typed scancodes, copied device enumeration, text input and mouse state.

## Queries and ownership

- keyboards()/mice(): Result<array<uint>,SdlError>; copy SDL's allocated ID list
  and free it immediately. An empty list is a successful result.
- keyboard_state(): owned array<bool>, copied from SDL's borrowed state. Poll/pump
  events first when fresh input is needed. Reading a snapshot does not pump.
  key_down(int) remains available for a single physical key without array copying.
- keyboard_name(id)/mouse_name(id): Result<string,SdlError>, copy before device
  removal; a null native name is an error. Raw names remain SDL-owned.
- key_name/scancode_name: copied string; SDL's empty unknown name stays empty.
  Names/keycodes and scancodes are different: key translation follows the current
  layout. A physical A need not produce Latin `a`.
- keyboard_focus/mouse_focus and current_cursor/default_cursor: Option of a
  borrowed native pointer. Absence is normal. Never destroy the default cursor;
  an application-created current cursor is still owned by its original owner.
- global_mouse_state/relative_mouse_state write float2 and return a button mask.
  Relative reads consume accumulated motion. Native relative mode getters return
  bool state, not Result; unsupported setters return SDL errors.

SDL_Keymod is uint16 in storage and raw pointer outputs. Pinned daScript widens
native small integer value/ref inputs to uint: pass uint to SDL_SetModState and
GetKeyFromScancode, uint16 storage to raw GetScancodeFromKey, and uint& to
scancode_from_key's ref adapter. The adapter explicitly converts the native mask.

## Retained scancode names

SDL_SetScancodeName does **not copy** its string. Its address must stay valid while
SDL uses it. Do not pass a temporary, collected or subsequently modified daScript
string. There is deliberately no convenience setter pretending to own this
lifetime. The raw execution test reuses SDL's permanent built-in name. Copied
name getters do not extend the lifetime of strings previously registered with SDL.

## Text input

set_text_input_area/text_input_area expose rectangle/caret refs through Result.
The getter clears output before calling SDL. with_text_input_properties starts
input only if not already active; it does not overwrite an outer session's
properties. It stops only the session it started, including a body Err or early
return, and preserves the body error if cleanup also fails. Arbitrary panic is
not protected. Do not stop/restart the session manually inside the scope.
Properties are passed synchronously to SDL, with platform-specific interpretation.
Screen-keyboard predicates may normally return false on a desktop.

## Cursors and platform behavior

create_cursor/create_color_cursor/create_system_cursor return owned pointers in
Result. Destroy successful factory results with SDL_DestroyCursor. with_cursor,
with_color_cursor and with_system_cursor free their own resource with defer.
They do not select it automatically or save/restore a previous current cursor.
If selection is changed, restore the borrowed previous cursor before leaving its
owner's scope when that is the application's intended behavior.

The bitmap adapter checks positive dimensions, width divisible by eight, hotspot
bounds, and both byte capacities using wide arithmetic. Raw CreateCursor requires
caller-validated buffers; the pinned SDL rounds width up to eight. Color cursor
creation copies surface content; keep the source surface alive for that call.
Never destroy a cursor borrowed from one of these scopes inside its body.

Follow each SDL function's thread requirements; window, text input and cursor
operations run on the main thread. Capture, relative mode, global warp and system
cursors can be unavailable on a backend. Keep those failures as Result errors.
The dummy backend checks unsupported paths; it cannot establish real input,
IME composition, global capture or physical device hotplug correctness.

## Validation

[Tests](../tests/keyboard_mouse.das) directly call all 40 newly added raw
functions and the existing query/session functions, check copied data, invalid
IDs and bitmap bounds, text-area round trips, nested/early-error input cleanup,
mask/key conversions, visibility restoration and cursor scopes. Windows tests
require successful native mono/color/system cursor creation. Warps use the
current position rather than deliberately moving the desktop pointer.

Main runner: dummy test/example and native Windows test passed (3/3), along with
four existing input/events regressions. Thirteen legacy/CppGenBind/strict-AOT
checks passed, including native Windows cursor execution on all three runners.
Metadata parity and six main plus four standalone generation/inventory/type
checks passed. Physical hotplug and interactive IME behavior remain unverified.
