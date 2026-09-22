# Thread/TLS and Atomic

Pinned SDL 3.2.18: all 12 active Thread and 15 Atomic functions have raw signatures.
`SDL_CreateThread` and `SDL_CreateThreadWithProperties` are C macros, not exported
symbols. The `Native` adapters invoke them with the binding's C runtime callbacks;
raw Runtime functions retain explicit native begin/end addresses.

Require `dassdl3/sdl3_thread_atomic` for Result factories, consuming join/detach,
join-on-exit `with_thread`, TLS references and atomic references.
Callbacks (thread entry, TLS destructor, runtime hooks) are native C addresses only.
Never pass daScript Func/Block addresses or concurrently enter one Context.
Code, userdata and loaded libraries must outlive the worker, including detached
workers and their TLS destructors. Detaching does not stop a worker or release its
userdata. Thread pointers become invalid after join/detach; do not reuse aliases.
Inside `with_thread`, the thread is borrowed: never join/detach it in the body.
The body runs on the calling thread; scope exit waits and propagates its Result.
The worker's integer exit status is separate; use explicit join to retrieve it.
A scope can wait indefinitely if the worker never finishes; it does not cancel work.
A just-created thread can still have ID zero before its entry starts. Synchronize
startup if a test or protocol requires the worker ID.

SDL_TLSID is SDL_AtomicInt: initialize once to zero and keep at a stable address.
Values are thread-local borrowed void pointers; raw null means no value.
Boost get_tls returns Option<SdlTlsValue>; `.address` still borrows the native
value and does not own it. The named payload avoids the same pinned compiler
void-pointer generic collision described in process-loadso.md. Replacing a
value does not run its previous destructor. Destructors run at thread cleanup and
must not call script code. SDL_CleanupTLS affects all TLS on the current thread;
it is explicit raw access, not automatic scope cleanup.

AtomicInt/AtomicU32 fields are only for initialization before sharing. Use atomic
functions for shared access. Set/Add return the OLD value; compare-and-swap false
is ordinary contention, not an error. Pointer atomics synchronize only the slot,
not pointee lifetime. Keep storage alive and stationary until every worker ends.
Spinlocks are nonrecursive and should guard only tiny bounded operations: never
hold them across script execution, waits or callbacks. Memory barriers alone do
not make non-atomic data races valid.

`tests/thread_atomic.das` exercises all raw functions with native worker fixtures,
TLS destructor counters, concurrent increments and scope error propagation.
`examples/82_atomic.das` is fixture-free and uses reference adapters.
Platform validation is local Windows x64; this does not enable web threads.
