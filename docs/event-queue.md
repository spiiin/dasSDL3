# Event queue

The Events header now has 19/19 generated functions. This queue package adds the
eleven remaining non-callback functions: PeepEvents, HasEvent(s), FlushEvent(s),
WaitEvent, WaitEventTimeout, SetEventEnabled, EventEnabled, RegisterEvents and
GetWindowFromEvent. PumpEvents, PollEvent and PushEvent were already generated.
All SDL_EventType constants and the SDL_EventAction enum are available.
Raw signatures and return sentinels are unchanged.

The five callback APIs are covered in [callback contracts](event-callbacks.md),
including the synchronous script predicate. This is not full P3 coverage.

## Boost contracts

Import `dassdl3/sdl3_event_queue`, which re-exports the existing events/boost
modules. [Example 68](../examples/68_event_queue.das) uses `sdl_scope`, pipe-style
`sdl_use`, `sdl_try`, timed waiting and custom event metadata.

| Operation | Result |
| --- | --- |
| `wait_event()` | `Result<SdlEvent,SdlError>` |
| `wait_event(raw)` | `Result<SdlUnit,SdlError>`; raw payload stays borrowed |
| `wait_event_timeout(ms)` | `Result<Option<SdlEvent>,SdlError>` |
| `wait_event_timeout(raw,ms)` | `Result<Option<SdlUnit>,SdlError>` |
| `peep_events(raw_array,action,min,max)` | `Result<int,SdlError>`; count, possibly partial |
| `count_events(min,max)` | `Result<int,SdlError>` without consuming events |
| `peek_events(limit,min,max)` | `Result<array<SdlEvent>,SdlError>`; leaves queue intact |
| `take_events(limit,min,max)` | `Result<array<SdlEvent>,SdlError>`; removes matching events |
| `register_events(count)` | `Result<uint,SdlError>`; first allocated custom type |
| `event_window(raw)` | `Option<SDL_Window?>`; borrowed window, not an owner |

As with existing mutable-pointer Results, extract the window from a mutable
Option using standard `move_unwrap` after checking `is_some`. The pinned
standard library's copying `unwrap` cannot remove pointer constness.

Type bounds are inclusive. The default range is FIRST..LAST; owned batch reads
default to at most 64 events. They do not pump the queue. Zero capacity is a
successful empty read, not SDL's special NULL-buffer count query. Negative limits
are rejected before allocation. For raw output arrays, only the returned prefix
contains events; unused entries are cleared. Count and peep adapters clear the
thread's old error before calling SDL and provide a fallback message if SDL
returns -1 without one (notably PEEKEVENT after shutdown in this version).

ADDEVENT may accept fewer events than requested, including zero on a full queue.
A nonnegative count is returned as success even if SDL left an overflow message.
The caller handles partial acceptance. ADD bypasses event filters/watchers and
does not fill timestamps like PushEvent. Enabled state is a producer-side rule;
neither ADD nor PushEvent provides a generic disabled-type rejection guarantee.
Disabling a type flushes already queued events of that type. Raw predicates and
void setters/flush functions need no Result facade.

## Timeout and registration limitations

SDL_WaitEventTimeout's bool has no independent error code. The adapter clears
SDL's old error, calls once, and maps true to Some regardless of the error string.
After false, a newly nonempty error becomes Err; otherwise the result is None.
This is an explicit diagnostic convention for SDL's ambiguous return, not an
independent backend error channel. It can also observe errors from implicit
event pumping. Zero timeout is a nonblocking poll cycle; negative timeouts keep
SDL's indefinite-wait behavior. Scheduling may exceed a positive timeout.

RegisterEvents can return zero without setting an error in SDL 3.2.18. Boost
validates a positive count and supplies its own failure text, never a stale SDL
error. It also rejects a returned range extending beyond LAST-1: the pinned
implementation checks the starting index but not the whole requested range.
Such a native allocation cannot be rolled back. Event IDs have no release API;
allocate them during setup, not every frame. Raw RegisterEvents stays unchanged.

## Payloads and lifetimes

Owned batch/wait results decode immediately before another pump. Drop Begin,
File, Text, Complete and Position have separate SdlEvent tags sharing a DropEvent
payload: timestamp, window ID, position and copied source/data strings. Missing
strings become empty; begin coordinates retain SDL's unspecified semantics.
Custom event types in USER..LAST-1 produce UserEvent metadata (type, timestamp,
window ID, code). Application-defined data1/data2 pointers are deliberately not
represented in the owned variant; their ownership cannot be inferred.
This package does not add script readers/writers for those two pointers. Raw
queue calls preserve the opaque SDL_Event contents; pointer-bearing custom
payload access remains a separate native-adapter contract.
`SDL_MakeUserEvent` creates an event with null data pointers and a zero timestamp;
use a registered type. No custom-event registry or dispatcher is introduced.

Peep's raw SDL_Event copies do not own pointer payloads. The owned read functions
copy all supported text immediately, but cannot protect against another thread
flushing or consuming the same queue concurrently between retrieval and decode.
Use the owned script API on the main thread and serialize destructive queue
access. Waiting/pumping follows SDL's main-thread restriction. Unknown payloads,
including clipboard MIME arrays and IME candidate lists, remain Unknown until
their dedicated contracts are added. No thread may invoke a shared script
Context through retained SDL callbacks.

Tests in [event_queue.das](../tests/event_queue.das) execute all eleven new raw
functions and the adapters, queue ordering/ranges, peek versus take, zero and
negative capacities, timed/indefinite queued waits, stale-error timeouts,
partial ADD and a full pinned queue,
shutdown errors, window lookup, enabled state and copied UTF-8 drop payloads.
The fixture supplies only event data, never hides queue operations under test.
Real drag-and-drop from external applications and other OS event backends are
not established by these synthetic tests.

## Owned list payloads and moves

Owned reads also copy IME candidates and clipboard MIME strings. SdlEvent and
its Option/Result are move-only: bind them with `<-`; use move_unwrap after the
corresponding tag check. peek/take produce independent arrays and move their
decoded events into the returned list. Raw reads retain borrowed payloads.
The [list/pointer contract](event-list-payloads.md) covers explicit cloning,
malformed-list fallback and raw user-data pointer readers/writers. SdlEvent.user
still contains only metadata.
