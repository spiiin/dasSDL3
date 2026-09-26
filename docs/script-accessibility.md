# Script accessibility audit (SDL 3.4.16, Windows x64)

This package leaves raw function signatures and resource ownership unchanged.
The census is still 998 generated + 13 adapted / 1263 functions; constants and
record fields are not counted as additional functions.

## String constants

All 552 active SDL_HINT_* and SDL_PROP_* string macros in the Windows header
inventory are exported (543 newly accessible, eight IO keys moved from manual registration, one HID key already generated). The five
GAMEPAD_CAP aliases resolve to the corresponding JOYSTICK_CAP strings. Thirteen
SDL_oldnames compatibility/deprecation markers stay excluded. Enum priorities
are existing enum values, not string hints. Exporting a platform-specific key
never promises that its backend works on Windows. Dynamic property names remain
ordinary strings; no builder, owner or property registry is introduced.

Both generators use native const char * expressions. CppGenBind preserves type
checks, pinned header hashes and metadata parity. tests/string_constants.das
checks the actual values of all 552 macros, including aliases, in interpreter/AOT.
The strings are native static constants; callers must not modify their storage.

## Audio channel maps

See [audio stream controls](audio-stream-controls.md). The input/output getters
return Result<Option<array<int>>, SdlError>, copy allocated maps, free native
storage and preserve the default None. Null-stream errors are copied into Result.
Tests cover stale errors, identity normalization, reset, independent copies,
mutation and lifetime after stream destruction. Native allocation failure is
classified from pinned SDL_malloc behavior; forced OOM has not been exercised.
The older audio_device_channel_map contract remains separate and ambiguous.

## Owned device events

SdlEvent adds keyboard_added/removed, mouse_added/removed,
audio_device_added/removed/format_changed and
camera_device_added/removed/approved/denied (64 alternatives total).
The four payload records own timestamp and which; AudioDeviceEvent also owns
recording. They carry IDs, not device owners or cached names. In particular a
removed ID need not remain valid for querying the device. Existing polling,
waiting and queue decoding all use decode_event and gain these variants.

Raw SDL_Read*DeviceEvent adapters copy only the matching active union member;
a mismatched tag returns false and zeroes output. tests/hotplug_events.das uses
native synthetic payloads with large IDs/timestamps, verifies all eleven tags,
and overwrites the source event before checking the owned result. This does not
validate physical hotplug delivery or camera permission UI.

## Record-field audit

Compared every exposed native record against the pinned inventory. Four real
SDL 3.4 omissions are now exported: SDL_GPUDepthStencilTargetInfo.mip_level/layer,
SDL_GPUMultisampleState.enable_alpha_to_coverage and SDL_PenProximityEvent.pen_state.
The owned PenProximityEvent also preserves pen_state. Field tests establish
script access/layout; they do not establish GPU rendering/backend support.

Remaining intentional or specialized omissions:

- reserved/padding/internal: ABI or SDL-private state, not application data.
- SDL_Event union members: access through tag-checked readers and owned decoding;
  display/render/pinch payload coverage remains a follow-up.
- Per-event type fields: the parent SDL_Event supplies the tag.
- Keyboard scancode / mouse-wheel direction: existing scalar predicate adapters.
- Clipboard MIME / IME candidates and HID wchar_t/list links: copied adapters.
- GamepadBinding input/output unions: existing tagged accessors.
- VirtualJoystickDesc, IOStreamInterface and StorageInterface callback fields:
  native-only callback lifetime; no automatic retained script block bridge.

Windows inspection does not replace other-platform ABI/build validation.

## Validation (2026-09-26)

- Main targeted regression and generation/inventory checks: 12/12.
- Baseline/CppGenBind/strict AOT (fallback disabled) plus metadata: 13/13.
- No-LLVM/generator-free consumer: build, example 78, all string constants,
  public owned-event decoding and removed-framework boundary checks passed.
- Production generator configuration restored; saved CppGenBind snapshot is
  current and deterministic. Documentation links and diff whitespace passed.

This is targeted Windows validation, not a full project or browser regression.
