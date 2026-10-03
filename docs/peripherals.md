# Touch, Pen, Sensor, Haptic and HIDAPI

Pinned SDL 3.2.18, Windows x64/MSVC. All 71 native functions are generated:
Touch 4/4, Sensor 14/14, Haptic 31/31, HIDAPI 22/22. Pen has no functions in this
release; its input is delivered through events. These counts describe declarations,
not certification of physical devices. The native enums, effect records, feature
flags, special mouse/touch IDs and SDL_STANDARD_GRAVITY are also available.

`require dassdl3/sdl3_peripherals_boost` adds copy/array/ref adapters and Result
ownership scopes. [Example 72](../examples/72_peripherals.das) enumerates devices
without sending output reports or playing forces. Raw calls retain SDL sentinels.

## Touch and sensor

`touch_devices`, `touch_fingers`, `sensors`, and `haptics` return Result of an
owned array. An empty successful enumeration is an empty array. The native list
is freed with SDL_free after copying; finger structures are copied before freeing
their native pointer list. Touch and finger IDs are uint64, not signed ints or
device indices. `touch_device_name`, `sensor_name` and `haptic_name` copy text.

`open_sensor` / `with_sensor` use SDL_Sensor pointers and SDL_CloseSensor.
`sensor_data(device, var buffer)` fills an existing float array and returns
Result<Unit>; it does not resize the buffer or normalize values. SDL determines
the meaning and number of available components. Raw pointer/count APIs retain
their original storage preconditions. GetSensorFromID is borrowed, not a new
owning reference. Follow the SDL main-thread rules for touch queries; sensor
calls retain SDL's native synchronization rules.

## Haptic

All six effect payloads and SDL_HapticDirection are annotated, including fixed
arrays, envelopes and the custom sample pointer. SDL_HapticEffect is the native
union; its tag is exposed as `effect_type`. `SDL_MakeHaptic*Effect` copies a
selected payload into a zero-initialized union. Constant/Ramp/LeftRight/Custom
constructors set the corresponding tag; Periodic/Condition preserve the supplied
tag, which must match the chosen waveform/condition. Direction's `effect_type`
field means SDL_HAPTIC_POLAR/CARTESIAN/SPHERICAL/STEERING_AXIS, not an effect flag.

`open_haptic` / `with_haptic` close the native handle with defer.
GetHapticFromID is borrowed; OpenHapticFromMouse/Joystick return owning references.
`create_haptic_effect` / `with_haptic_effect` treat **-1** as failure; effect ID
zero is valid. The effect scope destroys that ID on normal/early Result return.
Its device must remain alive until cleanup. Updating/running/stopping effects
return Result<Unit>; effect support is a bool predicate, not an error inferred
from SDL_GetError. Raw status/rumble/support queries retain SDL's semantics.

Custom payloads contain borrowed sample storage. Copying a record/union does not
copy its samples or create ownership. Keep channels*samples uint16 values valid
for every create/update call; retain storage for the effect lifetime if relying
on a backend whose copying behavior has not been established. No custom-sample
owner or automatic pointer allocation is provided. Hardware restrictions,
supported effect sets, units and SDL_HAPTIC_INFINITY follow SDL's headers.

## HIDAPI

`with_hid` pairs SDL_hid_init/exit. `open_hid` / `with_hid_device` open a native
path and close it with SDL_hid_close. Bodies return Result; if body and cleanup
both fail, the body error is preserved. Scope operations return errors as values
and use defer, without catch/recover. Bodies must not close the scoped handle
or use it after the scope has ended. As elsewhere, arbitrary application panic
in the pinned runtime does not guarantee defer execution.

`hid_devices(vendor,product)` copies enumeration metadata into an owned array of
HidDeviceInfo and calls SDL_hid_free_enumeration. A zero vendor/product is SDL's
wildcard; nonzero inputs must fit uint16. SDL's NULL enumeration result does not
distinguish no matches from failure, so this helper returns an array rather than
inventing a Result error from a possibly stale SDL error string. Establish a HID
session first. `hid_device_info(ptr)` returns Option of copied metadata; NULL is
None. SDL_hid_get_device_info returns device-owned memory: **do not free it** with
SDL_hid_free_enumeration. Only enumeration results use that deallocator.

Native HID strings use wchar_t. In this Windows profile raw buffers are uint16
UTF-16 code units and maxlen is in code units, not bytes. Both generators keep
native signatures. CppGenBind uses decltype for these five functions because a
C AST canonicalizes wchar_t to unsigned short, while MSVC C++ distinguishes it.
Small AOT-only pointer casts bridge uint16 storage. Metadata strings are converted
to UTF-8 and copied immediately, including surrogate pairs; absent strings become
empty strings. SDL_HidWideString is the explicit conversion helper. No cross-OS
wchar_t ABI guarantee is claimed for those Windows snapshots. The native macOS
profile uses `SDL_HidChar` (`int`/UTF-32) buffers and explicit interpreter/AOT
bridges; Windows uses the same alias for `uint16`/UTF-16. Use the alias for
portable scripts. Metadata copying converts the native representation to UTF-8.

`hid_read`, `hid_read_timeout`, `hid_write`, feature/input reports and descriptor
helpers take byte arrays and return Result<int>, preserving the native count.
Zero from a nonblocking/timed read means no data, not failure. Only negative
counts become Err. The array capacity is unchanged; only the returned prefix is
valid. Buffers must contain 1..INT_MAX bytes. Feature/input/output reports retain
their report-ID byte convention; the wrapper does not insert or strip it.
Use raw set_nonblocking when needed. Do not close devices while another thread
uses them, and do not mutate borrowed arrays during a native call.

## Events and verification

[Event variants](event-variants.md) adds all 13 touch/pen/standalone-sensor tags,
SdlEvent currently has 53 alternatives including the later IME/MIME lists. Sensor data[6] and both timestamps are owned
inline values; touch coordinates are not clamped, pen coordinates remain pixels.

[peripherals.das](../tests/peripherals.das) directly calls all 71 raw functions.
It distinguishes successful enumeration/init from invalid-device errors, checks
six haptic payload constructors against native readers, owns copied Unicode HID
metadata across source mutation, and checks failed creation skips scope bodies.
[peripheral_events.das](../tests/peripheral_events.das) covers all 13 tags, large
IDs, independent timestamps, sensor array copies, mismatch clearing and queue
round trips. These fixtures construct payloads, not fake successful device I/O.

Physical sensor readings, haptic output/custom samples, HID report exchange,
timeouts on real hardware and cross-platform behavior remain unverified. Further
boost conveniences can be added for hardware workflows; raw API access is present.

Local validation (2026-09-21): seven main package/regression tests passed.
Twenty-two baseline/CppGenBind/strict-AOT and metadata tests passed, with AOT
fallback disabled. Six main generation/inventory/boundary and four standalone
clangbind checks passed. BUILD_TESTING=OFF with generators/LLVM/Clang/Python
package discovery disabled built successfully; example 72 and float/64-bit
constant checks passed. Native test fixtures were confirmed unavailable in that
consumer. Documentation links and diff whitespace checks passed.
