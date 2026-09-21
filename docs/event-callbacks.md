# Events callbacks (SDL 3.2.18)

All 19 Events functions now have generated raw bindings. Five native callback
functions complete the declaration set: SDL_SetEventFilter, SDL_GetEventFilter,
SDL_AddEventWatch, SDL_RemoveEventWatch and SDL_FilterEvents.

## Native addresses

Raw callback arguments are C function addresses (`void?` in daScript), never
script functions or blocks. The callback ABI is SDL_EventFilter. Callers own
callback code and userdata lifetime, thread synchronization and unregistering.
SetEventFilter replaces the process-wide filter; unset with a null filter.
RemoveEventWatch must receive the same callback and userdata as registration.
GetEventFilter returns false for normal absence, not an SDL error.
SDL_GetEventFilterRef supplies explicit output references for native addresses.

Retained filters/watches may run on another thread, including the thread calling
PushEvent. Do not use them to enter a shared daScript Context. No retained script
callback overload is provided. PeepEvents ADDEVENT bypasses both callbacks;
a watch return value does not reject an event. A filter false return does.
Replacing a global filter follows SDL behavior, including processing queued events.

## Synchronous script predicate

`filter_events(predicate)` in `dassdl3/sdl3_event_queue` returns
Result<SdlUnit,SdlError>. SDL_FilterEvents itself has no failure result: normal
completion is Ok, regardless of stale SDL error text. The predicate returns bool:
true keeps the event, false removes it. It can edit the borrowed SDL_Event.

The native adapter keeps Block/Context only on the calling stack. SDL invokes it
synchronously and retains nothing after return. No registry, catch, panic or
protected invocation is added. Follow the calling Context's ordinary thread rules.

SDL holds its queue lock while visiting entries. Within the predicate, do not
pump, push, poll, flush, recursively filter, toggle event enablement, change the
global filter or shut down SDL. Do not wait for another thread using the queue.
Do not retain event references or replace pointer payloads with short-lived data.
Use decode_event to copy supported payloads for storage. Return normally: the
pinned runtime's panic can bypass native stack cleanup and SDL's queue unlock.
These are caller preconditions; the adapter does not intercept arbitrary raw SDL calls.

[Example 69](../examples/69_event_filter.das) keeps even user-event codes without
unsafe expressions. [Tests](../tests/event_callbacks.das) execute all five raw
functions, identity/userdata round trips, filter rejection/mutation, native worker
thread callbacks, ignored watch return values, unregistration, ADDEVENT bypass,
script mutation/removal/order, empty queues and stale-error success.

This completes Events declarations, not all event payload projections or all P3.
Keyboard/Mouse and the remaining owned event payloads follow next.

## Local validation — 2026-09-21

Windows x64/MSVC: four main Events checks, three existing Clipboard/hit-test
checks, eight legacy/CppGenBind interpreter checks and seven strict-AOT checks
passed. Metadata parity and all ten generation/inventory/preprocessor/boundary
checks passed. The negative callback-type probe rejects script blocks on all
three interpreter runners. Tests cover native worker-thread callbacks; no
script Context is entered by that worker.

The BUILD_TESTING=OFF consumer rebuilt with LLVM, Clang and Python discovery
disabled. Example 69 and a fixture-free raw/ref absent-filter probe passed;
script blocks were rejected by raw callback APIs and test callback exports were
confirmed unavailable.
