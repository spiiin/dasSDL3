# Native callbacks: Hints, Timer, Log, Init and Properties

Nine declarations are generated from pinned SDL 3.4.16. Callback parameters and
returned function addresses use `void?` in daScript, with native address casts for
AOT. These are C callbacks supplied by the host, **never script Func/Block values**.
Their code and userdata must outlive registration, queued work and in-flight calls.
No script Context is entered on SDL worker threads. Raw return values are unchanged.

## C callback signatures

The host must supply the exact SDL typedef and `SDLCALL` calling convention.
`void?` does not statically verify the pointed-to function's signature.

| SDL typedef | Return | Parameters |
| --- | --- | --- |
| SDL_HintCallback | void | userdata, const char *name, const char *oldValue, const char *newValue |
| SDL_TimerCallback | Uint32 | userdata, SDL_TimerID, Uint32 interval_ms |
| SDL_NSTimerCallback | Uint64 | userdata, SDL_TimerID, Uint64 interval_ns |
| SDL_LogOutputFunction | void | userdata, int category, SDL_LogPriority, const char *message |
| SDL_MainThreadCallback | void | userdata |
| SDL_CleanupPropertyCallback | void | userdata, void *value |

All userdata arguments are `void *`. String arguments are borrowed. Native
callbacks must not throw C++ exceptions across SDL or enter a shared script Context.

## Lifetime and threading

- Hints: Add invokes synchronously with the current value as both old/new values;
  later calls run on the thread changing the hint, under the hint lock. Strings
  are borrowed for the call. Remove uses the same name/address/userdata triple.
  Re-adding the same triple replaces registration and invokes it once immediately.
- Timers: AddTimer uses milliseconds, AddTimerNS nanoseconds. Callbacks run on a
  worker, may precede Add's return, and return the next interval (0 stops).
  **RemoveTimer does not join an in-flight callback.** Cancellation alone does not
  permit freeing userdata. The host must synchronize completion separately; no
  lexical timer owner or script callback scope is provided.
- Log: callbacks receive borrowed message text and may run on any logging thread.
  GetLogOutputFunctionRef returns both native address and userdata through refs;
  save and restore both. Set changes global output. Synchronize host shutdown with
  log producers before releasing callback code/data. Example 92 uses only SDL's
  built-in callback, so it needs no external native fixture.
- RunOnMainThread: on the main thread this invokes immediately; workers queue work
  while events are initialized. With wait_complete=true the worker waits while
  the main thread must keep pumping events. Do not block the main thread joining
  that worker. False means enqueued, not completed; keep userdata alive. Shutdown
  may cancel queued work. With events uninitialized the pinned implementation
  calls immediately on the calling thread. NULL callback is not accepted by the
  binding contract (the pinned immediate path dereferences it).
- Properties: cleanup runs on replacement, clear or destruction, **and on setter
  failure**, including a NULL value. Do not free the value twice on false. The
  cleanup receives userdata and the value; synchronization belongs to the host.
  CopyProperties does not copy pointer properties carrying cleanup ownership.

Tests use native static-lifetime fixtures (no retained script state), assert raw
calls, callback arguments, registration/removal, cleanup on failure and success,
log restoration, both timer units/rescheduling and cancellation during a blocked
callback, and worker-to-main dispatch with both waiting modes. The tests run in interpreter, CppGenBind and strict AOT.
`va_list` APIs remain outside this package.

## Local validation (Windows x64/MSVC, 2026-09-26)

- Main runner: the two contract tests and example 92 passed (3/3).
- Baseline, CppGenBind, strict AOT and metadata comparison: 10/10.
- Freshness, inventory and inventory contracts: 3/3; both generators agree.
- Installed core SDK without LLVM/Python discovery: external example-92 consumer
  passed interpreter, strict AOT and missing-AOT negative checks (3/3). This smoke
  checks installed native log address/ref adapters, not the private callback fixtures.
- Core census: 1062 generated / 13 adapted / 188 pending of 1263. The 169 Stdinc
  pending declarations remain intentionally unbound by the user's decision.

Other platforms and retained script callback bridges are not certified here.
