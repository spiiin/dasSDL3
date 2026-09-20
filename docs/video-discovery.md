# Video discovery and window queries

Pinned SDL 3.2.18, Windows x64/MSVC. First Video package: 31 generated functions
for video drivers, theme, displays, modes, display selection and window queries.
SDL_Point, the public SDL_DisplayMode fields, SDL_SystemTheme,
SDL_DisplayOrientation and SDL_PixelFormat are generated from pinned headers.
With the subsequent [window state package](window-state.md), Video now has
88/109 generated functions in the active Windows census.
This is not completion of SDL_video.h.

## Ownership and results

All display/window operations retain SDL's main-thread requirement. Driver
enumeration can run before SDL_Init; display/window queries require video init.
Raw SDL errors retain bool/null/zero. Boost returns Result values and copied
SdlError; wrappers never panic or catch exceptions.

SDL_GetDisplaysCopy / displays returns copied uint IDs. IDs identify currently
connected displays, not permanent monitors: hotplug can invalidate them.
SDL_GetWindowsCopy / windows copies pointer values and frees only the SDL list.
The windows are borrowed and must not be destroyed just to release the list.
Pointers become invalid when their windows are destroyed; there is no registry.

SDL_GetFullscreenDisplayModesCopy / display_modes copies mode values and frees
SDL's single list allocation with SDL_free. Desktop/current/closest copy/ref
adapters also return mode values. Their private internal pointer is cleared;
these are field snapshots, not ownership of backend mode data. The annotation
intentionally omits SDL_DisplayMode.internal. Raw native mode pointers retain
SDL lifetimes and must not be freed individually. Raw GetDisplays/GetWindows/
GetFullscreenDisplayModes lists must be freed once with the existing SDL_free.

Copy-array adapters replace the output, including clearing it on SDL failure.
Copied mode output is zeroed on failure. Copied names/titles/driver strings are
daScript strings; later title changes or SDL shutdown do not invalidate copies.
GetDisplayProperties and GetWindowProperties return borrowed property group IDs;
do not call DestroyProperties for these groups.

Bounds, usable bounds, point/rect selection and window position/size have ref
adapters. Boost queries offer value-returning Result overloads and explicit output references. Window units, pixel size,
pixel density and display scale are distinct SDL quantities; no extra DPI model
or coordinate conversion policy is introduced.

## Validation and remaining work

[video_discovery.das](../tests/video_discovery.das) calls all 31 new raw functions,
checks copied enumeration against raw counts, frees raw lists, reads real display
modes and creates a hidden 320x240 window. It verifies copied title lifetime,
borrowed window identity, list refresh after destruction and invalid-ID/null
failures. No fullscreen switch or desktop resolution change is performed.
[Example 54](../examples/54_video_discovery.das) uses only public, safe wrappers.

A desktop video backend with at least one display/mode is required for this test;
headless/dummy behavior, hotplug, unusual display topology and DPI transitions
are not certified by it. Orientation/theme may legitimately be unknown.

Window creation/state is covered in [window-state.md](window-state.md).
Fullscreen/ICC, surfaces and input grabs are covered in [window-io.md](window-io.md). GL/EGL integration,
platform property keys and companion libraries remain separate. Hit-test scopes are
covered in [callback contracts](rect-clipboard-hittest.md); GL/EGL is P8.

## Local validation (Windows x64/MSVC, 2026-09-20)

- Main regression suite: 124/124.
- Package interpreter (baseline and CppGenBind), AOT and metadata: 7/7.
- Generation/freshness/inventory/boundary gates: 6/6; standalone clangbind: 4/4.
- No-LLVM consumer: build, full video_discovery test, example 54 and public API
  boundary check passed.
- Documentation links and whitespace checks passed.

The full AOT runner was rebuilt. Runtime parity was executed for this package
and metadata; the entire GPU parity runtime suite was not repeated.
