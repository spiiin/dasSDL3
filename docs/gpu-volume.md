# Checked 3D texture transfers

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.

P6/G3 batch 39: `sdl3_gpu_volume_boost`, `src/sdl3_gpu_volume.h`,
`examples/39_gpu_volume_transfers.das`. This extends the existing five texture
create/release/upload/copy/download contracts to 3D volumes. Function census
remains 13 generated / 54 adapted / 25 pending; parameters and ownership, rather
than new SDL function names, are the coverage change.

The nine related steps are volume creation/zero initialization, 3D mip extents,
checked regions, copied pitched uploads, volume copies, shared fence readback,
failure invalidation/recovery, scoped/device cleanup and a byte-reference example.

## Public contract

`with_gpu_volume(device, size:uint3, levels:uint, format:SDL_GPUTextureFormat)`
owns a checked ID. The shorter overload uses one RGBA8 UNORM mip. Format must be
an uncompressed color format supported by SDL for 3D SAMPLER usage. Sample count
is one. Depth, BC/ASTC, render/storage usage and shader sampling integration are
not part of this slice. The old 2D/array API still rejects 3D; IDs from the two
registries cannot be interchanged, including a 3D volume with depth one.

Each dimension is 1..2048. Mip count is 1..floor(log2(max(x,y,z)))+1; each axis
shrinks to max(1, base >> mip), including depth. The sum of aligned staging
footprints over all mips must fit 64 MiB. These are binding limits, not hardware
capability claims. Every mip starts zeroed; no automatic mip filtering occurs.

Upload takes a mip, origin and size in texels, plus a byte array, row pitch and
slice pitch in bytes. Nonempty regions must fit all three axes. Row pitch must
be at least width*texel_bytes; slice pitch must be at least row_pitch*height.
Required bytes are `(depth-1)*slice_pitch + (height-1)*row_pitch + row_bytes`:
padding after the final row of the final slice is optional. Array size is capped
at 64 MiB. Bounds/products use checked uint64 arithmetic before GPU allocation.
Odd pitches are allowed. Data is copied synchronously into private staging memory;
no script pointer escapes. Rows are 256-aligned, slices have exactly height rows,
offset is zero and staging padding is zeroed. This avoids the pinned D3D12
backend's extra pitch-realignment path.

Copy requires distinct live volumes on the same device, matching formats and
valid source/destination mips. Regions can have nonzero x/y/z origins and copy
between mip levels when extents fit. Other texels/mips are preserved. Same-volume
copies, format conversion, filtering and copy cycling are rejected/not exposed.

Upload cycling is allowed only for a full replacement of a single-mip volume.
A failed submit invalidates only its destination mip; read/copy and partial
uploads reject that mip until a full upload succeeds. Failure before submit
leaves existing validity unchanged. The regression injects a consuming failed
submit by cancelling the recorded command; it is not a device-loss test.

`with_gpu_volume_readback` returns the existing shared readback ticket. Poll,
wait and read use `sdl3_gpu_transfer_boost`. Result size is exactly
width*height*depth*texel_bytes, tightly packed with x bytes, then y rows, then z
slices. The shared reader strips staging padding. Source mutation/release after
request does not change the queued snapshot. Releasing an incomplete ticket
retires its fence until completion, preserving the Vulkan fence-pool workaround.

Operations require the main thread and a live scoped device. IDs share the global
monotonic namespace, but lookup checks resource kind and owner. Recording stays
native-only. Volume scopes use one native owner boundary for cleanup on return
or panic; ordinary calls add no try/recover. Device teardown waits for idle then
releases only that device's volumes and outstanding tickets.

## Verification scope

`tests/gpu_volume.das` uses CPU byte references for zero mips, padded input,
partial two-slice updates, nonzero source/destination z, untouched neighbors,
mip copies, 1x1x1 mips and queued cycling snapshots. It exercises 1/2/4/8/16-byte
formats when supported, overflow/short arrays/bad pitches, bounds, same-volume
copy, wrong-kind/stale/foreign IDs, failure recovery, panic/early return, rapid
ticket retirement, two live devices and pending-work teardown. A separate
registry prevents volume IDs from being accepted by 2D transfer helpers.
Example 39 uses only public helpers and needs no unsafe block or test exports.

ASTC transfers, arbitrary mapping, command-plan integration and general shader/
pipeline bindings remain open. Existing 2D/array/BC/cube/image behavior is covered
by the combined regression suite; Windows results do not establish Metal/Linux
support.

Verified 2026-09-20 with the pinned Windows x64 toolchain: main suite 133/133,
baseline/CppGenBind/strict AOT suite 306/306, standalone Clang preflight 4/4.
All five selected volume formats ran on Vulkan and D3D12; no optional-format
fallbacks, CTest skips or GPU validation errors occurred.
The LLVM/Python-disabled consumer built from saved snapshots and passed example
39 on both backends. Its build graph has no libclang, LLVM or binding-generator
dependency. Developer generator configuration was restored afterward.
