# Audio callbacks, WAV IO and conversion

The remaining nine Audio functions are generated: SDL_SetAudioStreamGetCallback,
SDL_SetAudioStreamPutCallback, SDL_OpenAudioDeviceStream,
SDL_SetAudioPostmixCallback, SDL_LoadWAV_IO, SDL_MixAudio,
SDL_ConvertAudioSamples, SDL_GetAudioFormatName and SDL_GetSilenceValueForFormat.
Audio raw declaration coverage is 56/58 for SDL 3.4.16 (56/56 in the original 3.2.18 package). SDL_AudioFormat is now a
selected enum, and SDL_AudioSpec exposes its format field in addition to channels
and freq. Existing uint format constants and factories remain usable. Require
`dassdl3/sdl3_audio_final` for the thin boost layer, including the enum factory
overload. This does not make all SDL behavior safe or validate hardware.

## Native callbacks only

The four callback APIs are explicitly allowlisted in both generators. Script
arguments are native C function addresses and void userdata pointers, with AOT
address-cast adapters preserving the original SDL function contract. A daScript
Block/Func is not accepted. Do not pass pointers to movable or scope-local script
storage as retained userdata. Native function code and userdata must outlive every
callback; unloading the native module while registered is invalid.

Get callbacks run before stream reads and may supply input bytes. Put callbacks
run after writes and may consume output bytes. Additional/total byte counts can
be zero or approximate due to resampling; they are not an obligation to fill an
exact amount. Stream callbacks run under the recursive stream mutex, possibly
on the audio thread or another caller's thread. Do not call back into daScript.
Use the native callback's stream for short, bounded native work.

Setting a stream callback to NULL acquires its lock and waits for an in-progress
callback to finish. After successful unregister returns, its userdata can be
released, provided nothing concurrently re-registers it. Postmix unregister waits
for the device's current iteration. Postmix receives a borrowed float buffer and
current format, which may change between calls; it can modify the final mix, must
not retain that buffer, and should not allocate/block or do heavy work. Never
destroy a stream/device from its own callback. Pausing alone is not the lifetime
barrier used by these wrappers. There are no implicit callback scopes restoring
unknown previous callbacks: use explicit unregister or destroy the owning stream.

`open_audio_device_stream(device,spec[,callback,userdata])` returns Result of a
stream which owns its logical device. It starts paused for both playback and
recording. App spec describes playback input / recording output. Destroying this
stream also closes the device; do not close its borrowed device separately.
`with_audio_device_stream` defers that destruction and returns the body's Result.
Raw SDL_OpenAudioDeviceStream also permits a NULL spec; the ref helper uses an
explicit spec. No script callback trampoline, mixer graph or worker registry is
introduced.

SDL 3.4.16 rejects an invalid logical device ID in SDL_SetAudioPostmixCallback;
the boost setter returns Err. This fixes the old 3.2.18 behavior that returned
true in that case. A nonempty SDL_GetError after success still does not turn
success into Err. The invalid-ID result is covered by a regression test.

## WAV and buffers

`load_wav_io(io,spec)` borrows the IOStream and returns owned PCM bytes plus the
output spec. The raw closeio argument is deliberately not hidden: use an IO scope
for an explicit fallible close, or raw SDL_LoadWAV_IO(closeio=true) when transferring
ownership. Raw closeio consumes the IOStream on success AND failure and ignores
its close result. With closeio=false SDL seeks to its computed end position, which
can also replace error text; callers cannot recover an earlier internal error.

SDL owns and frees a failed WAV output. The pinned source sets local audio_buf /
audio_len variables to zero instead of clearing the caller slots on this failure
path, so never free or use failure out-pointers. The existing owned WAV loader
was corrected to avoid a redundant SDL_free on failure; the new copy adapter
only adopts successful output. Successful PCM buffers are copied, range checked
against INT_MAX, then SDL_free'd. The script array survives closing the IOStream.
Compressed WAV variants are not exhaustively tested.

`mix_audio(dst,src,format,count,volume)` mutates the first count bytes of dst and
returns Result<Unit>. Both capacities and whole-sample alignment are checked;
volume must be finite in [0,1], as required by SDL's contract. SDL performs sample
addition and clipping; this is not stream scheduling. Raw SDL_MixAudio retains
its original pointer/count signature and caller preconditions.

`convert_audio_samples(src_spec,bytes,dst_spec)` converts a complete buffer into
an owned byte array. Input must fit int and contain whole frames. The native
adapter rejects the same array as both input and output, bounds counts, and frees
the SDL output after copying. Empty valid input yields empty output. SDL does
format/rate/channel conversion; use a persistent audio stream for chunked
resampling to avoid boundary artifacts and repeated stream creation.

Format names are static SDL strings (unknown formats return SDL_AUDIO_UNKNOWN).
Silence value is a byte value, not a Result: U8 uses 128, common signed/float
formats use zero. No extra error inference is added.

## Tests and remaining work

[Tests](../tests/audio_final_api.das) call all nine raw functions. They check PCM16
WAV decoding, borrowed versus consumed IO, bad WAV input, exact stereo float
conversion, clipping/half gain, invalid capacities/alignment/volume, empty input,
address callbacks on a native worker and dummy playback/recording, postmix
metadata and unregister barriers. Native callback fixtures hold only native
storage/atomics and are excluded from production. No physical microphone is used.
[Example 79](../examples/79_audio_conversion.das) mixes and converts PCM entirely
in memory with Result/sdl_try and a scoped stream, without unsafe or test fixtures.

[Stream channel-map default handling](audio-stream-controls.md) is fixed upstream
in SDL 3.4.16 and tested; copied boost getters remain a follow-up. Hardware
playback/capture, hotplug/default migration, callback deadline guarantees, unusual
formats and other OS backends remain unverified. Camera is the next P5 section.

Local Windows x64 validation: four audio test/example pairs passed under baseline,
CppGenBind and strict AOT, with matching metadata (25 checks); no AOT fallback.
Main audio tests (8), generation/inventory/boundary gates (6), standalone clangbind
checks (4) and docs links passed. A script block passed as callback is rejected
at compile time. Consumer without testing, generators, LLVM or Python discovery
built and ran example 79; native callback test helpers are absent in production.
