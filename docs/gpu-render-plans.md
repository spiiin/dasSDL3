> Historical implementation record. The framework API described here was removed.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.
> Do not use this as current binding guidance. See [API boundary](gpu-api-boundary.md)
> and [current GPU roadmap](gpu-roadmap.md). Old test counts describe earlier revisions.

# Native render operations in command plans

Example 44 and `sdl3_gpu_render_plan_boost` connect the independent graphics
pipeline registry to public offscreen rendering. This bounded P6 batch adds:

1. One complete native render pass per copied plan operation.
2. Pipeline/attachment format, sample count, depth and resource compatibility checks.
3. Explicit CLEAR/LOAD and fixed STORE, with cycling disabled.
4. Copied viewport with finite bounds and ordered 0..1 depth.
5. Copied scissor in top-left pixel coordinates, bounded before integer conversion.
6. Copied normalized blend constants.
7. Direct non-indexed drawing using the generated draw-command value record.
8. Ordering with existing texture copies, blits, mipmaps and markers.
9. Full revalidation, one-shot submission and error-path destination tracking.
10. CPU pixel/lifetime/failure tests and an LLVM-free example.

## Public contract

`gpu_plan_draw(device, plan, pipeline, target, sub, load, clear, viewport,
scissor, blend, draw)` copies all descriptors and borrows the two IDs.
`sub` is uint2(mip, layer); `scissor` is uint4(x, y, width, height).
`gpu_viewport(width,height)` supplies origin 0 and depth 0..1.
`gpu_direct_draw(vertices=3,instances=1)` supplies zero first indices.
The generated `SDL_GPUIndirectDrawCommand` is reused as a value descriptor;
this function issues **SDL_DrawGPUPrimitives**, not an indirect draw.

Supported pipelines have no vertex buffers or shader resources (samplers,
uniforms, storage buffers/textures). They use exactly one matching color target,
sample count 1, and no depth attachment. Current target factories provide RGBA8/
BGRA8 UNORM 2D/array textures. Every mip/layer must already be valid; CLEAR does
not repair invalid resources. Viewport/scissor must be nonempty and fit the
selected mip; viewport coordinates and extents may be fractional. Colors must
be finite in 0..1. Only CLEAR/LOAD are accepted; STORE is unconditional. CLEAR
affects the entire selected attachment, independent of viewport/scissor.

Draw counts must be nonzero, with at most 1,048,576 total vertex invocations.
First vertex and instance must be zero for portable shader ID semantics.
Shader bytecode and its declared interface remain trusted; there is no reflection
or proof that a shader's own vertex-ID array can accommodate a particular count.
The included triangle asset requires exactly three vertices. Instancing is
passed through but this batch's pixel oracle exercises one instance only.

Each operation begins/binds/sets state/draws/ends entirely in C++. Multiple
operations use separate passes, including LOAD to preserve earlier results.
No script callbacks, new catch boundary, raw pass pointer or native command
handle escapes. Plan scope exit discards unsubmitted work, also after panic.
Copied descriptor values may change immediately after append. Resource IDs
must remain live through submit; all operations are revalidated before acquire.
All calls require the main thread and a live scoped device.

Begin failure balances debug groups and cancels; no swapchain enters these
plans. Submission failure consumes the plan and marks every written target
subresource invalid, including draws, while untouched mip/layers remain valid.
Use full upload to recover. These rules extend the existing command-plan
contract; they do not promise rollback after submission.

## Evidence and remaining work

Tests compare over 3,000 pixels per image against CPU barycentrics after public
fenced readback: translated/reduced viewport, scissor, RGB constant-color blend,
nonblack whole-attachment clear, LOAD preservation and draw-to-copy ordering.
They exercise mip 1/layer 1, untouched neighboring layer, mutation after append,
late stale pipeline rejection before acquisition, wrong ID kind/device/thread,
invalid enums/ranges/nonfinite values/counts, missing resources, format/sample/
depth incompatibility, discarded panic scope and injected begin/submit failures.
Metadata incompatibility probes never submit deliberately mismatched pipelines.
Fault injection is controlled; no physical device-loss claim is made.

This adds three **partial adapted** SDL contracts: SetGPUViewport, SetGPUScissor,
SetGPUBlendConstants. GPU census becomes 13 generated / 57 adapted / 22 pending;
Windows total is 66 generated / 66 adapted / 1094 pending. Generation selection
remains 66 functions, 29 records, 153 fields, 24 enums / 230 values.

Next: independent vertex/index buffer bindings and range checks, followed by
sampler/texture and uniform bindings. MRT, depth/MSAA passes, swapchain targets,
live pass handles, indirect draws, compute and reflection remain open. This
render-plan slice does not close G2/G4/P6. Linux/Metal are not runtime-tested.

Verification on 2026-09-20:

- Main interpreter suite: **154/154**.
- Legacy/CppGenBind parity and strict AOT: **359/359**, no skips.
- Standalone generator/AOT/missing-AOT experiment: **4/4**.
- Developer configuration restored; generation/inventory/preflight freshness:
  **5/5**.
- LLVM/Clang/Python discovery and generators disabled: consumer built and
  example 44 passed on Vulkan and D3D12, including readback assertions.
  Consumer build.ninja has no LLVM or generator dependency.
- Complete main/parity logs have no VUID, validation error, D3D12 error or
  corruption. No upstream sources were modified and no commits were created.

Extension 45 adds vertex/index buffers and instance-rate slots; the original
no-vertex-buffer restriction above describes batch 44. See [vertex/index plans](gpu-vertex-plans.md).
Uniforms, samplers/storage resources and broader attachments remain pending.

Extension 46 adds copied vertex/fragment texture/sampler and uniform state;
see [shader bindings](gpu-shader-bindings.md). The earlier no-shader-resources
restriction describes the original batch, not the extended API. Storage remains pending.
