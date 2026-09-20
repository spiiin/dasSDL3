> Historical implementation record. The framework API described here was removed.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.
> Do not use this as current binding guidance. See [API boundary](gpu-api-boundary.md)
> and [current GPU roadmap](gpu-roadmap.md). Old test counts describe earlier revisions.

# Opaque mesh/material batches

Example 20 groups 64 animated cubes with two textures into two indexed instanced
draws in one render pass. `sdl3_gpu_batches_boost` exports `GpuBatchList`,
`gpu_batch_add(list,mesh,model,color=float4(1.0))`, `gpu_batch_clear`,
`with_gpu_batch_scene(device,window) $(scene) { ... }` and
`gpu_draw_batches(device,window,scene,list,camera,light_direction,ambient=0.2)`.
The draw returns true for a submitted drawable, false for a skipped frame and
panics on an error, like the other GPU boost draw functions.

## Group identity and ownership

For the original owned bundles, a group key is the exact colored instanced mesh ID, representing its geometry,
texture, sampler and pipeline. Non-adjacent objects with the same ID are merged;
different IDs remain separate even when their resources contain identical data.
This original bundle path does not deduplicate content. Example 22 adds a
separate material/geometry resource path (see the extension below). To create a template use the
existing `with_gpu_colored_instanced_mesh` with one identity, white instance.
Its original instance count, contents and upload readiness are not used by a
batch draw: geometry/material are borrowed, instance data comes from the scene.
The original template instance allocation remains owned by that mesh bundle.

Lists own IDs, model columns and colors, but never own mesh resources. All IDs
are resolved for every draw and must remain alive on the same device. Create
the mesh scopes outside the batch scene scope. The scene owns a cached shared
depth target and lazily creates one 512 KiB instance buffer and one 512 KiB upload
buffer. Scope cleanup handles normal exit, early block return and panic through
the protected callback adapter; device destruction cleans only its own scenes.
Releasing a scene does not release its meshes, or vice versa.

## Draw contract

- 0..4096 objects and at most 64 distinct mesh IDs per call. Count and group
  membership may change on every frame. Empty lists clear/present without upload.
- Exactly four float4 model columns and one finite normalized RGBA per object.
  Models must be finite, affine and nonsingular. Camera and light follow the
  existing lit contract. Every item is checked before GPU allocation/acquisition.
- Only colored stride128 meshes with matching device, color and depth formats
  are accepted. Plain stride112 and non-instanced meshes are incompatible.
- One camera and light per call; each object has its own model, inverse-transpose
  normal matrix and RGBA multiplier. Shader assets are unchanged: `colored_instances.*`.
- Groups follow first appearance, objects remain stable within each group. This
  changes cross-group submission order. Opaque depth testing/writes resolve
  ordinary overlap; coplanar ties may render differently. Blending, transparent
  sorting, per-object textures within a draw and general draw ranges are pending.

The native adapter repacks the entire active list into contiguous group slices,
cycles both transfer and destination buffers, and submits the upload before
acquiring the swapchain. Each indexed draw binds its slice by byte offset in
instance buffer slot 1; first_instance stays zero and instance_step_rate stays
zero as required by SDL. Unused tail bytes are undefined and never drawn. No
script callback runs while commands are recorded, and production has no fence
or idle wait. Submitted frames can remain in flight during subsequent uploads.

Invalid input leaves existing GPU data untouched and produces no frame. An
upload/submission failure returns before swapchain acquisition; the next call
always uploads the full list and can recover. Once a non-null swapchain texture
has been acquired, shared frame handling submits even if depth/pass setup fails;
it never cancels that command. Depth dimensions follow the acquired drawable.
Input arrays may be cleared after the draw returns; no array pointer is retained.

## Verification

`tests/gpu_batches.das` and `tests/gpu_batches_probe.h` use an independent CPU
projection/depth/normal/color reference with two distinct texture RGBA values.
They check A/B/A merging, reversed group order, cross-group depth, three objects
from one-instance templates, one/two/empty groups, twelve queued alternating
group layouts, invalid late IDs/colors/models and array counts, incompatible
plain ABI, failed-upload recovery, stale/foreign/cross-kind IDs, resize, panic,
early return and device-specific cleanup. Test readback/fences are not public API.
The injected upload failure exercises the pre-acquisition error path; it does
not simulate every possible driver/device-loss failure.

Run from the repository root:

```powershell
.\build\ninja\bin\dasSDL3_runner.exe .\examples\20_gpu_material_batches.das --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
```

The optional filter addresses this machine's FPS Monitor overlay conflict only;
see [gpu-multidevice.md](gpu-multidevice.md). Escape exits, resize works. Add
`--smoke-test` for 60 deterministic frames. No new shader compiler is required.

## Verified on 2026-09-19

- Main CTest: 69/69 passed.
- Baseline/CppGenBind/strict-AOT CTest: 148/148 passed, including the negative
  missing-AOT test and both backend batch tests.
- Example 20: 60 frames on Vulkan and D3D12 in the main runner, strict AOT
  (`main AOT=yes; fallback disabled`) and LLVM-free consumer build.
- After restoring the generator-enabled configuration: 6/6 targeted batch,
  ClangBind probe and snapshot freshness tests passed.
- Full test and example logs contain no `VUID-` or `Validation Error`.
  Only the known overlay layer was filtered in these processes.
- Policy snapshots regenerated; `git diff --check` passed.

## Extension: shared resources (example 22)

In addition to owned mesh bundles, lists accept lightweight shared mesh IDs.
Their grouping key is the exact (geometry,material) pair, so separate binding IDs
for that pair merge. Parent IDs are resolved at each draw, without lifetime
extension. The original bundle-ID behavior is unchanged. See `gpu-shared-resources.md`.
