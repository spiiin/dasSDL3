# Audio device discovery and logical ownership

Audio raw coverage is now 56/56 after [final Audio API](audio-final-api.md). SDL 3.2.18: 21 additional raw functions cover driver enumeration, playback and
recording device enumeration, names, format/channel-map queries, logical open /
close, physical/playback predicates, pause/resume/gain and single/multiple stream
binding. The default recording ID constant is now exported too. Existing WAV and
stream helpers remain in [audio.md](audio.md); this layer requires
`dassdl3/sdl3_audio_devices_boost` and re-exports them.

## Results and ownership

Enumeration returns Result of copied arrays of physical uint IDs. The SDL arrays
are freed after copying, without including the zero terminator. Names are copied
strings. Driver lookup/current driver return Option (invalid index/uninitialized
subsystem); device name returns Result. SDL audio IDs stay their native uint32
representation; physical and logical IDs are not new wrapper objects.

`open_audio_device(id[,spec])` returns Result of a new logical device ID. Opening
an already opened logical ID creates another independently closable logical
device on the same physical device. Spec is a hint, not a guarantee: query the
actual format afterwards. `audio_device_format(id,frames)` returns Result of the
spec and writes the buffer size in sample frames, not bytes. The old format
factory/getter is retained for SDL_AudioSpec; no new format enum is required.

`with_audio_device(id[,spec])` opens, calls its Result-returning body and defers
close, including early Err and move-only results. Do not close the borrowed ID
inside the body or let it escape as an owner. `close_audio_device(var id)` closes
and zeros the caller ID, but cannot invalidate copied aliases. SDL_CloseAudioDevice
returns void. Closing unbinds attached streams and does NOT destroy them. Closing
a logical device does not close other logical devices on the same hardware.

Bind/unbind array adapters borrow the pointer list synchronously; SDL retains the
stream objects, not the array. Streams must stay alive until unbound or device
close (destroying a stream also unbinds it). The scope does not create an implicit
stream group or mixer object. Device open starts unpaused, unlike the existing
SDL_OpenAudioDeviceStream playback convenience. Pause before binding if needed.

Pause/resume/set gain and bind return Result. Get gain uses SDL's negative error
sentinel. SDL accepts gain zero (silence) and values above one; the binding adds
no clamping. Paused/physical/playback remain native predicates: false is not Err.
In the pinned SDL the latter two inspect ID bits and do not validate liveness.

## Channel map ambiguity

`audio_device_channel_map` returns Result<Option<array<int>>>. None preserves a
native null map: usually default channel ordering, but SDL also returns null on
an invalid device or failed allocation. This API cannot reliably distinguish
these states and does not infer failure from SDL_GetError. Err is reserved for
an adapter range/copy validation failure; non-null native maps become owned
arrays and are freed. The dummy backend exercises only default/None; a physical
backend's custom channel map remains unverified.

## Verification and limits

[Tests](../tests/audio_devices.das) use SDL_AUDIO_DRIVER=dummy and call all 21 raw
functions. They check copied discovery, format, predicates, independent logical
opens, pause/gain, one/multiple bindings, close-unbind behavior and dummy recording
converted to PCM16 silence with bounded waiting. No real microphone is opened by
these tests. [Example 77](../examples/77_audio_devices.das) enumerates devices and
binds an empty playback stream through sdl_scope/sdl_use/sdl_try. It does not open
recording devices or queue audible samples.

Stream format/ratio/gain/channel maps/properties and locks are now available in
[audio-stream-controls.md](audio-stream-controls.md). Native callbacks and WAV/mixing/conversion are now available in
[audio-final-api.md](audio-final-api.md). Camera follows. Hardware playback/capture,
hotplug/default migration, custom device channel maps and other OS backends need
separate validation. Defer has the pinned runtime's arbitrary-panic limitation.

Audio raw declarations are now complete; current limitations are listed in
[audio-final-api.md](audio-final-api.md).

Local Windows x64 validation: old/new audio tests and examples passed under
baseline and CppGenBind interpreters and strict AOT; metadata matched (13 checks).
Generation/inventory/boundary gates (6) and standalone clangbind gates (4) passed.
Consumer with testing, generators and LLVM/Python package discovery disabled
built and ran example 77 with dummy audio; public API boundary passed.
