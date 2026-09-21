# AsyncIO (SDL 3.2.18)

All 11 functions in `SDL_asyncio.h` are generated, with the two opaque pointer
kinds, both enums and all eight fields of `SDL_AsyncIOOutcome` (`type` is exposed
as `task_type`). Raw signatures and return values are preserved.

## Submission and completion

`open_async_io`, `async_io_size`, `read_async_io`, `write_async_io`,
`close_async_io` and `load_file_async` return Result. Submission success does not
mean the task succeeded. `get_async_io_result` / `wait_async_io_result` return
Option of the native outcome. Inspect `result` (COMPLETE/FAILURE/CANCELED) and
`bytes_transferred`; successful reads can be short, including zero at EOF.
None covers an empty queue, timeout, signal, spurious wake or native retrieval
failure. It is not inferred from SDL_GetError, whose text can be stale.

Pinned generic, Windows I/O ring and io_uring backends do not transport a task's
error string to the caller through the outcome. `take_async_file_bytes` uses a
fixed failure/cancellation message, never an unrelated thread error. Submission
errors use the ordinary immediate copied SDL error. No per-task cancel function
exists in these 11 APIs; signaling wakes waiters and does not cancel their work.

## Pinned short-read defect

The local Windows run returns FAILURE with three valid transferred bytes when
reading eight bytes at offset one from a four-byte file. In the pinned generic
backend, `SDL_ReadIO` leaves status READY on a positive partial read; the async
worker accepts only EOF for a short successful read and consequently reports
FAILURE. This is consistent with the observed preserved byte count (the Windows
I/O ring failed-HRESULT path does not copy that count). The binding does not
rewrite failure into success. Tests accept either native COMPLETE or FAILURE
for this short-read case while requiring the exact count and bytes; an in-range
read and zero-byte EOF are tested independently. A debug SDL build can assert
on this generic-backend READY status. This is not fixed in vendored SDL.

## Buffers and shutdown

Read/write buffer and userdata pointers must remain valid and stationary until
completion (or queue drain). Read buffers must not be accessed while the task
writes them. Do not submit a movable daScript array and then return from its
owning scope. There is deliberately no async array adapter that borrows `.data`
for longer than a synchronous call. Native allocation or an explicitly stable
caller-owned buffer is required. The runtime tests retain unchanged arrays in
the same scope and await their tasks before leaving.

A successful close submission consumes the AsyncIO pointer immediately, even
before outstanding operations complete. `close_async_io` nulls its ref only on
successful submission; failure leaves ownership with the caller. Outstanding
outcomes' `asyncio` pointers are identity tokens and may already be dangling.
Do not dereference them. The close outcome follows outstanding tasks.

`with_async_io_queue` defers SDL_DestroyAsyncIOQueue: destruction blocks until
pending work finishes and discards remaining outcomes. It releases unretrieved
LoadFileAsync buffers, but does not close arbitrary open AsyncIO files or own
caller read/write buffers. Submit file closes before destroying their queues.
No other thread may still wait on the queue at destruction. Signal, coordinate
and join external waiters first. There is no implicit worker/job manager.
The pinned daScript runtime can bypass defer on arbitrary panic.

## Taking LoadFileAsync data

`take_async_file_bytes(outcome)` is an explicit consuming adapter for one
original, unmodified LoadFileAsync READ outcome. It copies exactly
`bytes_transferred` bytes to an owned array, frees the native buffer and nulls
`outcome.buffer`. It also consumes that buffer on failure/cancellation or range
validation failure. Empty files work; SDL's extra NUL is not part of the array.
Counts must fit the script array range and not exceed bytes_requested.

The adapter checks the pinned oneshot marker (`asyncio == null`), READ type and
non-null buffer. This is a provenance precondition, not a registry or protection
against forged records. Outcome copies alias the buffer: consume exactly once
and never use a saved alias afterwards. For manual raw consumption use SDL_free.
After retrieval queue destruction no longer frees that buffer for you.

Get/Wait ref adapters clear the output on false: SDL can internally consume a
hidden oneshot CLOSE and still return false after writing an outcome. Raw SDL
functions remain unchanged. Opening and getting size are synchronous, and queue
destruction can block. This API does not promise every call is nonblocking.

## Verification

[Tests](../tests/asyncio.das) call all 11 raw functions and cover empty/timeout,
stale errors, short/EOF reads, explicit offsets and userdata, close ordering,
ref consumption, owned/empty file copies, duplicate consumption rejection,
range rejection and pending queue drain. Failure/cancellation consumption tests
use real allocated load results with synthetic status values: they do not prove
OS task cancellation or an actual disk failure. Cross-thread wake/join and other
OS backends remain unverified. [Example 76](../examples/76_asyncio.das) uses
sdl_scope/sdl_use/sdl_try without unsafe or address expressions.

Local validation (Windows x64, pinned SDL/daScript): main test and example passed;
baseline/CppGenBind/strict AOT test and example plus metadata parity passed (7
checks); generation/inventory/boundary gates (6) and standalone clangbind gates
(4) passed. Consumer with testing/generators/LLVM/Python package discovery
disabled built and ran example 76; public API boundary passed. No AOT fallback.
