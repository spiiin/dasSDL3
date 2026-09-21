# SDL results and deferred ownership

Raw `SDL_*` keeps SDL signatures, sentinels and ownership. Boost operations use
standard `daslib/result` and `daslib/option`, publicly re-exported by `sdl3_boost`.
There are no legacy bool scopes, void-block scopes or `_result`/`_status_result`
entry points. Pure constructors, predicates and void destroy/log functions remain
ordinary values. This supersedes the previous additive migration.

- Fallible commands return `Result<SdlUnit,SdlError>`; factories return
  `Result<resource,SdlError>`. `SdlError.operation/message` are owned script strings.
- Queries have value-returning overloads, for example `texture_size(texture)` and
  `window_size(window)`. Explicit mutable ref/out overloads return Result too.
  In-place transfer/audio byte buffers retain their capacity/mutation contracts.
- Hint and typed event readers use Option. Color key and app metadata use
  `Result<Option<T>,SdlError>` to distinguish absence from invalid input.
- GPU checked support queries and poll-readback use `Result<bool,SdlError>`:
  Ok(false) means unsupported/pending; Err means failure.
- `native_gpu_swapchain(command,window,wait)` returns Result<Option<texture+size>>.
  Neither waiting nor nonblocking acquisition erases successful null texture.
- `with_*` takes a Result-returning block. Acquisition failure skips the block.
  A body Result survives deferred cleanup. Fallible cleanup changes Ok into Err;
  if both fail, the body error is primary (secondary cleanup error is discarded).
  `with_native_gpu_swapchain` returns Result<Option<T>>; None skips the body.
  An acquired texture must be submitted even when the body returns Err, because
  SDL forbids cancelling that command. None is cancelled without submission.
- Errors are captured immediately after established failure, before cleanup.
  A stale SDL error on successful calls, pending work or absence is ignored.
- `push_event` deliberately remains an acceptance bool: SDL conflates event
  filtering and queue failure. An arbitrary stale SDL error is not proof of
  queue failure. Use raw SDL event/filter facilities when that distinction matters.

```daslang
let result = with_sdl() {
    return with_window("SDL",640,480,SDL_WINDOW_RESIZABLE) $(window : SDL_Window?) {
        return window |> with_renderer() $(renderer : SDL_Renderer?) {
            var cleared = renderer |> clear()
            if (is_err(cleared)) { return <- cleared }
            return renderer |> present()
        }
    }
}
result |> if_err() $(error : SdlError) {
    print("{error.operation}: {error.message}\n")
}
```

Use one outer SDL lifetime; owned handles are borrowed inside scope blocks and
must not escape or be manually released. Result itself does not own pointers.
Enter nested defer scopes only after acquisition. There is no script try/recover
or native protected-call bridge. Pinned daScript panic/runtime faults still skip
finally; Result does not promise cleanup after arbitrary application panic.
`unwrap` is an explicit application decision; library uses it only under a tag check.

`poll_event(var event)` returns Option<SdlUnit> as a presence marker while
writing the borrowed SDL_Event. Decode pointer-bearing text before polling again.
The typed text readers return copied script strings. The opt-in
[sdl3_events module](event-variants.md) provides `poll_event() : Option<SdlEvent>`
with owned text for the documented input/window variants. Other payloads remain
unknown (type/timestamp only), pending further P3 coverage.

For nested generic blocks, explicit argument types stabilize inference. Mutable
native block arguments must retain `var`. Check a scope after assigning its result,
or use `with_*() { ... } |> is_ok`; wrapping a no-argument trailing block inside
`is_ok(...)` can confuse this pinned parser. Arrays and mutable pointer containers
use move_ok/move_some/move_unwrap, not implicit cloning.

See [migration record](result-option-plan.md), [scope/data boundary](gpu-api-boundary.md)
and [example](../examples/results/01_results.das).
