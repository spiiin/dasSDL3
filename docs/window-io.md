# Fullscreen, window surfaces and remaining window operations

Pinned SDL 3.2.18, Windows x64/MSVC. Adds 25 generated Video functions and three
Surface functions (CreateSurface, FillSurfaceRect, MapSurfaceRGBA). Video now has
88/109 generated functions; its remaining 21 are GL/EGL and SetWindowHitTest.
SDL_FlashOperation and the two surface-vsync constants are generated.

## Surface ownership and pixels

SDL_GetWindowSurface returns a borrowed surface. Do not call SDL_DestroySurface
for it. DestroyWindowSurface or window destruction releases it; resizing
invalidates it, so reacquire after resize and never use the old pointer again.
Do not mix a window surface with your renderer/GPU/3D API on the same window.

with_surface owns only a standalone SDL_CreateSurface allocation and destroys it
via defer after normal/early return. It never wraps a borrowed window surface.
The block must not destroy/retain that surface past its scope. Panic cleanup is
not guaranteed by the pinned runtime. All window calls retain SDL main-thread
requirements and native return values; no registry or exception interception.

SDL_FillSurfaceAll supplies a native null rectangle for a full-surface fill;
SDL_FillSurfaceRectRef and SDL_UpdateWindowSurfaceRectsArray borrow inputs only
for synchronous calls. Rect-count narrowing is bounded by INT_MAX byte capacity.
Empty update arrays are forwarded as native count zero; no fake success shortcut.
Colors are mapped through SDL_MapSurfaceRGBA for the surface's actual format.
Its byte-valued C arguments use daScript uint parameters (0..255).
SDL may update more pixels than the dirty rectangles requested.

## Modes, ICC and input

SDL_SetWindowFullscreenModeRef supplies a copied mode; the desktop-mode helper
passes native NULL. SDL_GetWindowFullscreenModeCopy copies public values and
clears the internal pointer. A false copy result means the raw getter returned
NULL: this includes the normal desktop/no-selected-mode case as well as errors.
It is not a distinct SDL error code. Mouse-rectangle copies use the same presence
contract and zero their output on NULL. ClearWindowMouseRect passes native NULL.

ICC copy owns the temporary SDL allocation, copies bytes into a daScript array,
then frees it with SDL_free. Failure clears the output. Missing ICC profiles are
normal platform-dependent failures; no fake profile is supplied. Native callers
of GetWindowICCProfile must free the returned allocation themselves. The byte
copy is size-bounded but does not parse or validate the ICC profile.
Pinned SDL_GetWindowICCProfile omits normal window validation: NULL can crash the
Windows backend, and uninitialized video can also dereference missing state.
The copy adapter rejects NULL cheaply before SDL; all non-null handles must still
be live and video initialized. Raw native calls retain these preconditions.

Keyboard/mouse grab requests do not imply active capture on an unfocused window.
SDL_GetGrabbedWindow and the grab getters report SDL's active state. Tests use
hidden, non-focusable windows and release requested grabs immediately. Screensaver
functions alter SDL's process state; tests restore the previous SDL enabled flag.

## Pinned shape discrepancy and test limits

SDL 3.2.18 documents NULL as removing the window shape, but its SDL_SetWindowShape
implementation calls SDL_ConvertSurface(NULL), fails and retains the previous
shape. The binding preserves this behavior; it does not patch SDL or manipulate
private properties. Valid shape data is copied by SDL and requires a transparent
window. Icon/shape input surfaces remain caller-owned.

[window_io.das](../tests/window_io.das) executes all 28 newly generated functions,
with CPU pixel/color assertions, dirty updates, resize/reacquire/destroy/recreate,
icon and shape input release, mode set/reset, mouse rectangle copies, grab state,
screensaver state and invalid arguments. ICC and vsync support are printed;
absence/unsupported paths are accepted and are not reported as positive coverage.

Fullscreen requests are made on a hidden window and cleared before presentation;
exclusive display switching is not tested. SystemMenu is tested only with invalid
input: opening its interactive menu is deliberately left for a manual test.
Flash uses CANCEL only; attention flashing and physical input capture are not
claimed as tested. Vsync timing, color management, visual shape rendering, other
OSes and all graphics backends are not certified by this test.

[Example 56](../examples/56_window_surface.das) fills a borrowed window surface
and updates it using only public helpers, without unsafe. Renderer/Surface API
coverage continues next; GL/EGL and retained hit-test callbacks remain separate.

## Local validation (Windows x64/MSVC, 2026-09-20)

- Main regression suite: 128/128.
- Package interpreter (baseline and CppGenBind), AOT and metadata: 7/7.
- Generation/freshness/inventory/boundary gates: 6/6; standalone clangbind: 4/4.
- Local ICC query succeeded; copied bytes matched the raw allocation byte for byte.
- Local surface VSync set/query both returned unsupported; positive support and
  synchronization timing are not claimed.
- No-LLVM consumer: build, full window_io test (exit 0), example 56 and public API
  boundary check passed.
- Documentation links and whitespace checks passed.

The full AOT runner was rebuilt. Runtime parity was executed for this package
and metadata; the entire GPU parity runtime suite was not repeated.
