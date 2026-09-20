# Surface state

The package exposes native properties, colorspace, RLE, color key, color/alpha
modulation, blend mode and clip rectangle APIs (16 functions), plus SDL_Colorspace.
Small scalar/rectangle ref adapters preserve SDL return values; no panic or catches.
Byte outputs use native Uint8 temporaries copied to daScript uint references.

SDL_GetSurfaceProperties returns a borrowed ID owned by the surface. Do not destroy
it separately or retain it after surface destruction. Assigning a colorspace changes
metadata, not pixel values. HDR conversion is outside this package.
SDL_SurfaceHasRLE reports the requested RLE state; it does not prove compression
has already happened. Color keys are mapped pixel values, not portable RGBA integers.
Modulation and blending affect subsequent copies, not stored source pixels.
CreateTextureFromSurface captures current state; later surface changes do not update
an existing texture. The texture owns its copied pixels independently of the surface.

SetSurfaceClipRect returning false can mean an empty intersection, not an SDL error.
Empty clip dimensions may be negative; test w <= 0 or h <= 0, not equality to zero.
NULL resets the clip to the whole surface. Ref/reset adapters retain these semantics.
Mutations require caller synchronization. Existing with_surface uses deferred cleanup.

Tests: tests/surface_state.das. Public example: examples/65_surface_state.das.
Verification is combined with the remaining Surface/Pixels API in
[surface-pixels.md](surface-pixels.md), including blits, palettes, alternate images
and external storage.
