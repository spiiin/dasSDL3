# P6: complete direct SDL GPU bindings

> Current declaration coverage: all 92 active Windows GPU functions are generated.
> See [native GPU API](gpu-native-api.md). Runtime/AOT validation of the expanded
> surface is pending; earlier gaps below describe the previous checked subset.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.

The binding follows SDL objects and operations. Renderer plans, meshes, materials,
scenes and batching have been removed: see gpu-api-boundary.md. This replaces the
previous implementation chronology. Do not expand an engine layer to close an API gap.

## Current baseline

SDL 3.2.18; Windows x64/MSVC; Vulkan and D3D12 locally tested. Generated GPU enums
and selected descriptors, independent shader/pipeline/sampler objects, bounded
buffer/texture/volume transfers and a direct offscreen graphics subset exist.
The authoritative function census is generated from pinned headers: GPU 92 =
92 generated + 0 adapted + 0 pending. Adapted does not mean complete.
Read gpu-recording.md, gpu-transfer.md, gpu-texture-transfer.md, gpu-pipelines.md
and api-coverage.md for the actual constraints. Public copy/compute passes and
swapchain acquisition are not established by internal calls in a helper.

Native command/fence lifecycle is now generated, including the original
WaitForGPUFences signature and a borrowed-array adapter. See gpu-native-fences.md
and example 47. Raw SDL pointers do not interoperate with checked uint64 command
IDs. Native swapchain/render/copy/compute access is now generated as well; the
remaining work is validating the expanded signatures, language adapters and
direct examples together. The sequence below is the validation checklist now,
not a list of declarations still absent from the generated binding.

## Implementation order

1. Audit every GPU declaration against its exported signature and state/lifetime
   contract. Separate generated raw access from array/ownership adapters. Generate
   direct signatures wherever possible; avoid project concepts in public names.
2. Add native swapchain acquire/wait-and-acquire and borrowed texture lifetime.
   Native command submission and fence wait/query/release are now generated.
   Never cancel after a non-null swapchain acquisition; finalize on normal/error
   return via defer. Add compatible native render-pass descriptors and operations.
3. Direct copy-pass begin/end, transfer-buffer create/map/unmap/release and
   upload/download/copy operations, with explicit offsets, strides and cycling.
   Existing readback conveniences must not hide missing direct operations.
4. Complete graphics bindings: first slots, vertex/index offsets, first-instance,
   sampled/storage buffers and textures. Keep validation bounds explicit;
   replace adapter restrictions where SDL supports broader use.
5. Render attachments: multiple color targets, depth/stencil, sample counts,
   resolve, load/store and cycling. Test output and pass state, not just creation.
6. Compute pipelines/passes, storage bindings, uniforms and direct/indirect dispatch.
7. Indirect graphics draws, debug labels/groups and remaining property/platform
   paths. Preserve the pinned D3D12 debug-group limitation until verified fixed.
8. Close coverage: enum/record/field ABI, errors, thread/state/lifetime edges,
   interpreter/AOT parity, no-LLVM consumer, Vulkan/D3D12 pixel and byte references.
   Add other platforms/backends before claiming cross-platform completion.

## Verification rules

Keep GPU resources scoped to their device; stale/wrong-kind/device handles must
not reach native calls. No script per-call try/recover. Preserve script defer ownership and the asynchronous fence-retirement rule. Keep
validation enabled; machine-specific Vulkan layer filtering is opt-in only.

Tests and examples should demonstrate SDL operations directly. Application code
such as matrices or lighting belongs in the example. A shader DSL, reflection,
SDL_shadercross and SDL companion libraries are separate follow-ups after their
underlying SDL access is complete. No scene/material/batching API is planned here.
