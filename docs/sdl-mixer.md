# SDL_mixer

Optional `DASSDL3_WITH_MIXER=ON`, independent of ImGui/image/ttf/net. Import
`dassdl3/sdl3_mixer_boost` in the libraries runner, or raw `sdl3_mixer`.
This binds SDL3's MIX_* API, not SDL2's Mix_Chunk/Mix_Music/channel model.

## Version, codec profile and generation

Pinned [SDL_mixer 3.2.4](https://github.com/libsdl-org/SDL_mixer/tree/release-3.2.4),
zlib license, requires SDL >= 3.4.0; uses the project's shared SDL 3.4.16 target.
Release archive SHA256:
`182a07c745375e113dc740d43964ff21b0be29f29f59876c4dbc4db3d32f6901`.
Static profile: built-in WAVE/AIFF/AU/VOC, dr_flac, dr_mp3, stb_vorbis, raw PCM
and sine synthesis. No extra codec downloads or dynamic codec DLLs. External
FLAC/mpg123, GME, MOD, MIDI, Opus, Vorbisfile/Tremor and WavPack are disabled.
Only WAV/raw/sine decoding has runtime fixtures here; compilation of other
codecs is not format-conformance coverage. Query MIX_GetAudioDecoder at runtime.

All **94** pinned C exports are registered, plus five opaque owner types,
MIX_Point3D, MIX_StereoGains and property/duration constants. Native signatures
are inferred by DAS_BIND_FUN; five callback parameters use explicit C-address
casts. `tools/generate_mixer_bindings.py <SDL_mixer.h> [--check]` checks version,
count and deterministic snapshots. As in the other companion libraries, this
uses a small header snapshot generator, not a second dasclang pipeline.
Consumers need neither LLVM nor Python. Core SDL census is unchanged.

Thirteen additional native adapters provide reference arguments, returned-query
storage and bounded byte/float arrays. Input PCM is copied by MIX_LoadRawAudio;
no daScript memory is retained by these adapters. Native NoCopy/IO APIs remain
available with their original ownership obligations. Float arrays must contain
whole interleaved frames; output float arrays require native F32 format. Counts
are checked before narrowing to SDL's int byte size.

## Result and ownership

| Operation | Contract |
| --- | --- |
| with_mixer_system | matched MIX_Init/MIX_Quit; initialize before every other owner |
| create_mixer / with_mixer | offline mixer, generated only by generate_mix_audio |
| create_mixer_device / with_mixer_device | device-driven mixer; initialize SDL audio first |
| with_mix_audio / with_mix_audio_io | decoded audio from path or borrowed IO; predecode explicit |
| with_mix_raw_audio | copies interleaved native-F32 input |
| with_mix_sine_audio | generated tone; duration in milliseconds |
| with_mix_track / with_mix_group | one SDL_mixer resource each; destroy before mixer |
| with_mix_decoder | independent file decoder; props remain caller-owned |
| mix_format / mix_audio_format / mix_decoder_format / mix_track_position | Result with a returned struct, no script out parameters |
| play_mix_track / stop_mix_track / pause_mix_track / resume_mix_track / set_mix_audio / set_mix_gain / seek_mix_track | Result<Unit>; no panic, callbacks or hidden waits |
| generate_mix_audio | fills caller byte/float array; Result<int> counts real audio **bytes**, excluding appended silence |
| decode_mix_audio | fills caller byte array; Result<int> byte count; zero = EOF |

Factories return Result<native pointer>. Scopes return the body's Result, including
move-only values, and defer cleanup after acquisition. Use typed pipe sdl_use in
sdl_scope. The body borrows the resource and must not destroy it, destroy its
owner, call MIX_Quit, or retain it outside the scope. Application panic is not a
cleanup guarantee. MIX_Init is reference-counted; each successful init has one quit.

Destroy tracks and groups before mixer, and all owners before the final MIX_Quit.
MIX_DestroyAudio releases the caller's reference: an attached track may retain
its own reference. Any borrowed IO or NoCopy memory must therefore outlive **all**
uses, including audio retained by tracks. Prefer audio outside track scopes.
with_mix_audio_io passes closeio=false and does not take ownership; an outer IO
scope must outlive the audio and every track retaining it. Raw closeio=true is an
explicit ownership transfer; do not close the stream again. Borrowed audio streams
attached to tracks must be detached (or tracks destroyed) before stream destruction.

Properties IDs from getters and pointers from track/group owner queries are
borrowed. Arrays returned by MIX_GetTrackTags and MIX_GetTaggedTracks need SDL_free;
the pointed-to track handles stay borrowed. No pointer registry or scheduling
framework is introduced. Existing SDL properties configure playback options.

Raw predicates stay bool. Unknown/infinite duration, zero loops and negative
fade direction are not automatically errors. MIX_GetTrackLoops reports zero for
stopped tracks and -1 for infinite looping. MIX_SetTrackLoops changes an active
track; starting playback resets it from properties. MIX_GetTrackFadeFrames is
negative during fade-out. MIX_StopTrack takes **sample frames**, while
MIX_StopAllTracks/MIX_StopTag take **milliseconds**. Do not infer errors from a
stale SDL_GetError after a successful call.

## Callbacks and threading

The five raw callback setters accept native C function addresses and native
userdata, never a daScript block/Func. Device mixing can invoke callbacks from an
audio thread. Do not access a script Context or movable script memory there.
Code and userdata must outlive registration and any in-flight callback; unregister
while the owner is alive before freeing them. The positive native fixture uses an
offline mixer, whose callback execution is synchronous with MIX_Generate. It does
not validate arbitrary application worker synchronization. Completion is exposed
through existing raw predicates/callbacks, without script-thread subscriptions.

## Example and validation

[Example 07](../examples/libraries/07_mixer.das) plays a short two-note chord with
two tracks, sdl_scope/sdl_use and sdl_try. Normal launch uses the default output;
CTest uses SDL_AUDIODRIVER=dummy. No microphone or remote audio is used.
`assets/mixer-tone.wav` is a generated 0.1-second 440 Hz PCM16 mono fixture.

[Script tests](../tests/mixer.das) contain direct calls to all 94 exports: offline
PCM sum/silence/copy checks, tags/groups, pause/resume, loop/fade/seek, formats,
spatial parameters, file/raw/NoCopy/IO loading, standalone decoding/EOF and
Result scopes. Null callback registrations run in script; the
[native fixture](../tests/mixer_native.cpp) verifies all five real callback
addresses, PCM output, retained audio and exact transferred/borrowed IO closure.
[Coverage gate](../tests/test_mixer_coverage.py) compares raw test sites with the
snapshot; it does not substitute for runtime assertions.

Windows x64 validation (2026-09-26):

- Main optional-library/GPU-image selection: 24/24 passed across the main run
  and targeted generator-gate rerun after fixing Python lookup in CMake.
- Mixer example and full raw test: legacy/CppGenBind/AOT 6/6, no AOT fallback.
- Mixer-only consumer (other optional libraries OFF): built with generators and
  LLVM/Clang/Python discovery disabled; example, raw tests and core version/events
  test passed. Desktop generator configuration was restored afterwards.
- Mixer snapshots and unchanged core CppGenBind snapshots are reproducible;
  public GPU boundary, documentation links and whitespace checks passed.

Web/shared linking, physical speakers, codec breadth and script callback delivery
remain unverified/follow-ups. Dummy completion is not proof of physical playback.
