# `sdl_try`: early return for SDL Results

Import the opt-in compile-time module:

```daslang
require dassdl3/sdl3_try

def draw(renderer : SDL_Renderer?; texture : SDL_Texture?) {
    let size = texture_size(texture) |> sdl_try
    print("{size.x} x {size.y}\n")
    renderer |> clear() |> sdl_try
    renderer |> draw_texture(texture) |> sdl_try
    renderer |> present() |> sdl_try
    return sdl_ok()
}
```

The function also needs the usual boost import for these SDL operations.
See [the complete runnable example](../examples/results/02_sdl_try.das), based on
[01_results](../examples/results/01_results.das).
The numbered examples also use the macro for linear Result operations. The first
Result example deliberately remains the explicit-check/`and_then` comparison.

## Contract

- Input is the standard `$Result<T; SdlError>`. The expression runs exactly once.
- Ok produces `T`; a standalone statement discards it. Ok(false) remains false,
  and Ok(None) produces None. This macro does not unwrap Option or interpret SDL
  sentinel values.
- Err returns the existing owned SdlError from the nearest function or closure
  block, with that scope's success type. Thus a texture-size Result<float2> can
  propagate into a function returning Result<SdlUnit>.
- The enclosing scope must return `$Result<U; SdlError>`. Inference from an
  ordinary success return works; `return sdl_ok()` remains necessary for void-like
  work. An explicit return type can also be used. No implicit final success is added.
- Expansion uses a local temporary, an error guard and an ordinary return. There
  is no runtime macro call, panic, try/recover or protected callback invocation.
  Normal deferred cleanup runs. A return inside a `with_*` block leaves that block;
  the scope helper cleans up and applies its existing primary-error policy.
- Copyable Results are copied, including scalar/string/handle values. Move-only
  Results are consumed. For arrays use `let items <- result |> sdl_try`, with a
  mutable result or a temporary; it does not clone the array. The compiler's normal
  const/pointer rules still apply.
- A pointer inside Result still has its original ownership contract. `sdl_try`
  neither creates a resource scope nor schedules its destruction.

## Supported placements

Use a standalone statement, the entire initializer of a single `let`/`var`, or
the entire right-hand side of an assignment to a variable (`=` or `<-`).
For example, `pipeline = device |> create_gpu_graphics_pipeline(...) |> sdl_try`.
On Err the target keeps its previous value and deferred cleanup observes it;
on Ok the assignment runs once. Move assignment consumes move-only payloads.
These forms work inside ordinary branches and loop bodies. Do not nest the macro
inside arguments, arithmetic, conditions, return expressions, or
multi-variable declarations. Split such expressions into local declarations first.
Indexed/field assignment targets and compound assignments are unsupported; this
avoids moving target evaluation across an early return.
It is forbidden in `defer`/finally and cannot be taken as a function pointer.
Unsupported calls fail compilation, rather than falling back to an unchecked unwrap.

This restriction deliberately avoids hoisting computations across short-circuit
operators, conditional branches or loop conditions. A named Result-returning helper
is the preferred way to keep acquisition callbacks short; no compound resource APIs
are needed.

## Implementation and verification

[sdl3_try.das](../dassdl3/sdl3_try.das) uses a typed inference signature and an
`infer_macro` AST pass. It rewrites completed block statement lists after type
inference, when the nearest closure's Result type is known. It does not insert into
a vector while the compiler's call visitor is traversing it. A second visitor
rejects unexpanded uses with sticky compile errors before optimization.

[Runtime contracts](../tests/sdl3_try.das) cover different success types, scalars,
strings, pointers, arrays, nested Option, exactly-once evaluation, branches/loops,
nearest-block propagation and cleanup with an overwritten SDL error string.
They also cover copy/move assignment, once-only RHS evaluation and an unchanged
target visible to defer after assignment failure.
[Negative tests](../tests/test_sdl3_try_compile_errors.py) check unsupported
placements, caller types, Option and non-SdlError inputs. CTest runs the runtime
contracts and example in the main interpreter, both parity interpreters and strict
AOT. Existing raw SDL and boost function signatures are unchanged.
