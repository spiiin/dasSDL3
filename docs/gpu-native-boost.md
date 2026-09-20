# Native GPU adapters and scopes

`require dassdl3/sdl3_gpu_native_boost` exposes native SDL pointers and small
`defer` scopes. This module is separate from the older checked uint64 adapters.
Never interchange their resource handles. No plan, mesh, material or scene is
introduced, and no callback is invoked through a native catch bridge.

## Creation from script data

- `SDL_CreateGPUShaderBytes(device, info, bytes, entrypoint)` and
  `SDL_CreateGPUComputePipelineBytes(...)` accept byte arrays. An aligned temporary
  copy exists during the synchronous SDL creation call; it is then destroyed.
  `code`, `code_size` and `entrypoint` in the supplied descriptor are overridden
  locally. The caller's descriptor is not changed. Metadata, props and resource
  counts are preserved; compiled code and its shader ABI are trusted input.
- `SDL_LoadGPUShaderFile` and `SDL_LoadGPUComputePipelineFile` perform the same
  operation from a file, freeing file bytes on success and failure. Missing files
  return null and preserve SDL's error result.
- `SDL_CreateGPUGraphicsPipelineArrays(device, info, buffers, attributes, colors)`
  supplies all pointer/count fields from arrays for that call only. Vertex slots
  are sorted in a temporary copy and must be unique/dense for the pinned backend.
  No caller arrays or descriptors are mutated or retained. SDL's descriptor and
  live-handle preconditions still apply; these are not shader reflection helpers.
- `SDL_CreateGPU{Buffer,Texture,TransferBuffer,Sampler}Ref` and the copy/state
  `*Ref` adapters accept records without script address expressions. They preserve
  the original SDL operation, fields and ownership.

Raw const-pointer descriptor fields remain non-assignable in pinned daScript.
The adapters solve construction without weakening language pointer checks or
returning descriptors that point into expired arrays.

## Transfer memory

`SDL_WriteGPUTransferBufferBytes(device, buffer, capacity, offset, bytes, cycle)`
and `SDL_ReadGPUTransferBufferBytes(device, buffer, capacity, offset, bytes)` map,
copy and unmap within one synchronous native call. The read destination is a
pre-sized array. No pointer or borrowed mapped array escapes to script; no script
callback runs while mapped. There is no implicit GPU submission or wait.

`capacity` MUST equal the creation size of that live native transfer buffer.
SDL exposes no size query, and the adapter has no resource registry with which
to verify this claim. Correct device, usage and completed GPU work are caller
preconditions. Checks bound the array size and offset against the declared
capacity before mapping or pointer arithmetic. Zero bytes are a no-op (even with
cycle=true). This is lifetime-safe argument conversion, not protection from a
forged native handle or a falsely declared capacity.

## Cleanup and command ownership

`with_native_gpu_device`, resource/shader/pipeline scopes and copy/render/compute
pass scopes acquire first, enter a nested cleanup scope, invoke the block directly
and release/end with script `defer`. False acquisition skips the callback. A true
return reports acquisition success; the callback's own operation results must
be checked separately. Normal and early returns run cleanup. Pinned application
panic does not guarantee cleanup. Native pointers must not escape their owners.

`with_native_gpu_commands` is for offscreen commands. Its mutable command
reference must be consumed using `native_gpu_submit`, `native_gpu_submit_fence`
or `native_gpu_cancel`, which null it even when SDL returns failure. Unconsumed
commands are cancelled at scope exit. End all passes before consuming a command.
Do not acquire a swapchain inside this cancellation scope.

`with_native_gpu_swapchain` owns the acquisition command. A successful null
texture (minimized window) skips the callback and cancels the empty command.
Once a non-null texture is acquired, cleanup submits rather than cancels, including
after callback early return. The callback borrows the command and texture and
must not consume/release them. It must end passes before returning. The helper
returns acquisition/submission success; it does not release or read the borrowed
swapchain texture. The claimed window and device must outlive the call.

Fence wait/release stays explicit. Wait before release because of the pinned
Vulkan unsignaled-fence issue. The examples do not release a fence after a failed
wait; device teardown owns final backend cleanup in that error path.

## Examples and verification

- `48_gpu_native_graphics.das`: create shaders/pipeline from script descriptors,
  render a triangle to a borrowed swapchain, submit from deferred cleanup.
- `49_gpu_native_compute.das`: compute pipeline, uniform bytes, storage output,
  fenced download with a CPU reference (`10 + 3*i`).
- `50_gpu_native_transfer.das`: byte-array roundtrip through two GPU buffers,
  nonzero offsets and cycling; all 100 bytes checked.

All three use public modules only, with no `unsafe` or test fixture exports.
`--smoke-test` bounds graphics to three frames; its default run draws 180 frames.

`tests/gpu_native_adapters.das` additionally checks temporary bytecode lifetime,
failed acquisition skipping a callback, construction scopes and early returns,
out-of-range transfer spans, vertex slot normalization without mutation, first
binding slot 1, vertex/index byte offsets, first vertex/index/instance and indexed
vertex base. Two color targets use 4x MSAA with RESOLVE_AND_STORE. Depth LESS
rejects a farther draw; stencil EQUAL rejects a wrong reference; a permitted
indexed draw changes only half the image. Both resolved textures are read back
and compared pixel by pixel. LOAD/STORE preserves depth/stencil and MSAA colors
between passes, and the first pass exercises attachment cycling.

SDL 3.2.18 D3D12's depth sample-count query uses the SRV format instead of the DSV
format and reports false on this machine. The test checks depth format support,
then actual 4x creation and pixel results with validation enabled; the binding
does not change SDL's query result. The D3D12 debug-group and combined-buffer
limitations in gpu-raw-tests.md also remain documented.

Shader maintenance: `tools/build_native_gpu_shaders.py --dxc <path> --spirv-val
<path> [--check]`. Normal builds use the committed SPIR-V/DXIL files; no shader
compiler is required by consumers. No other platform/backend is certified here.
