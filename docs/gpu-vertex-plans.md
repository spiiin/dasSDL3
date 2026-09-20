> Historical implementation record. The framework API described here was removed.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.
> Do not use this as current binding guidance. See [API boundary](gpu-api-boundary.md)
> and [current GPU roadmap](gpu-roadmap.md). Old test counts describe earlier revisions.

# Vertex/index resources in native render plans

Example 45 extends the offscreen render-plan contract with ten related steps:

1. Persistent usage metadata for existing mutable data buffers.
2. Copied float32 vertex-buffer convenience factory; arbitrary bytes still work.
3. Immutable UINT16/UINT32 index buffers with retained CPU indices.
4. Separate ID registry, native ownership scope and device cleanup for indices.
5. Copied vertex-buffer IDs and byte offsets in dense pipeline-slot order.
6. Per-vertex and per-instance stride/bounds checks before command acquisition.
7. Direct and indexed draws, first-index range and signed base-vertex validation.
8. Native vertex/index binding with no script callback during recording.
9. Draw/copy ordering, invalid-resource recovery and independent CPU pixel tests.
10. Reproducible shader assets, example, interpreter/AOT/consumer gates.

## API and ownership

`with_gpu_vertex_buffer(device, array<float>, block)` copies finite float32 data
into an ordinary VERTEX data buffer. It is a packing convenience, not a layout
inference API. Data is nonempty, at most 64 MiB. Existing `with_gpu_buffer(bytes,
SDL_GPU_BUFFERUSAGE_VERTEX)` accepts other layouts. Those buffers remain mutable
through the transfer API; plans borrow their current contents, not snapshots.

`with_gpu_index_buffer(device, array<uint>, SDL_GPUIndexElementSize, block)`
creates an independent immutable index resource. The array has 1..1,048,576
elements. UINT16 accepts 0..65534, UINT32 accepts 0..4294967294; all-ones restart
sentinels are rejected even for list topologies. Odd UINT16 counts are padded
privately to four bytes, but padding is never available as a logical index.
Both GPU bytes and validation data are copied. Input mutation/clear is legal
immediately after creation. Only the index scope/release function owns this ID;
ordinary transfer/update/copy/name/readback APIs reject it as a different kind.

Retaining immutable CPU indices avoids a GPU readback or wait for bounds checks.
Do not add generic mutation without maintaining a provably synchronized CPU
index representation, including queued GPU copies/compute writes. Index IDs use
the shared monotonic namespace, a separate registry, main-thread/live-device
checks, one protected native owner block and device-specific cleanup.

`gpu_plan_draw_vertices` extends `gpu_plan_draw` with `array<uint64>` buffer IDs
and `array<uint>` byte offsets. Arrays must have exactly one entry per dense
pipeline slot, at most 16. Their order is slot order regardless of the original
pipeline-description array order. Each buffer needs VERTEX usage and valid
contents. Offsets are four-byte aligned. Every required complete stride must fit
after the offset: vertex count for vertex-rate slots, instance count for
instance-rate slots. This conservatively requires the full final stride,
including padding. Empty/missing/extra bindings reject; they do not imply a
vertex-ID fallback for a pipeline that declares attributes.

`gpu_plan_draw_indexed` additionally takes a checked index ID and a generated
`SDL_GPUIndexedIndirectDrawCommand` **value descriptor**. It issues a direct
SDL_DrawGPUIndexedPrimitives call; it is not GPU indirect execution.
`gpu_indexed_draw(count, instances=1, first_index=0, base_vertex=0)` supplies it.
Every selected CPU index plus signed base vertex is checked with int64 arithmetic,
then the maximum resulting vertex bounds every vertex-rate slot. At least one
vertex-rate slot is required for indexed draws. Instance slots use instance
count, never index values. First instance is zero; direct first vertex is zero.
Counts are nonzero and their product is at most 1,048,576. An empty indexed draw
rejects and never becomes sequential drawing.

All descriptors and binding arrays are copied at append. All IDs, validity and
ranges are checked again for the entire plan before acquiring a command buffer.
Closing a vertex/index scope invalidates submission. Transfer copies can precede
draws in one command plan; separate copy/render passes establish dependencies.
Index resources cannot be copy destinations. Failed transfer submission blocks
vertex use until a successful full upload. Draw submission failure invalidates
its target but does not invalidate read-only vertex/index sources.

No new script try/recover or per-call native catch is introduced. Scope cleanup
uses the existing single protected owner boundary. Other render-plan limits stay:
one sample-1 color target, no depth, no uniforms/samplers/storage bindings.
Vertex data and shader interface declarations are trusted; there is no reflection
or semantic proof that supplied bytes represent the declared attributes.

## Assets and test evidence

`vertex_color` has position float2 at location 0 and color float3 at location 1,
without shader resources. Offline generation:

```
python tools/build_triangle_shaders.py --vertex-color
python tools/build_triangle_shaders.py --vertex-color --check
```

The normal consumer needs neither DXC nor spirv-val. Committed source/binary
hashes are covered by `tests/test_triangle_assets.py`. DXIL fragment input keeps
SV_Position before TEXCOORD0, matching the vertex output register signature.
An initial omitted position input failed D3D12 pipeline creation; debug output
identified CREATEGRAPHICSPIPELINESTATE_SHADER_LINKAGE_REGISTERINDEX. The complete
signature fixes it; validation was not disabled and upstream code was not patched.

CPU pixel tests on Vulkan and D3D12 cover an interleaved stride-20 buffer,
two separate vertex slots, reordered pipeline descriptions, instance-rate colors
with two instances, UINT16/UINT32, selected index ranges, signed base vertex,
byte offsets, six-index reuse of three vertices, copied inputs/bindings and copy-to-draw ordering. They also check
wrong usage/kind/device/thread, stale indices/vertices before acquisition,
out-of-range indices and instances, invalid/oversized input, transfer-failure
recovery, panic cleanup and an abandoned index resource on a second device.

These extend existing partial BindGPUVertexBuffers, BindGPUIndexBuffer and
DrawGPUIndexedPrimitives contracts. Census is unchanged: GPU 13 generated /
57 adapted / 22 pending; Windows 66 generated / 66 adapted / 1094 pending.
Next: independent texture/sampler bindings and uniforms, then broader attachment
and compute contracts. Mutable index buffers, primitive restart, nonzero first
instance, indirect execution, reflection and Linux/Metal verification remain open.

Verification on 2026-09-20:

- Main interpreter suite **158/158**; full legacy/CppGenBind/strict AOT **369/369**.
- After adding six-index vertex reuse, the strengthened slice passed again:
  main **4/4**, all parity/AOT variants **10/10**. Production code was unchanged.
- Standalone generator/AOT/missing-AOT checks **4/4**; offline shader rebuild
  `--check` and SPIR-V validation passed.
- Developer configuration restored; final generation/inventory/preflight **5/5**.
- Consumer built with LLVM/Clang/Python discovery and generators disabled;
  example 45 passed on Vulkan and D3D12. No LLVM/generator build dependency.
- No skipped tests or GPU validation errors in complete/final test logs. The
  strengthened D3D12 test also ran under debug-output capture: exit 0, no D3D12
  ERROR/CORRUPTION. The earlier shader-linkage failure is documented above.

Extension 46 connects these vertex/index draws to independent Texture2D samplers
and uniform blocks; see [shader bindings](gpu-shader-bindings.md).
