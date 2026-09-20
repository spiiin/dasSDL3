# GPU data buffers and asynchronous readback

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.

Public G3 slice after example 22, pinned SDL 3.2.18. Module:
`dassdl3/sdl3_gpu_transfer_boost`; native adapter: `src/sdl3_gpu_transfer.h`.
Example 23 needs a GPU device but no window or shaders. This does not complete P6.

## Contract

- `with_gpu_buffer(bytes, usage)` copies a fully initialized array into an owned
  fixed-capacity GPU buffer. Six generated SDL buffer usage flags are available;
  zero, unknown bits and VERTEX+INDEX are rejected. Storage layout is the caller's
  responsibility; byte transfer does not establish shader std140 compatibility.
- Sizes and offsets are bytes, nonempty, multiples of four; at most 64 MiB per
  buffer/request. Bounds are checked without overflowing offset+size. Array size
  is checked before narrowing from the daScript array's 64-bit size.
- `gpu_update_buffer` copies source bytes synchronously to private staging;
  submission completes asynchronously. Partial non-cycling updates preserve
  other bytes. Cycling is explicit and allowed only for a full replacement.
  Failed submission invalidates the buffer's content contract until a successful
  full update; a failure before submission leaves the old state intact.
- `gpu_copy_buffer` copies a checked source range into a checked destination
  range without cycling. Source and destination must be distinct, live buffers
  on the same scoped device. Same-buffer copies are deliberately rejected.
- `with_gpu_readback` submits a native copy and returns a ticket owning its
  download transfer buffer and fence. Later updates do not change that snapshot.
  The source buffer may be released after the request: SDL defers native release
  while submitted commands still reference it.
- `gpu_poll_readback` returns -1 for error, 0 for pending and 1 for ready.
  `gpu_wait_readback` waits for that fence, never the entire device.
  `gpu_readback_bytes` requires a ready ticket and an output array of exactly the
  requested size; it copies bytes into script-owned storage. Repeated reads are
  allowed. Invalid size/state does not change the output array.
- No mapped pointer, transfer buffer, command/pass or fence pointer reaches
  script. The block runs after submission, not during native recording.
- Closing a ticket invalidates its ID immediately and discards the result.
  Pending tickets are retired internally; the fence and transfer buffer are
  released only after the fence signals, on a later transfer operation or device
  teardown. Scope exit does not block or cancel submitted GPU work. This avoids
  premature fence-pool reuse observed in pinned SDL Vulkan (VUID 01123).
- Main thread and a live scoped device are mandatory. Buffer and ticket IDs
  share the existing monotonic GPU ID namespace and reject stale, wrong-kind
  and foreign-device use. Device teardown clears only that device's entries.
  Raw destruction of a scoped device remains unsupported, as in the base API.
- Scopes use direct script invocation and defer; SDL failures return values. Do not manually release a resource
  whose enclosing scope still owns it.

## Coverage and remaining work

Six formerly pending SDL functions gain limited public adapters:
CopyGPUBufferToBuffer, DownloadFromGPUBuffer,
SubmitGPUCommandBufferAndAcquireFence, QueryGPUFence, WaitForGPUFences,
ReleaseGPUFence. Create/update/map/release operations already used by meshes now
also have the public data-buffer contract above. No claim of general raw fence
arrays or public command-buffer recording is made.

Texture upload/download/copy regions, row pitches, compressed formats, explicit
transfer-buffer ownership/mapping and arbitrary pass recording remain separate
G3 work. The fixed mesh resources are not interchangeable with data-buffer IDs.
Graphics/compute binding of these buffers is still to be added; this slice
establishes transfer and lifetime contracts first.

`tests/gpu_transfer.das` covers exact byte comparison, partial updates/copies,
queued snapshots before cycling, repeated reads, release of the download source,
invalid ranges/usage/output sizes, stale/cross-kind/foreign-device IDs, normal
exit/early return/SDL error, and device-specific cleanup with pending work. Real
backend runs must distinguish a skipped device from a passing test. Hardware
device-loss and allocation-failure injection are not covered by those tests.

The rapid-discard regression submits 128 consecutive snapshots and closes their
scopes immediately. Transfer CTests fail on Vulkan VUID/Validation Error or
D3D12 ERROR output, even when byte assertions and the process exit code pass.

## Verification (2026-09-19)

- Final project CTest filter: 82/82 passed, including Vulkan/D3D12 transfer
  contracts and example 23. No validation errors in the final GPU test logs.
- After the fence-retirement fix: 13/13 focused parity/strict-AOT tests, including
  both GPU backends, both interpreter binding backends, metadata parity and
  missing-AOT rejection. The earlier broad 177-test run preceded this fix.
- Standalone dasClangBind interpreter/AOT/negative experiment: 4/4.
- BUILD_TESTING=OFF, generators/LLVM/Clang disabled source build: example 23
  succeeds on Vulkan and D3D12; build.ninja has no libclang/libLLVM/generator.
- Developer generator restored after the consumer build: 5/5 freshness,
  inventory/contracts and Clang preflight checks. 60 generated functions,
  53 constants; GPU inventory is 7 generated / 40 adapted / 45 pending.

The initial unfiltered CTest command also selected unbuilt upstream daScript
executables; those are not project binding failures. The final project filter
above excludes them. A stale inventory fingerprint caused by preserving the
bindings policy line endings was regenerated and passed the final freshness
checks. Hardware device-loss and injected allocation/submission failures remain
unverified. This slice is not a claim of complete G3 or P6.

RGBA8 2D/array texture regions and mip/layer readback are now implemented in
`gpu-texture-transfer.md`; generic/compressed formats and mapped views remain
pending. Both buffer and texture tickets share the same fence retirement path.
