# SDL record-field accessibility audit

Pinned SDL 3.4.16, Windows x64/MSVC. This audit examines **all 122 named complete
native records and their 840 top-level fields**, including records absent from
bindings.json and complete records treated as opaque. The earlier audit examined
exposed records only and therefore missed SDL_GPUVulkanOptions.

| Status | Fields | Meaning |
| --- | ---: | --- |
| direct | 586 | Field selected by the native generators |
| adapted | 84 | Existing reader/query/copy or tagged-union projection |
| native_callback | 25 | Existing setter accepts a native C function address |
| tag | 38 | Tag supplied by the enclosing SDL_Event |
| internal | 98 | Padding, reserved/private state or alignment probe |
| host_only | 9 | AssertData (7) and Surface/Texture native reference counts (2) |
| partial | 0 | All identified surface byte layouts now have plane access |
| pending | 0 | All identified field gaps implemented |

These categories describe access routes, not runtime coverage or field write
permission. The report counts native fields, not additional SDL functions. Core
function totals remain 1062 generated / 13 adapted / 188 pending of 1263.

## Implemented access

Import `dassdl3/sdl3_record_access` for Result helpers:

- `surface_info(surface)` returns a copied SurfaceInfo (flags, format, width,
  height, pitch). It does not expose mutable resource fields or refcounts.
- `palette_colors(palette)` returns an owned array of SDL_Color. Its length is
  ncolors; it survives palette changes/destruction.
- `surface_plane_info(surface, plane=0)` returns int4(row_bytes, rows, pitch,
  plane_count). Plane order is physical storage order, including Y,V,U for YV12.
- `with_surface_bytes(surface, plane) $(var bytes : array<uint8>#; layout : int4)`
  locks the surface, lends a zero-copy temporary array, and unlocks via defer on
  success, ordinary early return or Result error. The block returns Result.
  Array move outside the block is rejected; an explicit clone is independent.
  Raw SDL_WithSurfacePlaneBytes requires an already locked, live surface.
- `create_gpu_device_with_vulkan_options(props, config, device_extensions,
  instance_extensions)` returns a native device Result; normal GPU destruction
  rules apply. SDL_GPUVulkanOptions itself is directly generated with all 7 fields.

Example: [93_surface_bytes.das](../examples/93_surface_bytes.das).

### Surface layout contract

Packed RGB/integer/float and 1/2/4-bit indexed formats use byte rows. Packed YUY2,
UYVY and YVYU include complete two-pixel groups. IYUV/YV12 have three planes;
NV12/NV21 and P010 have two. Odd widths/heights use rounded-up chroma dimensions
and SDL's format-specific chroma pitch. MJPG is one compressed byte span whose
length is pitch, not width*height. The view performs no conversion or decoding.

Each array ends at the last row's payload: `(rows-1)*pitch + row_bytes`, excluding
trailing padding after that row. It includes padding between rows. MJPG uses a
single row. Empty surfaces lend an empty array. Invalid plane, unsupported FOURCC,
negative/insufficient pitch, absent required storage or a span beyond INT_MAX
returns Err without invoking the block. Layout arithmetic uses uint64 intermediates.

SDL_CreateSurfaceFrom and camera/native producers must supply valid backing
storage for every plane: SDL_Surface does not record allocation capacity, so no
binding can discover a lying native pointer/extent. Do not destroy, resize or
unlock the borrowed surface inside the block; serialize concurrent users. Locking
does not turn SDL surface access into a cross-thread mutex. Texture-derived
surfaces retain write-only texture-lock rules. Arbitrary application panic still
has the pinned defer limitation; no panic/catch wrapper was introduced.

P010 plane layout is tested using a native surface fixture: the pinned SDL
CalculateYUVSize cannot allocate this format. This is not a claim that
SDL_CreateSurface(P010) or a physical P010 camera succeeds.

### Vulkan options lifetime

The helper copies SDL property values by type into a private group, selects the Vulkan driver,
and installs a stack copy of config for the synchronous device-creation call.
The two script string arrays replace config's extension counts/pointers; they are
borrowed until SDL_CreateGPUDeviceWithProperties returns. They are never stored
back into caller properties. The temporary group is destroyed, preserving the
creation error. Pointer values are borrowed without copying their cleanup ownership;
the original owners must stay alive through creation. Numeric values are copied
with their numeric getters: the pinned SDL_CopyProperties shallow-copies its
internal numeric-to-string cache and can double-free it. The helper avoids that
upstream defect and has a cached-number regression test. The raw property API
remains available for host-specific lifetime policies.

feature_list and vulkan_10_physical_device_features remain borrowed pointers to
real native Vulkan feature structures, valid throughout creation. No Vulkan
pNext DSL or script callback bridge is implied. Native fields, zero-feature Vulkan
creation, raw property creation and rejected instance/device extension names are
tested; enabling arbitrary native feature chains needs application-specific tests.

## Callback descriptor setters

All **25 native callback fields** now have explicit setters:

- SDL_IOStreamInterface: six via SDL_SetIOStreamInterfaceCallbacks.
- SDL_StorageInterface: eleven individual SDL_SetStorageInterface_* setters.
- SDL_VirtualJoystickDesc: eight SDL_SetVirtualJoystickDesc_* setters for Update,
  SetPlayerIndex, Rumble, RumbleTriggers, SetLED, SendEffect, SetSensorsEnabled,
  Cleanup. Null clears a slot. Use SDL_MakeVirtualJoystickDesc for version/zero
  initialization; setters do not initialize the rest of the descriptor.

Addresses must point to C functions with the exact SDL signature and SDLCALL.
They are never daScript Func/Block values. SDL copies the descriptor, but host
code, userdata and synchronization must outlive every callback through detach.
Pinned version validation occurs before ownership transfer (no Cleanup); failures
after descriptor copy may call Cleanup. Do not infer cleanup solely from an ID=0
return. Tests invoke every slot through a real virtual device and check userdata,
invalid-version behavior and exactly-once successful detach cleanup. Forced native
allocation failure has not been exercised. Existing IO/Storage tests remain.

## Intentional projections

- Event union alternatives use tag-checked readers and owned decode_event.
  Strings and lists are copied; user pointers remain borrowed. Common/quit/window/
  text/drop/user records need not be separately writable script structs to expose
  their payloads. This does not certify payloads for unknown future event tags.
- SDL_GamepadBinding input/output unions have tagged scalar accessors.
- HID wchar strings are copied and the borrowed list link has SDL_HidNext.
- Texture dimensions and format are available via GetTextureSize and texture
  properties; direct mutable texture fields are unnecessary.
- Palette version/refcount and DisplayMode.internal are SDL-private.
  Surface/Texture refcount is a native lifetime mechanism, deliberately separate
  from script destruction scopes. AssertData belongs to host diagnostics.

## Reproducible audit and limits

[record-field-policy.json](../tools/record-field-policy.json) lists all 254
non-direct fields explicitly. No padding/name-prefix rule automatically classifies
future fields. [audit_record_fields.py](../tools/audit_record_fields.py) compares it
with the pinned header inventory and bindings.json, checks source evidence and
adapter registration, and emits the [field report](generated/record-fields-windows-x64-msvc.md)
and JSON. Use `python tools/audit_record_fields.py --check` to verify freshness.

The inventory contract tests reject new unreviewed fields, duplicate decisions,
removed adapter registrations and stale decisions after a field becomes direct.
Static evidence is not proof of runtime behavior; existing package tests supply
that separately. The field audit remains separate from runtime tests.

Scope excludes opaque forward declarations, anonymous union interiors (their
parent field is classified), project-specific records, macro semantics and
non-Windows ABI branches. Platform/browser and hardware validation remain separate.

## Validation — 2026-09-26

Windows x64/MSVC, SDL 3.4.16 and the pinned daScript revision:
- Main runner: 4/4 record tests/example passed.
- Baseline, CppGenBind and strict AOT plus metadata parity: 13/13 passed.
- Installed SDK, generators/LLVM disabled: a separate consumer passed 5/5
  interpreter/AOT tests, including rejection of AOT fallback.
- Binding freshness and API inventory/contracts: 3/3 passed; record-field audit is current.
- Temporary surface-byte escape is rejected by the compiler; existing pixel-view,
  row and byte escape checks also pass.
- The Vulkan tests create real devices, exercise absent extension failures and
  preserve caller properties with an existing numeric-to-string cache.

Surface layout fixtures cover packed/sub-byte/float and planar YUV formats,
odd dimensions, row padding, empty spans, invalid planes and deferred unlock
on body errors. Native virtual callbacks are invoked by SDL; Cleanup runs once
on detach. Arbitrary Vulkan feature chains, forced allocator failures and
other platform ABIs are not claimed by these tests.
