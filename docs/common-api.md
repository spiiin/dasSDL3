# Common API and display/render/pinch events

Pinned SDL 3.4.16, Windows x64/MSVC. Seven new generated functions: MessageBox
(two), OpenURL, GetPlatform, GetRevision, GUIDToString and StringToGUID.
Use `require dassdl3/sdl3_common_boost` for the thin Result/Option adapters.
Raw declarations retain SDL signatures and pointer preconditions.

## Common contracts

- `platform_name()` and `sdl_revision()` return SDL static strings.
- `guid_from_string()` preserves SDL's permissive parser: pairs up to 16 bytes,
  zero padding for short input, ignored trailing odd character, invalid hex digits
  converted to zero. It has no native error result. Empty script strings are
  normalized to an empty C string. `guid_string()` returns an owned copy.
- Raw `SDL_GUIDToString` requires genuinely writable memory and correct capacity;
  the script string parameter does not make a literal writable. Prefer `guid_string`.
- `open_url()` returns Result<Unit>; empty URLs fail before SDL. A successful call
  means the OS accepted the request, not that navigation completed. SDL may launch
  an associated application, not only a browser. Call only for intended user actions.
- `show_simple_message_box()` returns Result<Unit>. `show_message_box()` takes an
  array of SDL_MessageBoxButtonData and optionally a SDL_MessageBoxColorScheme,
  returning Result<Option<int>>. Closing without selection is None; a button is
  Some(buttonID). The adapter rejects button ID -1, reserved for closing.
- Dialog calls are synchronous; respect SDL main/parent-window thread requirements.
  The adapter copies button descriptors and normalizes empty labels. Text and colors
  are borrowed only during the call. No callback or retained script pointers.
  Failure captures SDL's error immediately; no panic or exception interception.

Example: [88_system_info.das](../examples/88_system_info.das) is noninteractive.

## Owned events

SdlEvent has 71 alternatives. Seven new alternatives cover fourteen native tags:
`display` preserves event_type, display_id, timestamp and int2 data for all eight
SDL display tags; three render alternatives preserve window_id and timestamp;
`pinch_begin`, `pinch_update`, `pinch_end` also preserve scale. Pinch scale is the
relative value delivered by SDL, not an accumulated gesture scale.
IDs are copied identifiers, not owned display/window resources. Readers check the
active union tag and clear output on mismatch. Unknown tags retain the existing
unknown-event behavior. Raw SDL_Event still contains borrowed union data.

## Validation and limits

Main new tests: 3/3. Existing owned-event regression: 6/6.
Baseline/CppGenBind/strict AOT and metadata: 10/10.
Tests cover GUID buffers/copies/permissive parsing, all fourteen event tags through
native fixtures and SDL queue decoding, mismatch clearing, MessageBox validation
and forced missing-driver failures, boost empty URL and native NULL URL failure.
A native fixture is necessary for OpenURL(NULL): an empty daScript string is not
reliably passed as C NULL. No valid URL is invoked by the final tests.
MessageBox failure tests explicitly select a nonexistent video driver before any
video initialization, preventing native dialog fallback in the pinned SDL source.
Interactive selection/close and real display, renderer-loss and pinch input remain
manual/platform checks; synthetic event success does not claim hardware coverage.

Installed core SDK: standalone example 88 passes interpreter, strict AOT and
no-fallback guard (3/3), without source-tree includes or LLVM. The Result module
explicitly enables RTTI for its ast_typedecl typemacro during standalone AOT;
the SDK generator now reports simulate-stage compilation errors.
Final generator freshness and inventory/contract gates pass (3/3); Result regression
passes. Developer ClangBind configuration has been restored.
