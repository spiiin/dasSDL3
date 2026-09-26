# Complete native Surface and Pixels function declarations

All active Surface and Pixels functions in the pinned header profile are generated.
This is declaration coverage, not exhaustive format/backend/error-path coverage.
The combined tests explicitly call all 69 native Surface/Pixels functions. Common ref/array adapters and
small defer scopes accompany the raw functions; no registry or exception bridge.

## Ownership and pointers

CreatePalette returns an owned reference. CreateSurfacePalette/GetSurfacePalette
return a palette borrowed from the surface; do not destroy that borrowed reference.
SetSurfacePalette retains its own reference, so a separately created palette may be
released after assignment. Palette replacement invalidates old borrowed pointers.
AddSurfaceAlternateImage retains the image; release the caller's reference normally.
GetSurfaceImages allocates an SDL_free-owned pointer array, including the base surface
and a NULL terminator. Its elements are borrowed. The copy adapter frees only the
array; copied elements remain invalidatable by removing images/destroying the parent.
Do not create alternate-image reference cycles.

CreateSurfaceFrom borrows caller-owned storage. Keep its size, address and lifetime
stable until after DestroySurface, including through locks. LockSurface/UnlockSurface
are raw; the defer scope only handles unlocking. No general safe array-backed surface
scope is claimed. Never resize external arrays while the surface or IO stream uses them.
Duplicate/Scale/Convert return owned surfaces, with matching deferred cleanup helpers.
SDL_GetPixelFormatDetails returns borrowed immutable cached data; a copy adapter is
provided. SDL_GetPixelFormatName is a static borrowed string. Palette/details pointers
passed to Map/Get operations must match the pixel format and remain valid.

## Bounds and formats

Unchecked blits require non-null, already clipped rectangles within live unlocked
surfaces; they remain raw, without misleading checked aliases. Ref adapters for normal
blits retain SDL clipping, colorspace and blending behavior. The SDL_Color record and
SDL_PixelFormatDetails fields are available; internal palette/reference counts stay opaque.
Byte read adapters use native Uint8 temporaries and uint output references.
Packed byte-array conversion/premultiply adapters require positive dimensions,
non-FourCC formats with at least 8 bits/pixel, valid pitch and pitch*height bytes.
Other layouts, including planar formats, remain available through raw SDL. Avoid
partial overlaps; follow SDL's operation-specific in-place rules.

## BMP IO

Minimal IOFromMem/IOFromConstMem/SeekIO/CloseIO declarations support BMP streams.
The arrays are borrowed until the stream is closed. LoadBMP_IO/SaveBMP_IO with
closeio=true consume the stream even on failure; never close it a second time.
File tests create a uniquely named BMP and remove it via SDL_RemovePath.

Tests: tests/surface_pixels.das and tests/surface_state.das; examples 65 and 66.
The combined tests cover RGBA32/BGRA32/RGB24, INDEX8 palettes, RGBA128_FLOAT
colorspace conversion, nearest scaling, clipped/tiled/9-grid copies, padded buffers,
linear and sRGB premultiplication, and BMP file/memory round trips (including closeio
success and failure). They are not an exhaustive matrix of every pixel format,
filter, colorspace, HDR property or platform. Pixel-format helper macros are not
included in the function-coverage count.
