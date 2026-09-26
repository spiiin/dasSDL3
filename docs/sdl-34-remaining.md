# Remaining SDL 3.4 additions

Thirteen additional functions complete the **37 function additions identified in
our SDL 3.2.18 -> 3.4.16 Windows census**. This is not full SDL library/platform coverage.
Audio is now 58/58, Events 20/20, Mouse 24/24, HIDAPI 23/23 and Pen 1/1 raw.
Video is 94/114 (20 GL/EGL functions remain in P8); CPUInfo is 1/19.

The two generators retain SDL signatures. SDL_ProgressState, SDL_PenDeviceType,
SDL_CursorFrameInfo, SDL_WINDOW_FILL_DOCUMENT and the string property name
SDL_PROP_HIDAPI_LIBUSB_DEVICE_HANDLE_POINTER are exposed. CppGenBind now handles
selected `const char *` macro constants through native C++ type checking; their
values are covered by pinned-header hashes and baseline/CppGenBind metadata parity.
This does not automatically export every hint/property macro.

Import `dassdl3/sdl3_remaining_34_boost` for the following thin conveniences.

## Windows, input and diagnostics

- Progress setters return Result<Unit>; state/value getters return values in Result.
  SDL clamps finite values to [0,1]. A native setter can update cached state before
  a platform backend reports failure; wrappers do not promise rollback or visibility
  of the taskbar indicator. Calls and returned state are tested, not OS screenshots.
- `set_window_fill_document` follows SDL; on the pinned Windows backend this is a
  successful no-op. It does not implement desktop fullscreen. Browser behavior is
  a separate web-profile task (these declarations are added to desktop only).
- `with_animated_cursor(frames,x,y)` lends a cursor and destroys it after Result
  body completion, including an early Err. Frames are borrowed only during creation;
  SDL creates its own platform cursor images. Empty arrays are rejected before SDL
  (the native implementation inspects frames[0] before checking frame_count).
  SDL can fall back to a static cursor on unsupported platforms. The scope does not
  select or restore a cursor; manage SDL_SetCursor explicitly. Normal native lifetime
  and main-thread rules apply. Displayed animation timing is not verified.
- `event_description(raw_event)` returns a copied English logging string. It is not
  a stable serialization format and must not be parsed as a protocol. Raw
  SDL_GetEventDescription uses snprintf-like length/capacity rules; its writable
  char buffer must really have the requested capacity. Prefer the copy adapter to
  passing script string literals as output storage. Do not mutate the event or its
  borrowed string payload concurrently with the two-pass copy.
- `pen_device_type` treats INVALID as Err; UNKNOWN is a successful device type.
- `hid_properties` returns a borrowed SDL_PropertiesID. Do not destroy that group;
  it belongs to the open HID device. The libusb handle property need not exist on
  every backend. Tests use the invalid-device path, not fabricated device pointers.
- SDL_GetSystemPageSize is directly available; no extra wrapper is necessary.

## Planar audio

`put_audio_planar(stream, samples, channels, frames)` accepts `array<float>` for
native SDL_AUDIO_F32 or `array<uint8>` containing the stream's PCM representation.
Data is **channel-major**, for example two stereo frames are `[L0,L1,R0,R1]` before
SDL interleaves them. `frames` counts samples per channel, not bytes.

The adapter locks the stream across format lookup, size validation and copying.
Counts must be nonnegative, storage must exactly match channels * frames * sample
size, and the interleaved byte count must fit Sint32. Format endianness follows SDL;
the byte overload performs no implicit conversion. F32 overloads reject other input
formats. No pointer to a script array survives the call.

Fewer channels produce silence in the missing output channels; extra channels are
ignored by SDL. Zero supplied channels can queue silence. U8 silence is 128, not
zero. A zero-frame input succeeds without queueing. Raw planar API also supports
individual null plane pointers and count=-1; the bounded array convenience uses
explicit counts and contiguous planes. Use encoded silence for interior channels.

Pinned SDL defect: the mono fast path ignores num_channels and forwards plane[0]
to SDL_PutAudioStreamData. A null/missing mono plane therefore fails instead of
supplying silence. The array adapter supplies a temporary correctly encoded mono
silence plane for this case; SDL copies it before return. Raw API stays unchanged.
Regression tests cover the raw failure and adapter output for U8 and F32.

## Native retained callbacks and no-copy data

SDL_PutAudioStreamDataNoCopy and SDL_SetRelativeMouseTransform accept **native C
function addresses**, never arbitrary daScript Func/Block values. The AOT address
casts follow the existing audio/event callback convention.

No-copy storage and callback userdata must remain valid until the completion
callback fires, which may happen on a worker/audio thread. The callback runs with
the stream lock held for queued data and fires when data is released by consumption,
Clear or Destroy. **Zero-length submit is different in the pinned source:** its
callback runs immediately in the submitting thread, before the call returns,
without this function acquiring the stream lock. A failed submit leaves the caller responsible for its buffer. There is
no automatic pointer adoption, script-array retention or script Context bridge.
For ordinary script data use the copied put_audio/put_audio_planar helpers.

Pinned SDL nuance: reading exactly the last requested bytes can leave a flushed,
empty track until a subsequent read removes it. Consequently zero queued/available
bytes does **not** authorize freeing a no-copy buffer; wait for completion. The test
reads through the empty tail on a native worker, and separately checks Clear and
Destroy, each with exactly one native callback and SDL_malloc/SDL_free ownership.

Mouse transform is process-global. Its callback can run away from the event-loop
thread (potentially at realtime priority), must remain short and must not access an unprotected script
Context. Registration must occur outside relative mode. Disable relative mode and
unregister before releasing userdata; synchronize any in-flight native callback.
The test registers/removes a native callback without synthesizing OS motion. It
makes no claim of end-to-end physical mouse transformation. No script scope with
unsafe retained captures has been introduced.

## Examples and tests

[Example 87](../examples/87_window_progress.das) uses window progress and a Renderer
progress bar, with sdl_scope/sdl_use/sdl_try and copied event descriptions.

- [Window/input test](../tests/sdl34_remaining.das): progress state/clamping/errors,
  cursor frame lifetime and early Err, native mouse callback registration/removal,
  copied descriptions, page size, HID/pen invalid-device paths.
- [Audio test](../tests/sdl34_audio.das): direct raw planar call, F32/S16/U8 arrays,
  independent interleaved values, missing/surplus channels, source mutation after
  copying, overflow/format rejection, native no-copy read/Clear/Destroy/failure.
- [Coverage gate](../tests/test_remaining34_coverage.py): 13 direct raw call sites.
  Runtime tests, rather than this text check, establish behavior.

Physical HID/pen devices, actual mouse-transform delivery, visual taskbar/cursor
animation and web/other-OS behavior remain outside this Windows validation.

## Validation (2026-09-26)

Windows targeted and affected checks passed (21/21), followed by 5/5 checks
after the final edge-case additions. Baseline, CppGenBind, strict AOT (fallback
disabled) and metadata parity passed 10/10. The external consumer built with
companion modules and generator/LLVM discovery disabled; example 87, planar
audio/public API smoke, existing binding checks and the public API boundary passed.
Both binding snapshots were regenerated. This was targeted validation, not a
full project regression or a hardware/browser run.
