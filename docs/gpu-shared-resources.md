> Historical implementation record. The framework API described here was removed.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.
> Do not use this as current binding guidance. See [API boundary](gpu-api-boundary.md)
> and [current GPU roadmap](gpu-roadmap.md). Old test counts describe earlier revisions.

# Shared geometry and materials

Example 22 uses one cube geometry with two materials for 2304 culled instances.
Unlike examples 20/21, it allocates the vertex/index buffers once, and creates
no seed instance buffer for either material. C toggles culling, Space pauses
animation, Escape exits. The title shows resource counts and frame candidates.

## Public API and ownership

`require dassdl3/sdl3_gpu_resources_boost` re-exports culling and batches and adds:

- `with_gpu_geometry(device,positions,normals,uv,indices) $(geometry) { ... }`.
  Owns immutable stride48 vertex and UINT32 index buffers, independent of target.
- `with_gpu_material(device,window,pixels,width,height,vertex_file,fragment_file,format) $(material) { ... }`.
  Owns an RGBA8 texture, nearest/clamp sampler and colored-instance graphics
  pipeline. Its color/depth formats must match the batch scene target.
- `with_gpu_shared_mesh(device,geometry,material) $(mesh) { ... }`.
  Creates a lightweight, non-owning pair of parent IDs, without GPU allocation.
  Use this ID with GpuBatchList, gpu_batch_add/visible and gpu_draw_batches.

Raw create/release functions are SDL_CreateGPUGeometry/SDL_ReleaseGPUGeometry,
SDL_CreateGPUMaterial/SDL_ReleaseGPUMaterial and
SDL_CreateGPUSharedMesh/SDL_ReleaseGPUSharedMesh. Create returns zero and release
returns false on failure, with SDL_GetError. Boost scopes panic on failure and
use the protected callback/recover/cleanup/rethrow mechanism on every exit.
All resource operations and draws require the main thread.

Nest geometry and material scopes outside their shared mesh scopes, inside the
owning device. A scene owns only its depth and cycled instance/upload buffers.
The binding does not retain either parent, and releasing it never releases its
parents. Releasing geometry/material invalidates all surviving bindings using
that parent: their next batch draw fails during preflight. Binding release still
works after a parent was released. No raw borrowed GPU pointer is cached across
calls. SDL defers underlying resource destruction for already submitted commands;
future commands must use live IDs. Device destruction cleans only its own entries.

IDs share the existing monotonic namespace but have separate kind/device registries.
Stale, foreign-device and wrong-kind IDs are rejected. Direct lit/ordinary instance
update/draw/release APIs reject shared mesh IDs; their supported draw path is batches.
No reference counting, implicit lifetime extension or content deduplication is implied.

## Layout, copying and grouping

Geometry creation validates every position, normal, UV and index before any GPU
allocation. Limits: 1..349525 vertices, matching position/normal/UV arrays; nonempty
triangle-list indices, at most 4194304 UINT32 entries. Positions must have w=1,
normals w=0 and nonzero length; normals are normalized, UV is finite in 0..1.
Each packed vertex/index stream is at most 16 MiB. Data is copied synchronously
into staging storage; source arrays can be cleared after create returns.

Material creation copies exactly width*height*4 RGBA8 bytes, up to 16 MiB and
8192 per dimension. It uses the trusted colored_instances SPIR-V/DXIL ABI:
stride48 geometry, stride128 scene instances (model/normal/RGBA), camera64,
light16 and one fragment texture sampler. Depth test/write are enabled;
blending is disabled. Shader reflection and arbitrary material state are pending.
Materials can be reused with multiple geometries; different material IDs still
own separate textures/samplers/pipelines, even when their content is identical.

Shared draws group by the exact (geometry ID, material ID) pair. Distinct binding
IDs for the same pair coalesce into one indexed draw. Existing owned colored mesh
IDs remain supported, including mixed lists; each retains its old distinct group.
Different geometry IDs remain separate even with identical vertices. First-appearance
group order, 4096 objects / 64 groups, full preflight, shared scene depth and buffer
cycling are unchanged. No temporary vertex/index buffers or seed instances are
created when making a shared binding. Coplanar ordering/transparency limitations
from `gpu-material-batches.md` still apply.

Common vertex validation/packing and pipeline construction were extracted from
the old lit builder and reused by both paths. The batch plan holds temporary
borrowed views by value, never frees them, and records without script callbacks.

## Verification

`tests/gpu_resources.das` checks native buffer identity and absence of redundant
geometry/instance allocations in materials, distinct-ID coalescing, shared and
legacy mixed draws, two geometries using one material, CPU-reference texture/
lighting/depth pixels and twelve queued frames. It also covers invalid indices,
failed material creation, released bindings/parents, wrong-kind/foreign-device IDs,
resize, pending-submission resource release, two-device cleanup, copied arrays,
early return and exact panic-message propagation through nested scopes.

Run from the repository root:

```powershell
.\build\ninja\bin\dasSDL3_runner.exe .\examples\22_gpu_shared_geometry.das --disable-vulkan-layer=VK_LAYER_RENDERDOC_Capture
```

The optional per-process filter addresses this machine's FPS Monitor conflict;
see `gpu-multidevice.md`. Add --smoke-test for 60 deterministic frames on the existing
saved shader assets. This adds resource adapters, not new SDL symbol coverage.

## Verified on 2026-09-19

- Main CTest suite: 78/78 passed, including the refactored legacy lit/instance paths.
- Baseline/CppGenBind/strict-AOT suite: 167/167 passed; resource tests pass on
  Vulkan and D3D12 with CPU-reference readback and deferred-release checks.
- Example 22: 60 frames each on Vulkan and D3D12 in the main runner, strict AOT
  (`main AOT=yes; fallback disabled`) and LLVM-free consumer build.
- Generator-enabled configuration restored; 6/6 targeted resource, ClangBind
  probe and snapshot freshness tests passed again.
- Full test/example logs contain no `VUID-` or `Validation Error`.
  Only the known overlay was filtered per process; validation was not disabled.
- Policy snapshots regenerated; `git diff --check` passed. SDL coverage counts
  and shader assets are unchanged.
