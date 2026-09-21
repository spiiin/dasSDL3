# Typed checked GPU handles

The checked GPU adapters use daScript **distinct** types backed by `uint64`.
They are nominal types, not aliases or enums. For example, the native module
registers the equivalent of:

```daslang
typedef distinct GpuBufferHandle = uint64
typedef distinct GpuTextureHandle = uint64
```

Use the types exported by `require sdl3`; do not redeclare them in script.
Native registration uses `DistinctTypeAnnotation`, `MAKE_DISTINCT_TYPE_FACTORY`
and matching C++ value/argument adapters. Each value occupies eight bytes and
has no destructor or allocation. The checked registry still stores numeric IDs.

| Type | Checked resource |
| --- | --- |
| `GpuBufferHandle` | Data/vertex buffer |
| `GpuIndexBufferHandle` | Index buffer |
| `GpuTextureHandle` | 2D, array, cube or color-target texture |
| `GpuVolumeHandle` | 3D volume |
| `GpuReadbackHandle` | Buffer, texture or volume readback ticket |
| `GpuShaderHandle` | Shader |
| `GpuSamplerHandle` | Sampler |
| `GpuPipelineHandle` | Graphics pipeline |
| `GpuCommandBufferHandle` | Command buffer |
| `GpuRenderPassHandle` | Render pass |

All 58 checked native adapter signatures and their boost helpers use these
types. Vertex-buffer binding takes `array<GpuBufferHandle>`; sampler binding
takes separate `array<GpuTextureHandle>` and `array<GpuSamplerHandle>` arrays.
The native implementation reads those arrays directly, without allocating an
intermediate numeric-ID array.

```daslang
return device |> with_gpu_buffer(bytes, SDL_GPU_BUFFERUSAGE_VERTEX) $(buffer : GpuBufferHandle) {
    return device |> with_gpu_readback(buffer, 0u, uint(length(bytes))) $(ticket : GpuReadbackHandle) {
        device |> gpu_wait_readback(ticket) |> sdl_try
        return sdl_ok()
    }
}
```

Keep explicit block parameter annotations for these generic Result scopes:
the pinned compiler cannot infer all of them from a trailing block. Ordinary
`let` values and `sdl_try` preserve the distinct type. Result and Option use
their existing standard-library implementations.

A default-initialized handle is zero. `*handle` explicitly extracts its numeric
representation; `GpuBufferHandle(value)` explicitly constructs a handle from a
number. These operations are useful for diagnostics and deliberate invalid-ID
tests, not for converting between live resources. Passing an integer, texture,
index buffer or native pointer to a data-buffer API is a compile error.

Distinct typing does not provide ownership or prevent a same-kind stale ID.
IDs are still validated for native kind, liveness and device at runtime. Copies
are aliases; `with_*` lends a resource until deferred cleanup. No new automatic
destructor, exception interception or panic conversion is added. Raw SDL APIs
retain their original pointer types and numeric parameters.

## Maintenance and checks

`tools/generate_gpu_handles.py` owns the explicit adapter/type mapping and the
three `src/generated/gpu_handle_*` snapshots. Run it to regenerate, or pass
`--check` to verify deterministic output. Consumers use the snapshots without
Python or LLVM. The SDL declaration generator remains unchanged.

`tests/gpu_handles.das` checks the full 64-bit native ABI, arrays, Result/Option,
`sdl_try` and deferred early return. `tests/test_gpu_handle_errors.py` checks
compile-time rejection with a positive control. Existing GPU tests retain
wrong-kind runtime checks by explicitly forging a requested nominal type;
their stale-ID, foreign-device, pixel and byte checks remain in place.
These tests are included in interpreter and AOT parity configurations.

Local Windows x64 validation (21 September 2026): all 45 Vulkan checks passed
after migrating the intentional wrong-kind tests; the 51-test Direct3D12/type/
contract selection passed. All 164 selected legacy/CppGenBind/AOT checks passed,
including metadata equality for ten distinct types and full-width ABI roundtrip.
Generation/inventory/boundary gates and the four standalone clangbind checks passed.
The consumer built with generators, LLVM and Python discovery disabled; all 17
migrated GPU examples and the compile-rejection suite passed with that runner.
