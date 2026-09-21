# Native command buffers and fences

P6 lifecycle slice, pinned SDL 3.2.18. Generated from SDL headers through the
legacy/CppGenBind parity path: SDL_AcquireGPUCommandBuffer,
SDL_SubmitGPUCommandBuffer, SDL_SubmitGPUCommandBufferAndAcquireFence,
SDL_CancelGPUCommandBuffer, SDL_WaitForGPUFences, SDL_QueryGPUFence and
SDL_ReleaseGPUFence. SDL_WaitForGPUIdle was already generated. The new opaque
pointer types are SDL_GPUCommandBuffer and SDL_GPUFence.

These are the actual SDL signatures and handles, separate from [checked distinct IDs](gpu-handles.md).
They introduce no new owner type or resource registry. Do not mix raw native
pointers with the Checked recording API. Follow SDL ownership: acquire and
submit/cancel on the same thread; submit/cancel consumes the command even on
failure; release each fence once, before destroying its device. All fences in
a wait must be live and belong to that device. The binding does not validate
arbitrary/stale/foreign raw pointers. A copied pointer does not extend lifetime.

SDL_WaitForGPUFencesArray(device,wait_all,fences) is the only new language adapter.
It borrows an array<SDL_GPUFence?> synchronously, passes its storage and count to
SDL, and returns SDL's bool result. It checks null device/elements/storage, empty
arrays and uint32 count overflow before calling SDL. It allocates no second list,
retains no pointers and does not release fences. The generated pointer/count
signature remains available for callers managing native memory directly.

Query returns true for signaled, false for pending; false is not automatically an
SDL failure. Wait and submit return bool; submit-with-fence returns null on failure.
Read SDL_GetError only after an operation reports failure. No panic or catch bridge.

Example 47 uses raw SDL device/command/fence pointers with explicit result checks
and defer. It waits for completion before releasing the fence. In pinned Vulkan,
early release of an unsignaled fence can cause fence-pool reuse while still in use;
the raw export intentionally does not add hidden waiting or retirement. Existing
checked readback tickets retain their separate asynchronous retirement mechanism.

Tests exercise repeated submit/query/wait-any/wait-all/release, array mutation,
cancellation, ordinary submit, wait-idle, early-return
cleanup, two devices and array rejection before native calls. Submission contains
no draw commands in this slice; existing recording tests still verify pixels.
Never test stale raw handles by passing freed pointers into SDL.

Swapchain acquisition, transfer creation and native pass/resource scopes are now
available in [gpu-native-boost.md](gpu-native-boost.md), examples 48–50.
