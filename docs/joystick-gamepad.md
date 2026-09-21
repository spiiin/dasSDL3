# Joystick and gamepad (SDL 3.2.18)

Generated raw declarations cover Joystick 58/58 and Gamepad 73/73 (131 new
functions). This is declaration coverage, not a claim that all devices, callback
fields or platform extensions have a script-level projection. Raw return sentinels,
SDL ownership and valid-index requirements remain unchanged.

[Example 71](../examples/71_virtual_gamepad.das) needs no physical controller.
It attaches a virtual gamepad, opens joystick/gamepad references, sets axis and
button state, matches typed events, reads mapped controls, closes both references
and detaches the device.
It uses `sdl_scope`, pipe-style `sdl_use` and `sdl_try`.

## Ownership and boost

Import `dassdl3/sdl3_joystick_gamepad_boost`.

- joysticks()/gamepads(): Result of owned ID arrays; SDL allocations are freed.
  No devices is a successful empty list. IDs are not opened pointers.
- open_joystick/open_gamepad: Result of owned native references. Close every
  successful open, even if repeated opens return the same pointer. with_joystick
  and with_gamepad close one reference with defer on success or body Err.
- Get*FromID, Get*FromPlayerIndex and GetGamepadJoystick return borrowed pointers.
  Do not close them unless you separately own an open reference.
- joystick_name/gamepad_name return copied Result strings. path/serial helpers
  return copied Option strings: absence is normal for a valid live device.
  They do not distinguish absence from an invalid handle; valid handles are a
  precondition. Raw borrowed strings must not outlive the device.
- gamepad_mapping copies and frees SDL's allocated string. gamepad_mappings
  copies strings then frees the single native allocation. Raw Mapping/ForID/
  ForGUID return allocated strings; free them with SDL_free (raw daScript code
  uses unsafe reinterpret<void?>). Do not free borrowed names/serials.
- gamepad_bindings copies each SDL_GamepadBinding before freeing the native
  pointer list. input_type/output_type are the union tags. SDL_GamepadBindingInput
  and Output read only the active alternative and return int3(index,min,max);
  a hat uses int3(hat,mask,0), a button int3(button,0,0), NONE zeros. This is a
  native union projection, not a separate input mapping framework.
- add_gamepad_mapping returns Result<bool>: true added, false updated; both are
  success. Axis zero, button false, unsupported predicates and absent serials
  are not inferred errors from SDL_GetError. Ball, effect and touch/sensor bool
  operations use Result; initial axis state uses Option and preserves unknown.
- with_joysticks_lock balances SDL's recursive lock through defer. Keep the body
  short and never wait for another thread needing that lock.

GUID is the native 16-byte SDL_GUID record. Both generators copy record returns;
interpreter by-value arguments copy the managed record for the C ABI, matching
AOT. Pinned raw by-value managed arguments require a mutable `var guid` in script.
SDL_GUIDString and GUIDInfoRef accept a const reference for convenient queries.
Native int16/uint16 out storage remains narrow; ref adapters explicitly widen it.
Rumble amplitudes must fit uint16 and LED components uint8; raw/native narrowing
is preserved. Only send effects to a device whose protocol the caller understands.

## Virtual devices and callbacks

SDL_MakeVirtualJoystickDesc zeroes the full native record and initializes its
version to sizeof(SDL_VirtualJoystickDesc), including hidden callback fields.
The generated descriptor exposes numeric fields, borrowed name/array pointers
and userdata; native function-pointer fields are not writable script fields.
Custom Update/SetPlayerIndex/Rumble/RumbleTriggers/SetLED/SendEffect/
SetSensorsEnabled/Cleanup callbacks currently require a C/C++-constructed
native descriptor. Never reinterpret daScript functions or blocks as C addresses.
A native caller owns callback code, userdata, synchronization and lifetime through
SDL teardown (including possible cleanup after failed attachment).

attach_virtual_joystick/with_virtual_joystick take the name and descriptor arrays
as separate arguments. The adapter borrows them only during Attach; pinned SDL
copies the name and touchpad/sensor descriptions. It overwrites the descriptor's
name, ntouchpads, nsensors and array pointers for that call. Other fields are
preserved. No script pointer is retained for the name or those arrays.
Close opened references before a virtual scope exits; do not detach its device
inside the body. A body Err remains primary if deferred detach also fails.
There is no panic recovery or retained script callback bridge.

## Pinned SDL defects and bounds

The binding does not patch third_party/SDL:

1. VIRTUAL_JoystickOpen does not assign joystick->nballs. A descriptor requesting
   balls therefore opens with zero balls; accepted virtual ball motion is dropped.
   Tests execute the setter and confirm the read error, not a successful trackball
   round trip. A real physical trackball remains unverified.
2. SendJoystickVirtualSensorDataInner assigns max_sensor_events to itself after
   reallocation. A second queued event before Update can write beyond allocation.
   **Send at most one pending sensor event per virtual device, then call
   SDL_UpdateJoysticks before another send**, for both raw and boost APIs. This
   applies across sensor types and threads. The wrapper does not silently pump
   global input or claim to repair SDL's queue. The hazard is identified in the
   pinned source; tests avoid executing the out-of-bounds case.
3. Virtual Update uses Uint8 control indices. The attach array adapter rejects
   naxes/nbuttons/nballs/nhats above 255 to prevent index wrap; raw callers must
   observe the same bound. Touchpad/sensor array counts must fit Uint16.

Sensor/effect adapters bound counts before int narrowing; sensor arrays must
have positive size and valid storage. Raw pointer buffers require valid capacity
and nonnegative counts. Ball/initial-axis ref helpers reject negative indices;
raw SDL callers must validate indices (some pinned checks miss negative values).
Relative device state is updated by SDL_UpdateJoysticks/UpdateGamepads or the
usual event pump; setters do not immediately update all mapped values.

## Tests and remaining work

[Raw tests](../tests/joystick_gamepad.das) directly invoke all 131 functions.
Native fixtures only construct descriptors and record callback effects; they do
not hide SDL functions being tested. Assertions cover identity/GUID/vendor/product,
player indices, mappings and lists, axes/buttons/hats, touch/sensors, effects,
open/close, detach cleanup and expected unsupported/invalid operations. Mapping
file failure is checked; successful disk file loading is not established.

[Scope tests](../tests/joystick_gamepad_scopes.das) are fixture-free: copied
configuration arrays, primary error preservation, early return, move-only Result,
close/detach, failed creation and invalid capacities. Physical rumble/LED/sensors,
hotplug races, Apple symbol availability and cross-platform hardware behavior are
not certified by virtual tests. All 21 Joystick/Gamepad event tags now have owned projections in
SdlEvent; see [event variants](event-variants.md). Example 71 also matches
real axis/button events from its virtual device. Native callback-field address
setters and property-name string macros remain explicit follow-ups.

## Local validation — 2026-09-21

Pinned Windows x64/MSVC: seven main tests passed, including the new raw/scopes/
example and existing Events/Keyboard regressions. Six legacy/CppGenBind tests
plus metadata parity passed; five strict-AOT tests passed with fallback disabled.
All six main generation/inventory/boundary checks and four standalone clangbind
checks passed. The raw script contains direct calls to all 58 Joystick and 73
Gamepad functions; successful virtual and documented error paths are distinguished
above. Validation uses virtual devices, not physical-controller certification.

The BUILD_TESTING=OFF consumer rebuilt with generators off and LLVM/Clang/Python
discovery disabled. Fixture-free scope tests and example 71 passed. The native
virtual-descriptor test fixture was confirmed unavailable in that consumer.
