# `sdl_scope` and `sdl_use`: linear scoped acquisition

Import `dassdl3/sdl3_scope`; it also re-exports `sdl3_try`. Import the boost
modules providing the scopes you use as usual.

```daslang
return sdl_scope() {
    let vb : GpuBufferHandle = device |> with_gpu_vertex_buffer(vertices) |> sdl_use
    let ib : GpuIndexBufferHandle = device |> with_gpu_index_buffer(indices,SDL_GPUIndexElementSize.INDEXELEMENTSIZE_16BIT) |> sdl_use
    let texture : GpuTextureHandle = device |> with_gpu_rgba_texture(1u,1u) |> sdl_use
    return upload_textures(device,pipeline,vb,ib,texture,linear)
}
```

Each `sdl_use` moves the remaining statements into the missing final callback
of its call. The example expands to nested `with_gpu_vertex_buffer`,
`with_gpu_index_buffer` and `with_gpu_rgba_texture` calls with ordinary returns.
Acquisition arguments execute once, in source order. Existing wrappers decide
whether to invoke the body and how to release resources, including their rules
for body versus cleanup errors. Failure of the second acquisition skips the
third and releases the first through its wrapper. No resource registry, panic,
catch, cleanup stack or new ownership object is added.

The macro expands before type inference so the incomplete scoped calls do not
need to type-check on their own. The outer block is immediately invoked; returns
are local to this expression. Use `return sdl_scope() { ... }` to return its
result from the enclosing function, or consume its Result using `sdl_try`.
Synthesized returns move Results so array payloads work as well as scalar ones.

## Supported syntax and boundaries

- One explicitly typed binding: `let resource : ResourceType = with_resource(...) |> sdl_use`.
  The type becomes the callback parameter type, not a cast. Match the original
  callback's `var`/reference qualifiers when mutable access is required.
- No binding for a callback with no parameters: `with_sdl() |> sdl_use` or
  `with_text_input(window) |> sdl_use`.
- Parenthesized `sdl_use(with_resource(...))` is equivalent; examples prefer pipes.
- Markers must be direct statements or the entire initializer of a single
  `let`/`var` in the literal `sdl_scope` block. Assignments, nested expressions,
  implicit binding types and markers inside `if`/loop/defer blocks are rejected.
  Use an explicit nested `sdl_scope` inside a branch or loop for its own lifetime.
- The scope call must omit its final callback. Multi-parameter callbacks, such
  as `with_window_renderer` or `with_native_gpu_swapchain`, retain explicit
  trailing blocks. No tuple/resource aggregate is invented for them.
- Keep explicit inner scopes where cleanup must happen before subsequent work.
  Flattening is appropriate only when resources should live until the same end.
- `sdl_try` performs a normal early return from the generated callback, so the
  existing wrapper still cleans up. Application panic has the pinned runtime's
  existing defer limitation; these macros do not change it.
- Resource values remain borrowed. Do not return/store them beyond their owner,
  manually release them, or consume commands contrary to the `with_*` contract.

Examples: [46 GPU bindings](../examples/46_gpu_texture_uniform_bindings.das) and
[Result macros](../examples/results/02_sdl_try.das). The first Result example
remains an explicit comparison without these macros. Other numbered examples
use the macros wherever scopes have zero or one callback parameter; raw/manual
resource examples keep their explicit deferred ownership.

Tests: [runtime contracts](../tests/sdl3_scope.das) and
[compile rejection cases](../tests/test_sdl3_scope_compile_errors.py).
They cover acquisition/cleanup order, partial failure, body errors, intermediate
statements, typed/inferred Result payloads, moving arrays, mutable callback
references, nested scopes and actual SDL window/renderer/texture scopes.

Local validation (2026-09-21, Windows x64/MSVC): 80 selected main checks passed.
The 206-check legacy/CppGenBind/AOT run passed after regenerating the expanded
runtime test's stale AOT artifact; 13 affected checks passed on the rebuilt
runner. Vulkan and D3D12 both exercised example 46. The existing no-LLVM,
BUILD_TESTING=OFF consumer passed the current scope test, eight representative
examples and all eleven compile-rejection cases. Production clangbind probe,
documentation links and whitespace checks passed.
