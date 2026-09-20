> Historical implementation record. The framework API described here was removed.

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.
> Do not use this as current binding guidance. See [API boundary](gpu-api-boundary.md)
> and [current GPU roadmap](gpu-roadmap.md). Old test counts describe earlier revisions.

# GPU command plans: next P6 batch (9 steps)

`sdl3_gpu_commands_boost` extends G0/G3/G4/G6 with a value-only plan and one
native command-buffer submission. This is not the general command/pass API.

1. Scoped plan IDs, shared monotonic namespace, device-specific cleanup.
2. Buffer range copies, including dependent A → B → C copies.
3. Texture region copies, including existing BC/mip/layer contracts.
4. Mipmap operations mixed with copies in the same submission.
5. Nearest/linear blits mixed with copies and mipmaps.
6. Copied debug label strings.
7. Balanced nested debug groups and explicit backend support query.
8. Full revalidation before command acquisition; no partial execution on a
   validation failure, including an invalid last operation.
9. One-shot submission, cancellation on recording failure, destination
   invalidation on submit failure, protected scope cleanup and regression gates.

## Ownership and state

`device |> with_gpu_command_plan() $(plan) { ... }` creates a CPU-only plan.
Operations use device-first `gpu_plan_copy_buffer`, `gpu_plan_copy_texture`,
`gpu_plan_mipmaps`, `gpu_plan_blit`, `gpu_plan_label`, `gpu_plan_push_group`,
`gpu_plan_pop_group`. `gpu_submit_plan` explicitly submits it. Leaving the scope
without submission discards the plan, including on return or panic; it never
automatically submits. Invocation and release now share one native owner helper; script try/recover
is removed from every boost scope (see [native-scopes.md](native-scopes.md)).

Plans copy parameters and strings and borrow resource IDs, not their contents.
Changing buffer/texture contents before submission changes what the plan reads.
Closing a resource scope invalidates future submission. Resource kind, device,
validity and bounds are checked at append and rechecked for the complete plan
before any command acquisition. No resource ownership is transferred.

Validation failure leaves the plan open and performs no GPU work. After
validation, a submission attempt consumes the plan even when acquisition,
recording or submit fails. Further additions/submissions reject it; release is
still required and the scope does it. Released and foreign IDs reject. Device
destruction removes abandoned plans without touching another device's plans.

All operations require the main thread and a live scoped device. No script
callback runs while recording. Plans contain at most 4096 operations (including
markers), groups nest at most 64 levels, each label/group string is at most
4096 bytes. Empty text is allowed. Rejected appends do not alter the plan.
Submit requires all groups to be closed. Pop on an empty stack rejects.

## Native recording and errors

All successful operations use one acquired command buffer and one submit.
Each buffer/texture copy uses a separate native copy pass to preserve barriers
between dependent operations. Mip generation, blits and debug commands are
outside those passes. Same-resource copies/blits remain rejected, cycling is
off, and texture copies require equal formats. Mips/blits retain the RGBA8/
BGRA8 UNORM limitations of [gpu-image.md](gpu-image.md). Copy regions retain
the checked block/edge handling of [gpu-texture-types.md](gpu-texture-types.md).

Acquisition or begin-pass failure performs no submission; an acquired command
is cancelled after balancing open debug groups. No swapchain texture can enter
this API, so cancellation is legal. The original SDL error is preserved.
Submit consumes the native command even on failure. On submit failure all
written buffers and destination texture subresources are conservatively marked
invalid; mip generation invalidates the lower levels of every layer. Recover
through the existing full-upload/mipmap helpers. A plan cannot repair already
invalid resources. Validation atomicity does not promise rollback after submit.

## Pinned SDL D3D12 debug group defect

On this machine, SDL **3.2.18** `D3D12_PushDebugGroup` calls the diagnostic
`ID3D12GraphicsCommandList_BeginEvent` with metadata 0. The enabled D3D12 debug
layer reports `CORRUPTED_PARAMETER2`, asks callers to use PIXBeginEvent and
raises exception **0x87a** (process exit 2170). The same buffer plan without
groups succeeds; individual `SDL_InsertGPUDebugLabel` commands succeed.
This was isolated with per-process Windows debug-event/output capture and
checked against the pinned `src/gpu/d3d12/SDL_gpu_d3d12.c` implementation.

`gpu_plan_debug_groups_supported(device)` therefore returns false for this
pinned D3D12 backend; pushing a group fails before SDL is called. It returns
true for Vulkan. No validation setting is disabled, no group is silently
dropped, and no upstream SDL/daScript source is patched. Labels remain usable
on both backends. Revisit this guard when upgrading SDL and verify it with the
D3D12 debug layer enabled. Debugger display/capture integration is not verified.
Metal/Linux runtime behavior is untested.

## Examples, tests and remaining work

Example `36_gpu_command_plan.das` submits two dependent copies with labels,
uses groups when supported, then checks readback bytes against the CPU source.
`tests/gpu_commands.das` additionally covers mixed copy/mip/blit ordering,
untouched layers, a 1×1 BC mip, borrowed contents, stale/wrong-kind/foreign IDs,
late-invalid-item rejection before acquisition, scope panic, abandoned device
cleanup, command/text/depth limits, double submit, invalid ranges and filters.
Native test-only fault injection exercises acquisition, first/second pass and
submit failure, cancellation counts and resource recovery. These are controlled
failure tests, not claims that a physical GPU submission failure occurred.

General render/compute passes, borrowed swapchain handles, shader/pipeline
descriptors and native live command handles remain pending. CPU plans do not
complete those contracts. This batch adds **3** partially adapted SDL functions
(the debug commands); the other steps extend existing partial contracts.

Final verification (including the native scope simplification):

- Main project CTest: **122/122**.
- Legacy/CppGenBind parity and strict AOT: **277/277**.
- Standalone generator/AOT/missing-AOT experiment: **4/4**.
- LLVM/Clang/Python discovery and generators disabled: consumer built; examples
  02, 04, 06, 08 passed (audio uses process-local dummy driver), and example 36
  passed on Vulkan and D3D12. No generator/LLVM dependency in consumer build.ninja.
- Main/parity logs contain no VUID, validation errors or D3D12 error/corruption;
  no skipped or not-run tests. D3D12 group rejection is tested explicitly.
- Developer generation/preflight is restored and rechecked after the consumer.

Extension 44 adds native complete render operations; see [gpu-render-plans.md](gpu-render-plans.md).
The earlier pending-pass statement describes the original transfer-only batch.
General live pass handles remain pending; plans now support bounded offscreen draws.
