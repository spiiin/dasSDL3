# P6: complete direct SDL GPU bindings

> Current declaration coverage: all 92 active Windows GPU functions are generated.
> The five native-adapter follow-up steps are implemented and locally validated
> on Vulkan/D3D12 (Windows x64). See [native guide](gpu-native-boost.md) and
> [results and remaining limits](gpu-native-validation.md). This is not a
> cross-platform completion claim.

The binding follows SDL objects and operations. Renderer plans, meshes, materials,
scenes and batching have been removed: see gpu-api-boundary.md. This replaces the
previous implementation chronology. Do not expand an engine layer to close an API gap.

## Current baseline

SDL 3.2.18; Windows x64/MSVC. All 92 active Windows GPU declarations are
available. Raw execution covers 92 Vulkan calls and 90 D3D12 calls; the two
D3D12 debug-group calls are excluded for a pinned backend issue.

Completed follow-up:
1. Shader/compute bytecode and file inputs; graphics pipeline descriptor arrays.
2. Bounded byte-array transfer access, synchronous map/copy/unmap without escaping views.
3. Native resource/pass/command defer scopes and swapchain submission cleanup.
4. MRT, depth/stencil, MSAA/resolve, load/store/cycle, slots/offsets/first-instance
   checked against CPU pixel and byte references.
5. Public graphics/compute/transfer examples 48–50, interpreter/AOT parity and
   no-LLVM consumer verification.

The older checked-ID API remains separate from native SDL pointers. Native handles
require the caller to obey SDL ownership, device, thread and synchronization rules.
See gpu-native-boost.md; no registry or framework objects were added.

The next library-wide vertical is P1 Properties, followed by Hints/Init,
Video/Render and IOStream/Events. Keep GPU backend limitations visible; Metal,
other operating systems and platform-specific declarations need their own tests.
A shader DSL and companion libraries remain separate projects in the roadmap.

## Retained GPU maintenance checklist

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

Keep GPU resources scoped to their device. Checked IDs validate provenance; native
pointers require valid/live/same-device handles as caller preconditions. No script per-call try/recover. Preserve script defer ownership and the asynchronous fence-retirement rule. Keep
validation enabled; machine-specific Vulkan layer filtering is opt-in only.

Tests and examples should demonstrate SDL operations directly. Application code
such as matrices or lighting belongs in the example. A shader DSL, reflection,
SDL_shadercross and SDL companion libraries are separate follow-ups after their
underlying SDL access is complete. No scene/material/batching API is planned here.
