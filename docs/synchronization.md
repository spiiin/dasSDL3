# Synchronization (P7)

All 28 functions from pinned SDL 3.2.18 SDL_mutex.h have generated signatures:
Mutex (5), RWLock (7), Semaphore (7), Condition (6), InitState (3).
`dassdl3/sdl3_synchronization` adds thin Result factories, ownership scopes,
synchronous lock scopes and three reference adapters for SDL_InitState.
No thread/Context scheduler or resource registry is introduced.

## Ownership and results

`create_mutex/rwlock/semaphore/condition` returns Result of the owning pointer;
`destroy_*` consumes that variable by clearing it after destruction. Other copies
remain raw aliases. `with_mutex/rwlock/semaphore/condition` owns the primitive
through a synchronous block returning Result<T,SdlError>, and destroys after the
block returns, including Err. It does not join arbitrary users of the primitive.
Finish all users/waiters before destruction; do not release or return borrowed
pointers from owning scopes. SDL initialization is not needed for these primitives.

`with_mutex_lock`, `with_rwlock_read` and `with_rwlock_write` borrow live objects
and unlock through defer on the same thread. The body must not manually unlock,
destroy, or transfer the lock to another thread. Null is an explicit Err in these
scopes. They pass the body's Result unchanged, including arrays and scalar values.
Arbitrary application panic can bypass pinned daScript defer; no panic safety is
promised. Error messages from allocation failure are copied immediately.

SDL mutexes are recursive: every successful recursive lock needs one unlock.
RW-locks do not support recursive write acquisition, upgrade or downgrade;
read recursion/ordering varies by backend, so these helpers promise none.

`try_lock_mutex`, `try_lock_rwlock_read/write`, `try_wait_semaphore`,
`wait_semaphore(sem,timeout_ms)` and `wait_condition(cond,mutex,timeout_ms)`
return bool, preserving SDL. False means unavailable/timeout, not an SDL error.
They do not inspect or clear stale SDL_GetError. Live-object preconditions and
raw null conventions are unchanged. A successful try-lock must be unlocked;
a successful semaphore wait consumes one token. GetSemaphoreValue is only an
instantaneous observation, not a check-then-act synchronization mechanism.
Negative SDL timeout means unbounded wait; avoid it in a browser/event-loop thread.

Condition waits require the calling thread to own the associated mutex, exactly
once. Wait atomically releases it while waiting and reacquires it before returning,
including timeout. Signals can be lost when nobody waits and wakeups can be spurious:
always check the application's predicate in a loop under that same mutex. A wake
signal alone is not the predicate. Do not use an RW-lock as a condition mutex.

## Initialization state

A fresh zero-initialized SDL_InitState can be passed to `should_init`/`should_quit`.
When either returns true, the same transition must be completed with
`set_initialized(state,success)` (false after cleanup). A failed initialization
can be retried. Keep the state at a stable address; do not copy/move/reinitialize it
while other threads can use it, and do not mutate status/thread/reserved directly.
The record fields are raw declarations, not permission for non-atomic access.
The state arbitrates initialization; it is not a reference count or a lock for the
resources initialized. Ref adapters borrow only for the synchronous call.

## Tests and limits

[tests/synchronization.das](../tests/synchronization.das) calls all 28 raw APIs.
Native-only probe workers exercise mutex/RW contention, cross-thread semaphore
handoff and condition wait/reacquisition. No worker enters a daScript Context or
retains a script callback. Test waiters are joined before resource destruction.
Timeout, stale-error behavior, initialization retry, null lock-scope errors,
scalar/array Result forwarding and deferred unlock after Err are covered.
[81_synchronization.das](../examples/81_synchronization.das) is a fixture-free example.

Thread/TLS and Atomic are covered in [thread-atomic.md](thread-atomic.md).
Process/LoadSO and platform services are covered in [process-loadso.md](process-loadso.md)
and [platform-services.md](platform-services.md). These bindings do not make concurrent calls into the
same daScript Context safe. Desktop tests do not imply Web worker support; the
existing Web profile is still single-threaded and is not expanded by this package.

## Local validation (2026-09-22)

Windows x64/MSVC: main test and example 2/2; legacy/CppGenBind/AOT test and
example plus metadata/missing-AOT gates 8/8; generation/inventory/API-boundary
and Result/scope/try regression gates 7/7. The no-LLVM/no-Clang consumer build
runs example 81 and passes the public API boundary check. Generation remains
deterministic. Other operating systems and Web workers are not validated here.
