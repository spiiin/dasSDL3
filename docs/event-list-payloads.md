# IME candidates, clipboard MIME lists and user pointers

Pinned SDL 3.2.18. Raw Events remains 19/19 generated functions; this package adds
four native adapters and two owned SdlEvent alternatives, not more SDL functions.

## Owned lists

`text_editing_candidates` carries TextEditingCandidatesEvent: timestamp:uint64,
window_id:uint, candidates:array<string>, selected_candidate:int, horizontal:bool.
`clipboard_update` carries ClipboardEvent: timestamp:uint64, owner:bool,
mime_types:array<string>. Selection -1 means no selection; its native value is
preserved, not clamped. Clipboard `owner` is SDL's internal-update flag, not
ownership of script memory.

SDL's pointer arrays and every pointed-to UTF-8 string are copied immediately.
The source must remain valid for the duration of decode_event; no SDL allocation
is freed by decoding. Subsequent polls/pumps may invalidate native payloads but
cannot invalidate the copied lists. Empty/null lists with count zero are valid;
null string elements become empty strings. SDL_PushEvent does not turn arbitrary
application pointers into owned data: manually supplied arrays/strings must still
outlive their queued uses. The adapters do not create events with script-backed
string pointers or retain arbitrary script storage for asynchronous delivery.

SDL_ReadTextEditingCandidatesEvent and SDL_ReadClipboardEvent return bool and
take native metadata plus an output array<string>. Pointer fields are not exposed
in those native annotations and are cleared in the returned metadata. On wrong
tag the outputs are cleared and false is returned without interpreting the union.
Negative/oversized counts or a positive count with NULL array also return false,
clear the outputs and set an SDL error. decode_event represents such malformed
events as Unknown with the original type/timestamp. This is structural validation,
not validation of arbitrary memory addresses supplied by the application.

## Moving events

An array<string> is move-only in daScript. Consequently **SdlEvent and its
Option/Result containers are now move-only for every tag**, including Quit and
keys. They remain clonable. No new shared-pointer container or event ownership
framework has been introduced.

```daslang
var next <- poll_event()
if (is_some(next)) {
    let event <- move_unwrap(next)
    match(event) {
        if (SdlEvent(text_editing_candidates=$v(ime))) {
            for (candidate in ime.candidates) { print("{candidate}\n") }
        }
        if (_) { }
    }
}
```

Use `<-` to initialize/assign returned events, options and results. Guard
move_unwrap with is_some/is_ok: as in the standard library, invalid unwrap is an
explicit caller panic. A reference passed to match or a function does not need
cloning. Use `emplace(events,event)` to move an event into an array, or
`push_clone(events,event)` / `clone_to_move(event)` when an independent list is
required. Standard `unwrap`/`some` clone non-copyable payloads; use move_unwrap /
move_some when the source can be consumed. poll/wait/batch helpers move their
decoded payloads rather than cloning each list. Managed string bytes may be shared
by a clone; the arrays are independent.

## Raw user pointers

SDL_ReadUserEventData(event,var data1:void?,var data2:void?) reads the two borrowed
addresses. SDL_WriteUserEventData(var event,data1:void?,data2:void?) writes them.
Both accept only USER <= type < LAST. Read clears both outputs on mismatch; write
leaves a mismatched event unchanged. False means wrong tag, not an SDL error
inferred from SDL_GetError. NULL pointer values are valid and are preserved.
Writing pointers preserves timestamp, window ID, type and code.

Neither adapter dereferences, copies the pointee, takes ownership, frees memory,
pins a daScript object nor schedules a callback. Keep the actual owner alive until
all queued/in-flight consumers are finished. Filter rejection, flushing, SDL_Quit
and SDL copying an SDL_Event do not supply a destructor for user data. Stack
variables, blocks and arbitrary context-owned script pointers must not be retained
across their lifetimes or used from another context/thread without a separate
native lifetime/synchronization contract. SdlEvent.user deliberately retains only
metadata; use raw SDL_Event when application pointer identity is required.

## Checks

[event_lists.das](../tests/event_lists.das) covers UTF-8 and null entries, empty and
malformed shapes, poisoned inactive union members, independent cloned arrays,
retention across source mutation and SDL_PumpEvents, poll/peek/take/wait/timeout,
user-pointer identity through the queue, tag boundaries and non-owning flush.
[Example 67](../examples/67_event_variants.das) displays real IME candidates and
clipboard MIME notifications using English messages. Other event examples use
move syntax as well. Synthetic tests do not certify OS IME presentation or real
clipboard-owner notification delivery.

Local validation (2026-09-21, Windows x64/MSVC): 11 main tests/examples passed.
All 34 baseline/CppGenBind/strict-AOT and metadata checks passed, with AOT
fallback disabled. Six main generation/inventory/boundary and four standalone
clangbind checks passed. The no-LLVM BUILD_TESTING=OFF consumer ran examples
67–71 successfully and rejected the native list fixture. Documentation links
and diff whitespace checks passed. Production generator configuration is restored
after the consumer check.
