> Historical implementation record. The framework API described here was removed.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.
> Do not use this as current binding guidance. See [API boundary](gpu-api-boundary.md)
> and [current GPU roadmap](gpu-roadmap.md). Old test counts describe earlier revisions.

# Texture/sampler and uniform bindings in render plans

Example 46 connects independent samplers/textures and copied vertex/fragment
uniforms to the native render plan. This P6 batch covers ten related steps:

1. CPU-plan binding state for two shader stages.
2. Copied dense texture/sampler ID arrays, up to 16 pairs per stage.
3. Texture type, format, usage, sampler comparison and mip-validity checks.
4. Feedback rejection against the draw's entire color-target texture.
5. Copied uniform byte blocks, four slots per stage, up to 16 KiB per block.
6. Float4-array packing convenience and explicit state clearing.
7. Per-draw snapshots and an 8 MiB retained-uniform limit per plan.
8. Complete resource/count/lifetime revalidation before command acquisition.
9. Native sampler binding and uniform pushes without script callbacks.
10. Nearest/linear TexturedQuad CPU pixels, negative/lifetime tests and build gates.

## Setting state and recording draws

`gpu_plan_samplers(device,plan,stage,textures,samplers)` replaces the dense
sampler slots from zero for that stage. It copies the ID arrays and borrows the
resources. Empty arrays clear the stage's samplers. Rejected setters leave the
previous state intact. `gpu_plan_uniform` takes `array<float4>`; the lower-level
`gpu_plan_uniform_bytes` takes `array<uint8>`. Each replaces one uniform slot;
an empty array clears that slot. `gpu_plan_clear_bindings` clears current state
for both stages. Setters only modify a CPU plan, never issue GPU commands.

Every draw copies current binding state along with its other parameters.
Subsequent setters, source-array mutation or clearing state do not change queued
draws. Uniform bytes are snapshots. Texture *contents* are not snapshots: queued
draws borrow IDs and use their contents in GPU command order. Binding state owns
no GPU resource and does not extend its lifetime. Closing a texture/sampler scope
invalidates submission of every plan borrowing that resource. All operations
require a live scoped device and main thread; consumed/released plans reject.

The number of sampler pairs must exactly match shader metadata. Each declared
uniform slot must be nonempty and undeclared slots must be empty; storage resources
remain unsupported. Resources, counts and all sampled mips are rechecked for the
whole plan before acquisition. Reading the same texture that the draw renders
into is rejected, even if a caller intends different subresources.

Supported sampled textures are **Texture2D<float4>, RGBA8/BGRA8 UNORM**, with
SAMPLER usage and all mip levels initialized/valid. Comparison samplers are
rejected. The registry now retains the actual texture type: a single-layer
Texture2DArray is not accepted as Texture2D. Arrays, cubes, volumes, compressed,
integer, depth and other sampled formats remain outside this initial contract.
Only RGBA8, one-mip sampling has positive pixel coverage in this batch.

## Uniform ABI and limits

There are four uniform slots per stage. Nonempty byte blocks must be a multiple
of 16 bytes and at most 16,384 bytes. Float4 arrays accept up to 1,024 vectors
and copy their 16-byte elements unchanged. A plan retains at most 8 MiB of copied
uniform data across queued draws; current state is independently bounded by the
eight slots. Clearing current state does not erase prior snapshots or refund
their retained byte count. Limit failures append no operation.

The caller must provide the **trusted shader's std140 layout and required size**,
including padding, array/matrix stride, stage and slot. Float4 packing does not
infer a structure layout, transpose a matrix, or verify its shader meaning.
This is not shader reflection; declared shader resource counts and Texture2D
interfaces remain trusted. Bounds/alignment checks cannot prove that a supplied
block is large enough for arbitrary shader bytecode. The example's vertex slot 0
is two float4 transform rows (32 bytes), fragment slot 0 is a tint (16 bytes).
Positive GPU coverage uses one uniform and one sampler slot in each stage;
the remaining slots have metadata/bounds validation, not a multi-slot pixel claim.

Uniform pushes happen before each native render pass; pipeline/samplers are bound
inside it. Recording remains native-only. Existing cancellation, one-shot submit
and destination-invalidation rules apply. Sampled textures/samplers/uniforms are
read-only inputs; failed draw submission invalidates written targets, not these
inputs. No new try/recover in boost wrappers or per-call catch boundary is added.

## Tests and assets

`tests/gpu_bindings.das` checks all 4,096 pixels against an independent CPU
reference for a transformed quad, vertex texture tint, fragment texture and
uniform tint, using nearest and bilinear filtering on Vulkan and D3D12.
UNORM comparison allows a two-byte-value tolerance: interpolated 0.5 can round
to 127 or 128. The initial exact-128 assertion was corrected after observing 127
on both backends, without changing rendering or disabling validation.

Tests cover copied ID arrays and uniform bytes, source/current-state mutation
after append, missing/extra uniform slots, wrong ID kind/device/thread, array
texture and comparison-sampler rejection, feedback, invalid sampled mip and
stale sampler/texture rejection before acquisition, bounded uniform sizes,
controlled plan-budget rejection, consumed plans and panic cleanup.

Offline assets: `python tools/build_triangle_shaders.py --bindings`, with
`--check` for deterministic recompilation and spirv-val. Source/binary hashes
are included in `tests/test_triangle_assets.py`. Consumer builds need no shader
compiler. The vertex/fragment shaders use SDL's stage-specific register spaces
and preserve matching DXIL interstage signatures including SV_Position.

One newly adapted function is SDL_BindGPUVertexSamplers. Existing fragment
sampler and vertex/fragment uniform contracts are extended. GPU census is now
13 generated / 58 adapted / 21 pending; Windows total 66 / 67 / 1093. Generation
selection is unchanged (66 functions, 29 records, 153 fields, 24 enums).

## Verified gates (2026-09-20)

- Main regression: 162/162 passed.
- Full interpreter/CppGenBind/AOT parity: 379/379 passed.
- Standalone clangbind checks: 4/4 passed.
- Final generated snapshot/inventory/preflight checks: 5/5 passed after restoring
  the developer build configuration.
- Consumer build with generators, LLVM and Clang disabled: example 46 passed
  on Vulkan and D3D12. Its build graph contains no libclang/libLLVM or binding
  generation commands.
- Deterministic shader recompilation and SPIR-V validation passed. Main/parity
  detailed logs contain no Vulkan validation errors, D3D12 errors or skipped
  tests. A separate D3D12 OutputDebugString capture of the binding regression
  also exited successfully without ERROR/CORRUPTION diagnostics.

Next: storage bindings, broader attachment/depth/MSAA contracts and multiple
draws in one pass; compute remains a separate large slice. Reflection and shader
DSL remain later stages. Linux/Metal runtime behavior is not verified here.

## Direct-recording migration

Example 46 now uses sdl3_gpu_recording_boost with live SDL command/pass handles.
The snapshot contracts and tests above still apply to the optional plan layer.
The direct path has immediate uniform pushes/bind/draw calls and multiple draws
per pass; its separate lifetime/error contract is in gpu-recording.md.
