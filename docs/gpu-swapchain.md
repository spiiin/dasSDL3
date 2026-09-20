# GPU packages 30–32: swapchain control

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.

Pinned SDL 3.2.18. Module: `dassdl3/sdl3_gpu_swapchain_boost.das`.
Native checked adapters: `src/sdl3_gpu_swapchain.h`.

## 30: capabilities and current format

`gpu_supports_present_mode(device,window,mode)` and
`gpu_supports_composition(device,window,composition)` require a live scoped
device and a live window claimed by that device, on the main thread.
The adapter compares the window address with SDL_GetWindows before calling
window APIs; invalid/unclaimed/foreign/null windows fail without backend access.
Window/device pointers remain borrowed scope values, not generational handles;
do not keep them beyond their scope (address reuse cannot identify an old borrow).

All three present modes and all four compositions from the pinned header are
generated uint constants. Unknown numeric values cause a script panic;
unsupported valid values return false. `gpu_swapchain_format` returns the
current SDL texture-format constant and rejects invalid handles. Enumeration
is target/display dependent and is not a promise of HDR color correctness.
SDR + VSYNC is SDL's required baseline.

## 31: configuration between frames

`gpu_try_configure_swapchain(device,window,composition,mode)` returns false
without calling the mutating SDL setter if either capability is unsupported.
Invalid input and an SDL setter failure panic. A setter failure has SDL's own
state semantics; the adapter does not promise transactional rollback.
Settings last until explicitly changed or the window is released. There is no
automatic restoration scope and no cache of presumed native settings.

Call between completed script frame helpers. The current API records/submits
frames entirely in native code, so no script callback can change the swapchain
while a pass is open. Future command/pass bindings must enforce that restriction.
Changing composition can change the swapchain texture format: query it and
recreate incompatible pipelines. Existing fixed GPU draw helpers check format
compatibility; tests keep an old triangle pipeline across transitions, verify
rejection when the format differs, then draw again after restoring SDR/VSYNC.
Changing one window's parameters does not configure other windows.

## 32: frames in flight and availability

`gpu_frames_in_flight(device,count)` accepts exactly 1..3. It is device-wide,
not per window. SDL stalls and flushes the command queue when changing it;
configure it deliberately rather than calling it every frame. SDL defaults to
two. This is a queue/latency limit, not an FPS limiter or measured latency result.

`gpu_wait_swapchain(device,window)` blocks for availability. It does not acquire
a texture, submit/present a frame, pump events or wait for global device idle.
A subsequent acquisition can still return no drawable (e.g. minimized). Use
the existing submitted/skipped result from `gpu_clear` or other frame helpers.
Do not infer drawable size or visibility from a successful wait alone.

## Verification

`tests/gpu_swapchain.das` exercises all reported composition/mode combinations,
invalid values, unclaimed/foreign/released/destroyed windows, dead devices,
limits 1/2/3, consecutive waits/presents, two windows, two devices, reclaim,
and pipeline compatibility after format changes. Hardware capability outcomes
are printed, with unsupported combinations explicitly returning false.
Examples 30/31/32 demonstrate queries, mode changes and latency configuration.
Interpreter/AOT and Vulkan/D3D12 checks share this contract; Linux/Metal and
actual HDR output/color accuracy remain unverified.

Observed on this Windows machine: both backends accepted all three present
modes with SDR and SDR_LINEAR. Vulkan rejected both HDR compositions;
D3D12 accepted HDR10_ST2084 but rejected HDR_EXTENDED_LINEAR. These are logged
capability results, not portable assumptions. Tests exercised both real format
changes (and incompatible pipeline rejection) and unsupported no-mutation paths.
SDL_GetWindows is an internal liveness check here, not a new public enumeration
binding counted by the inventory.

Combined verification on 2026-09-20:

- Main project: 110/110 CTest; parity/interpreter/strict AOT: 247/247.
- Standalone dasClangBind experiment: 4/4. Generated selection is deterministic:
  60 functions, 10 records, 7 opaque types, 49 fields, 181 constants (7 new).
- Examples 30–32 passed on Vulkan and D3D12 in the LLVM-free consumer build,
  with generators and Clang/LLVM/Python package discovery disabled. build.ninja
  contains no libclang/libLLVM or binding-generator commands.
- Completed main/parity logs contain no VUID, Validation Error or D3D12 ERROR.
  The existing FPS Monitor layer filter stayed process-local.
- GPU inventory: 7 generated / 55 adapted / 30 pending; total SDL API:
  60 generated / 64 adapted / 1102 pending. Adapted contracts remain partial.
- Developer generator configuration restored; final snapshot freshness,
  inventory and Clang preflight checks: 5/5 passed.
