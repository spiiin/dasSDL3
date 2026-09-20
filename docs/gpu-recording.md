# Direct SDL GPU command buffers and render passes

The primary low-level GPU direction is now SDL's command-buffer/pass model.
`dassdl3/sdl3_gpu_recording_boost.das` wraps checked native adapters in
`src/sdl3_gpu_recording.h`. Example 46 uses this path. Command plans and renderer-framework APIs have been removed; see gpu-api-boundary.md.

## Execution and lifetime

`with_gpu_command_buffer` acquires a real SDL_GPUCommandBuffer immediately.
`gpu_begin_render_pass` starts a real SDL_GPURenderPass. Bind, state, uniform and
draw calls record immediately; there is no CPU operation list, replay or
per-draw copy of uniforms. Multiple draws share one pass. SDL copies pushed
uniform bytes; the adapter retains only slot-presence bits. Bindings retain
bounded arrays of resource IDs for validation, not script-array addresses.

The checked raw adapters use SDL names suffixed `Checked`; stage-selected
sampler/uniform adapters cover the corresponding vertex and fragment functions.
Boost helpers are small error checks with receiver-first arguments.
SDL error results pass through to the caller. The owner calls its block directly
and uses defer; no script try/recover or native protected invocation remains.

Explicitly end the pass, then submit or cancel the command buffer. Both consume
its ID, including submission failure. End consumes the pass ID. Submit/cancel
with an open pass is rejected without consuming anything. On scope exit, early
return, deferred cleanup ends an open pass and cancels unfinished work; there is
no automatic submission. This slice cannot acquire swapchain textures, so its
cancellation is legal. Device cleanup ends/cancels recordings before releasing
resources; cleanup is device-specific.

Handles use the existing monotonic ID namespace and separate registries.
Wrong-kind/device/thread and stale IDs are rejected before native calls. All
operations are currently main-thread-only. The raw checked acquire/begin/end
functions support manual lifetime management; scoped use is recommended.
Resource IDs are borrows, not ownership. Releasing a bound resource makes later
draws fail validation; already recorded references follow SDL's deferred release
semantics. Rebind after changing resources. Do not confuse immediate recording
with immediate GPU execution: submission still controls execution.

This API does not prevalidate an entire future command sequence.
A rejected call leaves previously recorded work intact. On a false result,
the caller can correct it or explicitly cancel. Normal/early scope exit cancels
unsubmitted work; arbitrary application panic does not promise cancellation. Failed submission marks written target subresources invalid.
Successful cancellation preserves their previous validity/content.

## Initial supported slice and costs

- Offscreen RGBA8/BGRA8 UNORM color target, one attachment, sample 1, valid
  mip/layer, CLEAR or LOAD, STORE, no cycling/depth/MSAA.
- Standalone graphics pipelines and checked vertex/index buffers; direct and
  indexed draws, multiple draws per pass, multiple sequential passes per command.
  Vertex binding accepts a first slot. Indexed buffer byte offset and
  first_instance are currently zero; first_vertex/first_index/base_vertex are
  explicit. Count product is bounded to 1,048,576.
- Viewport/scissor within target bounds, normalized blend constants.
- Vertex/fragment ordinary Texture2D<float4> sampling, RGBA8/BGRA8 UNORM,
  noncomparison samplers, all mip levels valid, no target feedback. Sampler
  binding currently replaces the complete stage array starting at slot zero;
  its count must match the current pipeline's declared count.
- Vertex/fragment uniforms, slots 0..3, nonempty 16-aligned bytes up to 16 KiB
  or float4 arrays. Required slots must have been pushed; extra pushed slots are
  allowed. The caller supplies trusted std140 packing and matching shader ABI;
  no reflection/size inference is performed.

Checks still cost registry lookups and range validation; indexed draws scan the
selected immutable CPU index range. This is a checked adapter, not a claim of
zero overhead or measured speedup. Native binding arrays are fixed-size; the
adapter stores a list of written subresources only for submit-failure invalidation.
It does not retain draw operations or uniform blobs. Broader format/storage,
copy/compute, swapchain, fences and attachments are available through the
separate native pointer API; this checked subset keeps its stated restrictions.

## Validation

`tests/gpu_recording.das` uses an independent CPU image reference for all 4096
pixels, nearest/bilinear sampling, two draws with different scissor/uniform state
in one pass, and mutation of source arrays after binding/push. It checks missing
resources, rejected state changes, range errors, feedback, stale sampler/texture,
double end/submit/cancel, SDL-error/early-return cancellation and pixel preservation.
Native fixtures cover oversized arrays, wrong thread, injected submit failure,
foreign-device handles and device destruction with a live pass while another
device's command survives. Vulkan and D3D12 are the local runtime targets.

Latest combined verification: [gpu-native-validation.md](gpu-native-validation.md).
Current function census: [api-coverage.md](api-coverage.md).
This page describes the checked subset. Full native pointers/arrays and scopes
are documented in [gpu-native-boost.md](gpu-native-boost.md); IDs and native
handles are separate. Other platforms and all hardware formats are not certified.
