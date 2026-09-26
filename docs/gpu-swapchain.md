# Checked GPU swapchain settings

Module: dassdl3/sdl3_gpu_swapchain_boost; native adapters: src/sdl3_gpu_swapchain.h.
Examples 30–32 query/configure the window. Actual presentation is demonstrated
by [native example 48](../examples/48_gpu_native_graphics.das).

## Contract

Operations require a live scoped device, a live window claimed by that device,
and the main thread. The adapter checks windows against SDL_GetWindows; pointer
address reuse is not a generation check, so borrowed pointers must not outlive scope.

- gpu_supports_present_mode/composition return Result<bool,SdlError>: Ok(false)
  means unsupported; invalid input is Err. Native Checked queries retain -1/0/1.
- gpu_swapchain_format returns Result<format,SdlError>.
- gpu_configure_swapchain checks support before mutation and returns
  Result<bool,SdlError>; Ok(false) means unsupported.
  SDL setter failure retains SDL's state semantics; no transactional rollback.
- gpu_frames_in_flight accepts 1..3, device-wide. SDL stalls/flushes on change;
  this is not an FPS limiter or measured latency claim.
- gpu_wait_swapchain waits for availability, without acquiring a texture,
  presenting, pumping events or proving a drawable exists.

Configure between command recordings, with no acquired swapchain texture/pass
still in use. A composition change can change format; recreate incompatible
pipelines. Settings persist until changed/released and are per window, unlike
the device frame limit. No automatic restoration scope is added.

Native acquire can succeed with null texture; skip drawing then. Once acquisition
returns a non-null texture, submit that command instead of cancelling it.
with_native_gpu_swapchain implements this defer policy; its callback borrows
command/texture and must not consume/release them.

## Checks and limits

Tests/gpu_swapchain.das checks supported combinations, invalid values, unclaimed/
foreign/released windows, frame limits, two windows/devices and reclaim. It no
longer relies on removed triangle helpers. Native graphics/raw tests cover actual
acquisition/presentation. Capability reports do not prove HDR color accuracy.
Other platforms and HDR displays need their own verification.
See [gpu raw tests](gpu-raw-tests.md).
