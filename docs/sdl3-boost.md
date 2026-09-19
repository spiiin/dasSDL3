# sdl3_boost: decisions and maintenance notes

The design references `bgfx-idioms.md` in this directory. That document contains
reusable idioms and pinned upstream source links; this one describes our layer.

- `require dassdl3/sdl3_boost` re-exports the raw `sdl3` API and adds checked
  script functions. The runner mounts the project's `dassdl3/` directory through
  FsFileAccess.addFsRoot, independently of the current working directory.
- GPU helpers are separate in `dassdl3/sdl3_gpu_boost`: device/window scopes,
  clear and vertex-ID triangle with checked pipeline IDs. Multiple scoped GPU
  devices and windows are supported. See `gpu-triangle.md`
  for trusted shader ABI, offline assets and backend/pixel-reference tests.
- `require dassdl3/sdl3_geometry_boost` adds initialized vertex values and checked
  vertex/index arrays. Vertex colors are float4 in 0..1; positions are pixels.
  See `geometry.md` for empty indexed draws, finite values and buffer lifetimes.
- `require dassdl3/sdl3_pixels_boost` adds copied RGBA8 arrays, streaming/target
  texture scopes, nested target restoration and owned readback scopes.
  See `pixels.md` for pitch/bounds/copy contracts and interpreter/AOT coverage.
- `require dassdl3/sdl3_audio_boost` adds audio and re-exports this base layer.
  See `audio.md` for WAV ownership, stream queues, array limits and testing.
  `with_sdl(flags)` supports audio-only or combined initialization; `with_sdl()`
  keeps its VIDEO default. Both use guarded block invocation and global SDL_Quit.
- The current safe_addr macro rejects reference arguments as "not a local value".
  Therefore synchronous SDL_PollEvent, SDL_PushEvent and SDL_RenderFillRect
  use small C++ reference adapters. Texture size and rectangle adapters follow
  the same rule. No native function may retain these
  addresses. Callers pass an event by mutable reference or a rectangle by
  const reference, without copying the union or taking an address in script.
  Neither the boost module nor the example needs an unsafe block.
- Creation and rendering helpers panic on failure, including SDL_GetError's
  message. The runner turns an uncaught panic into exit code 1.
- `create_window` defaults to a resizable window; `create_renderer` accepts an
  optional driver string (empty chooses the default).
- Rendering helpers take renderer first for `renderer |> clear()` syntax.
  Colors use uint4 RGBA with each component in 0..255; invalid input is rejected.
- Prefer gen2 implicit trailing blocks: `with_sdl() { ... }`,
  `with_window(...) $(window) { ... }`, and
  `window |> with_renderer() $(renderer) { ... }`. The final block argument
  needs no `<|`; a block without parameters also needs no `$()` marker.
  The example and lifetime tests pass with these forms on the pinned interpreter.
  This changes call syntax only; cleanup remains implemented by the helpers.
- Prefer nested with_sdl -> with_window -> with_renderer blocks. Each helper
  catches panic from its callback, copies and trims the exception message,
  destroys its resource and then propagates the panic. This preserves renderer
  -> window -> SDL_Quit order on normal block exit, early return and errors.
- Actual tests on the pinned interpreter showed that defer/finally is skipped
  on panic: the cleanup trace was 0 instead of 123. Defer worked for normal and
  early return. Therefore it is not sufficient for checked helpers that panic.
  Do not infer full exception cleanup from the BGFX examples or macro comments.
- Nested panic/recovery also exposes a block-argument restoration issue in
  Context::invoke / SimNode_TryCatch: an outer block can read stale arguments
  after a nested callback panics. `src/sdl3_scopes.h` wraps resource callbacks
  with runWithCatch, restores BlockArguments and abiThisBlockArg, then rethrows.
  Script scopes still own cleanup and error propagation. No upstream files are
  modified. Recheck this version-specific workaround when updating daScript.
- `with_bmp(path)` lends an opaque SDL_Surface. `create_texture(renderer, surface)`
  copies its pixels and leaves the surface owned by the caller. `load_texture`
  releases its temporary surface before returning the owned texture;
  `renderer |> with_texture(path) $(texture) { ... }` releases that texture on exit.
  Texture scopes must be nested inside the renderer scope. Rendering stays on
  the main thread. Raw pointers must not escape scopes or be manually destroyed.
- `texture_size` returns float2 through a checked output-reference adapter.
  `draw_texture(texture)` uses the whole source/current target; adding a dst
  rectangle scales the whole source; adding src and dst crops then scales.
  Rectangles use SDL_FRect pixel coordinates and are borrowed synchronously.
  Missing files and SDL failures panic; null handles are rejected. Null destroy
  remains a no-op. Stale handles, foreign-renderer textures and invalid input
  remain subject to SDL's contract; the layer does not track pointer ownership.
- Use one outer with_sdl session. The current wrapper calls global SDL_Quit;
  it is not a ref-counted nested SDL-subsystem owner. Window/renderer handles
  supplied to a block must not escape it or be manually destroyed within it.
- Native pointers still have manual ownership. Copies are aliases; there is no
  unique-owner type or automatic use-after-destroy protection. Null destruction
  is a no-op; destruction of a stale non-null handle is not supported.
- The one-argument `should_close` still means Quit or any Escape key down.
  The window overload also handles CloseRequested and filters window-specific
  events by window ID. `input_window_id` covers supported input and window events.
- Input readers and state adapters are in `src/sdl3_input.h`; see `input.md`
  for the API, main-thread contract and text lifetime. Readers check the union
  tag and copy typed snapshots; on mismatch they clear output and return false.
  UTF-8 input/composition strings are allocated in the daScript heap, never
  returned as borrowed SDL pointers. Decode raw text events before polling again.
- Scalar output parameters need explicit references in script wrappers:
  `var text : string&`, `var start : int&`, `var position : float2&`.
  Mutable value parameters would silently discard native output at return.
- `with_text_input` uses guarded no-argument block invocation and only stops
  input if it started the session. Nested scopes preserve the outer session,
  including on panic. Do not manually toggle text input within these scopes.
  State queries read physical state after polling; pushed events do not update it.
- `tests/boost.das` exercises normal return, early return, panic, failed renderer
  creation and invalid color input. It checks actual SDL window/renderer state
  before SDL_Quit, so the runner's final fallback cannot mask leaked resources.
  It also tests the by-reference event wrappers and rendering with a const rect.
- Texture tests observe SDL property cleanup callbacks before renderer teardown
  and compare rendered pixels for all three draw overloads. They cover normal
  exit, early return, panic, failed creation after surface acquisition, missing
  BMP and continued renderer use after recovery. Test-only helpers are compiled
  only with BUILD_TESTING=ON; they are not supported public bindings.
- Project CTests cover generated output, standalone daslang,
  raw bindings, boost example, boost lifetime tests, texture example and texture
  lifetime/pixel tests, input events/text lifetime tests and the input example.
  Audio tests cover PCM copies, conversion, queue bounds, resource cleanup and
  dummy-device playback; audible output on physical hardware is not verified.
  The 60-frame examples
  and the boost module contain no unsafe/address expressions. Standard library
  internals and the raw API are not claimed to be entirely unsafe-free.
- Keep the original raw binding tests. Do not relax language pointer checking
  or add a broad unsafe block to the example to make new signatures compile.

Build and test commands are in README.md. This file and AGENTS.md are the
persistent project context for future sessions; no global user settings or
personal skill installation is required.

GPU mesh scopes are in `dassdl3/sdl3_gpu_mesh_boost.das`; see `gpu-mesh.md` for
the fixed vertex/shader ABI and copied array contract. Multiple scoped devices
are supported; device-specific cleanup must preserve other devices' resources.
The former single-device restriction was traced to this machine's FPS Monitor
Vulkan layer. Diagnosis and opt-in per-process filtering: `gpu-multidevice.md`.
The indexed scope uses the same owned bundle with copied UINT32 indices;
`gpu-indexed-mesh.md` describes bounds, empty-array behavior and coverage.
`sdl3_gpu_transform_boost` adds a separate transform mesh scope and receiver-first
draw accepting translation/scale/angle. Native uniform rows have an explicit
32-byte std140 ABI; see `gpu-transform.md`. Do not pass plain shaders to this scope.
`sdl3_gpu_3d_boost` uses standard float4x4/math_boost camera helpers. Four columns
are copied to a 64-byte uniform; indexed position/color arrays are copied into
native vertex storage. Depth format selection, resize and failure contracts live
in `gpu-3d.md`. Keep the old textured/2D shader ABIs separate.
