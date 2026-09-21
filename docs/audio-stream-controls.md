# Audio stream controls (SDL 3.2.18)

Twelve additional raw functions cover stream properties, setting format, frequency
ratio, gain, input/output channel maps and lock/unlock. Audio raw coverage is
56/56 after [final Audio API](audio-final-api.md). Require `dassdl3/sdl3_audio_stream_controls`, which re-exports the existing
[audio](audio.md) and [device](audio-devices.md) helpers. No mixer or scheduler
objects are added. Raw SDL signatures and sentinels remain unchanged.

## Formats, gain and ratio

`audio_stream_formats(stream,src,dst)` fills both output refs and returns Result.
Use `set_audio_stream_formats`, `set_audio_stream_input_format` or
`set_audio_stream_output_format` to change both sides or just one (the other native
pointer is NULL). Previously queued input retains its original format. For a
stream bound to a device, changes to the device-facing format are silently
ignored by SDL and still return success. Query afterwards if the actual format
matters. The borrowed properties ID belongs to the stream: do not destroy it.

Gain and ratio are applied when retrieving data. Gain zero is silence, not failure;
the negative gain getter sentinel becomes Err. Ratio zero is the error sentinel;
SDL accepts ratios 0.01 through 100 and ratio >1 consumes input faster, changing
pitch and speed together. There is no pitch-preserving time stretch. The binding
adds no clamping or alternate resampling implementation.

## Channel maps

Arrays are copied synchronously by SDL when set, and raw getters allocate arrays that require SDL_free (subject to the pinned
defect below). An input map is recorded with queued
input; changing it does not retroactively reorder earlier data. Output maps apply
when retrieving data. Entries select channels; duplicates duplicate a source and
-1 mutes that output channel. They cannot change the channel count.

The pinned `SDL_GetAudioStreamInputChannelMap` and output counterpart are unsafe
for default maps: they pass a null `stream->src_chmap` / `dst_chmap` to
SDL_ChannelMapDup, which unconditionally memcpy's it. The native test reproduced
a process crash immediately after resetting a map. Query only a known, explicitly
set non-default map while excluding concurrent reset/format changes. An identity
map may normalize to NULL and is not sufficient for this precondition.

Raw declarations are preserved and tested with non-default maps. Safe copied
boost getters are deferred: there is no public SDL query to discover whether the
internal map is null. No private struct-layout access, shadow registry or vendor
patch is added. A future SDL fix can enable Result/Option copied getters. The
AudioDevice map getter has a separate null guard and is unaffected.

Setters require exactly the current side's channel count. Empty arrays do not
mean reset. Use `reset_audio_stream_input_channel_map(stream,channels)` or its
output counterpart: the explicit count is required even for a native NULL map.
Use a lock scope if querying the format and setting a map must form one atomic
operation relative to other stream users. Changing channel count clears that
side's map. Native adapters reject null streams before map setters; raw SDL remains
unchanged (the pinned raw setters compute field addresses before their null check).

## Locks and cleanup

`lock_audio_stream` / `unlock_audio_stream` return Result. They expose SDL's
recursive mutex; unlock must occur on the same thread as lock. Most SDL stream
calls already lock internally, so extra locking is for compound operations or
coordination with native callbacks, not required around every call.

`with_audio_stream_lock` takes a synchronous, Result-returning block, acquires the
lock first and defers unlock. It propagates move-only results and preserves the
body error if unlock also fails. Never destroy the stream, explicitly consume this
scope's lock, switch execution threads or wait for a worker needing the same lock
inside the block. Short scopes avoid stalling an audio thread. Arbitrary panic can
bypass defer in the pinned daScript runtime; this layer adds no panic or catch.

## Tests and remaining work

[Tests](../tests/audio_stream_controls.das) execute all twelve new raw functions:
properties, recursive locks, map copy and reset, queued input-map and format
history, output mute/reorder, exact float gain samples, ratio/resampling counts,
invalid counts/indices/sentinels, bound-format behavior with dummy audio. A native
test-only worker acquires the lock after early Err and move-only scope returns;
CTest's timeout catches a leaked lock. It is not a production callback bridge.
[Example 78](../examples/78_audio_stream_controls.das) transforms stereo PCM16 in
memory, without unsafe or audio hardware, using sdl_scope/sdl_use/sdl_try.

All remaining Audio raw functions are now connected; see
[audio-final-api.md](audio-final-api.md) for callbacks and WAV/mixing/conversion.
Camera follows. Physical hardware, callback contention and other OS backends are
not validated by the stream-control tests.

Local Windows x64 validation: three audio test/example pairs passed on baseline,
CppGenBind and strict AOT, with matching metadata (19 checks). Generation,
inventory and API boundary gates (6), standalone clangbind gates (4) and docs
links passed. Consumer with testing/generators/LLVM/Python discovery disabled
built and ran example 78; the thread-lock test helper is absent in production.
