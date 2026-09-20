# SDL results and deferred ownership

SDL failures are ordinary return values, not daScript panic. This supersedes
the former native protected-scope design described in older documents.

- Operations return bool, null/zero handles, or the native error sentinel.
  Read SDL_GetError immediately after a reported failure; a stale nonempty
  SDL error string does not prove that a successful operation failed.
- Descriptor and size queries return bool with output arguments, for example
  `gpu_shader_descriptor(device,shader,info)` and `texture_size(texture,size)`.
- `with_*` returns false on acquisition/setup failure and does not invoke its
  block. True means the resource was acquired and the block returned, not that
  every operation inside succeeded. The block remains void; check operation
  results explicitly or use direct acquisition plus defer when returning a
  result from a larger operation is clearer.
- Predicate conveniences such as gpu_supports_format return false for both
  unsupported and invalid input; the corresponding native Checked query retains
  its -1/0/1 distinction. `gpu_poll_readback` (formerly gpu_readback_ready) and
  SDL_PollGPUReadback retain -1/0/1, distinguishing errors from pending work.
- Cleanup uses `require daslib/defer` and `defer() { release(...) }`, with direct
  script block calls. No SDL_Scope*, SDL_Invoke*, runWithCatch or rethrow bridge
  remains in the binding. No exception message copying occurs on the normal path.

The pinned defer macro moves cleanup into the enclosing finally section. Enter
a nested scope only after successful acquisition, or guard cleanup explicitly.
Normal return and early return execute cleanup in reverse ownership order.

```daslang
def draw_once() : bool {
    let window = create_window("SDL",640,480)
    if (window == null) { return false }
    {
        defer() { destroy_window(window) }
        let renderer = create_renderer(window)
        if (renderer == null) { return false }
        {
            defer() { destroy_renderer(renderer) }
            if (!(renderer |> clear())) { return false }
            return renderer |> present()
        }
    }
}
```

Use one outer SDL initialization lifetime. Never manually release a resource
borrowed from with_*. Cleanup failures are not converted to panic; callers that
need to observe a release/restore result should use explicit lifecycle calls.
The checked command-buffer defer ends an unfinished offscreen pass and cancels
unsubmitted work; submit/cancel consumes the handle, making deferred discard a no-op.

An application panic, failed verify, or runtime fault still bypasses finally in
the pinned runtime. These scopes do not promise cleanup after arbitrary panic.
Ordinary SDL errors no longer take that path. Tests use verify as a failing-test
assertion, not as a library error policy. Upstream daScript is unchanged.

Reference checked locally: dasBGFX examples/01_hello_triangle.das imports
daslib/defer and defers glfwTerminate/glfwDestroyWindow. That example also uses
panic on startup failures; it is evidence for the ownership idiom, not proof of
panic unwinding. dasSDL3 deliberately returns failure values instead.

## Verification

Latest combined verification: [gpu-native-validation.md](gpu-native-validation.md).
Current function census: [api-coverage.md](api-coverage.md).
