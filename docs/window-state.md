# Window creation, ownership and state

Pinned SDL 3.2.18, Windows x64/MSVC. This package adds 27 generated functions:
property/popup creation; size, position and constraints; borders, resizability,
always-on-top, visibility, raise/maximize/minimize/restore/sync; opacity;
parent/modal/focusability. With the [window IO package](window-io.md), Video now has 88/109 generated functions.
All SDL_WindowFlags and the constant undefined/centered positions are generated.
Parameterized position macros and string property-key constants remain pending.
Use literal SDL property names, as in example 55.

## Thin scopes and ownership

`sdl3_window_boost` re-exports video helpers and adds with_window_properties(props)
and with_popup_window(parent,x,y,w,h,flags). Both skip their block on a null
result and use defer after successful creation. Normal/early return destroys the
window. The properties group is borrowed and never destroyed by the window scope.
Use an outer with_sdl for subsystem ownership; window scopes do not balance
SDL implicit video initialization.
SDL reads/copies creation properties; changing the title property afterward does
not change the created window's title. A properties ID of zero is not treated as
an invalid argument by this wrapper: native SDL can use default properties.

SDL recursively destroys both popup and regular child windows when their parent
is destroyed. Nest child scopes inside the parent's scope. The callback must not
destroy its window or any ancestor before its scope exits; otherwise aliases and
pending cleanup become invalid. Do not add a second scoped owner to a borrowed
window. There is no registry, automatic stale-pointer check or exception bridge.
Application panic cleanup is not guaranteed by the pinned daScript runtime.

Popup flags must include TOOLTIP or POPUP_MENU. Popups cannot be reparented or
made modal. Regular modal windows must clear modal state before reparenting.
Avoid hierarchy cycles/sibling-as-parent cases: SDL documents undefined behavior.
These are SDL contracts, not an added ownership framework.

## State and outputs

All operations preserve SDL results and main-thread requirements. Query the
resulting geometry/state rather than assuming the window manager accepted every
request immediately. SDL_SyncWindow uses SDL's own backend synchronization; no
custom event loop, polling timeout or cached state is added.

Minimum/maximum/aspect scalar boost outputs are explicit references. Safe-area
and border-size ref adapters call SDL directly. Output values on failure retain
SDL semantics. DPI/pixel queries remain in sdl3_video_boost. Fullscreen, surfaces, ICC/icon/shape, grabs, flash/system menu and screensaver
are covered in [window-io.md](window-io.md). GL/EGL remains separate.

## Tests and example

[window_state.das](../tests/window_state.das) executes all 27 new raw functions.
It checks property snapshots, size constraints, safe area, raw/ref outputs,
flags/opacity, modal reparent rejection, failed acquisition skipping the block,
ordinary and early scope cleanup, and recursive parent destruction for both
popup and regular child windows. It verifies destruction by IDs instead of
passing freed pointers back to SDL. Final window enumeration must be empty.

Raise/maximize/minimize/restore requests are issued while the window is hidden;
the test checks acceptance, not visible animation or compositor completion.
Show/hide is exercised briefly on a non-focusable window. Tests use the local
Windows desktop; behavior on other window managers is not certified.

[Example 55](../examples/55_window_properties.das) creates a property-configured
hidden parent and a nested hidden tooltip, using public helpers without unsafe.

## Local validation (Windows x64/MSVC, 2026-09-20)

- Main regression suite: 126/126.
- Package interpreter (baseline and CppGenBind), AOT and metadata: 7/7.
- Generation/freshness/inventory/boundary gates: 6/6; standalone clangbind: 4/4.
- No-LLVM consumer: build, full window_state test, example 55 and public API
  boundary check passed.
- Documentation links and whitespace checks passed.

The full AOT runner was rebuilt. Runtime parity was executed for this package
and metadata; the entire GPU parity runtime suite was not repeated.
