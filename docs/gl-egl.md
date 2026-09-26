# GL / EGL integration

Pinned SDL 3.4.16, Windows x64/MSVC. All twenty GL/EGL declarations from
SDL_video.h are generated. SDL_GLAttr and eleven profile/flag/release/reset
constants are exposed. SDL_GLContext is represented as SDL_GLContextState?;
EGL display/config/surface and native function addresses are void pointers.
This package controls SDL contexts; it does not add another OpenGL binding.
Use the existing daScript OpenGL module for rendering (as in examples/web/opengl).
The current desktop core runner does not automatically register that module.

## Lifetime and results

`require dassdl3/sdl3_gl_egl` provides Result factories/status wrappers, returned
attribute/swap queries, and defer scopes. A GL-capable SDL window must outlive its
context. Initialize video first; configure attributes before creating the window.
Call these operations on the main thread and respect GL current-context rules.

- `create_gl_context(window)` creates and selects a context. `destroy_gl_context`
  clears the passed handle only on success; other pointer aliases remain aliases.
- `with_gl_context(window)` lends a context to a Result-returning block, then
  destroys it. It does not restore an earlier current context. The callback must
  not destroy the context/window, leak the pointer or release it on another thread.
- `with_gl_current(window,context)` selects a borrowed pair and restores the
  previous pair after the block, including Err/early return. All pairs must remain
  alive; this scope owns neither window nor context.
- Both scopes preserve the body's error if cleanup also fails; otherwise cleanup
  failure becomes Err. They accept copyable and move-only Result payloads.
  They do not promise cleanup after arbitrary application panic.
- `with_gl_library(path)` owns one SDL load reference and unloads in defer.
  Empty path explicitly calls SDL_GL_LoadLibrary(NULL), selecting SDL's default.
  Nest windows and contexts inside this scope. Raw string calls keep native
  semantics: an empty daScript string is not guaranteed to be a C NULL pointer.
- `gl_attribute` and `gl_swap_interval` return Result<int>. A supported value of
  zero is success. `SDL_GL_ExtensionSupported` remains a bool predicate; false
  plus a stale SDL error string must not be converted into Err.
- Current GL context/window getters remain borrowed raw nullable values. EGL
  handles are also borrowed and backend-specific, never freed with SDL_free.

## Native-only interop

SDL_GL_GetProcAddress and SDL_EGL_GetProcAddress expose C addresses, not daScript
functions. Cast/invoke only with the exact native ABI. Non-null does not prove
extension support. On Windows, resolve GL addresses per context and do not retain
addresses past that context/library lifetime. See [SDL guidance](https://wiki.libsdl.org/SDL3/SDL_GL_GetProcAddress).

SDL_EGL_SetAttributeCallbacks accepts native addresses and userdata only. SDL
retains them for later EGL creation; their code/data must survive until replacement
or SDL_GL_ResetAttributes. Returned attribute lists must be SDL_malloc-allocated,
EGL_NONE-terminated, and are freed by SDL. No script callback/context bridge or
borrowed script arrays. NULL callback arguments unregister; ResetAttributes also
clears callbacks. See [SDL contract](https://wiki.libsdl.org/SDL3/SDL_EGL_SetAttributeCallbacks).

Raw SDL_EGL_GetWindowSurface has no general window validation before dispatch in
the pinned source. With a live EGL backend pass a valid EGL window. Tests call NULL
only with no EGL backend, where SDL returns before window dispatch.

## Checks

`tests/gl_egl.das` executes all twenty raw APIs using the dummy video backend:
attribute state, unavailable GL/EGL errors, NULL callbacks and no-current state.
`tests/gl_context.das` requests real desktop GL 2.1: library reference pairing,
two contexts, switching/restoration, early Err and moved array Result cleanup,
and RGB pixel readback via addresses obtained by script calls. The native fixture
only executes GL drawing/readback; SDL operations under test remain in daScript.
`examples/89_gl_context.das` is a noninteractive hidden-window context query example.

Live EGL success and callback invocation require an EGL backend and are not
claimed by dummy failures or desktop WGL. These tests do not establish Linux,
macOS, web or cross-driver behavior. Existing web bindings remain unchanged.

## Local results (2026-09-26)

- Main GL package and snapshot/inventory/contract gates: 6/6.
- Baseline / CppGenBind / strict AOT plus metadata: 10/10.
- Installed core SDK, separate consumer with no source-tree dependency: 6/6
  (real context and dummy contracts in interpreter/AOT, plus no-fallback guards).
- Python baseline regeneration check and documentation links: passed.

Core census: 1025 generated, 13 adapted, 225 pending out of 1263 active Windows
functions. Video: 114 generated, zero pending. This is declaration coverage;
platform/runtime limitations above remain part of the contract.
