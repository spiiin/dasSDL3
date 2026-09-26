# GPU packages 33–35: color targets, mipmaps and scaled blits

Pinned SDL 3.2.18. Script module: `sdl3_gpu_image_boost`; native adapter:
`src/sdl3_gpu_image.h`. These are image-processing commands with CPU readback,
not a general render-pass or material/pipeline API.

## 33: initialized color-target textures

`with_gpu_color_target_texture(width,height,layers,levels,format)` owns a checked
texture ID in the existing transfer registry. It accepts RGBA8/BGRA8 UNORM,
2D/2D_ARRAY and sample count 1, with SAMPLER|COLOR_TARGET usage. SDL capability
support is checked before allocation. Existing size/64 MiB total footprint,
zero initialization, mip/layer, transfer, scope cleanup and owner checks apply.
The original transfer factories continue to create SAMPLER-only resources.
Color-target usage is stored per resource and checked before writes via blit.
SRGB, float/integer/BC/depth targets, MSAA and arbitrary usage masks are not
exposed by this factory; their existing format queries are unchanged.

## 34: mip generation

`device |> gpu_generate_mipmaps(texture)` requires a target from package 33,
at least two levels, and valid base data in every layer. It calls SDL's mip
generator for every layer and all allocated levels after mip 0. Base pixels
are preserved; lower levels are overwritten and can be regenerated after edits.
A failed submit invalidates lower levels; success does not imply CPU completion.
Use readback tickets/fences before accessing results on the CPU.

## 35: scaled/cropped blit

`gpu_blit_texture(device,src,src_sub,src_rect,dst,dst_sub,dst_rect,filter_mode)`
uses `uint2(mip,layer)` and `uint4(x,y,width,height)` with nonempty bounded
regions. The default filter is SDL_GPU_FILTER_NEAREST; LINEAR is also exposed.
Source and destination must have exactly matching RGBA8/BGRA8 UNORM formats,
be distinct live resources of the same device, and have valid selected data.
The source can be an existing sampler texture; the destination must have
COLOR_TARGET usage. No format conversion, flips, same-resource blits or cycling
are exposed. LOAD preserves pixels outside the destination region. Nonselected
mips/layers are unchanged. A failed submit invalidates the destination subresource.

Both operations acquire and submit a native command without an enclosing copy
or render pass: SDL performs its own work. No script callback executes while
recording. Existing main-thread/scoped-device rules and SDL deferred resource
release apply. No new raw command/pass pointer reaches the script.

## Tests

`tests/gpu_image.das` uses independent CPU byte references for both formats:
4x4 gradients, 2x2/1x1 averaged mip levels (one-byte UNORM tolerance), preserved
base levels, two layers, regeneration, constant odd 7x5 mip chains, cropped
nearest enlargement (exact bytes), linear downsampling into a mip, and sentinel
pixels outside the blit, and selecting a cubemap source face. It checks invalid bounds/filter/usage, mismatched format,
foreign/stale IDs, early-return cleanup and ticket survival after source destruction.
Examples 33–35 demonstrate each package without a window. This does not verify
SRGB behavior, general float filtering, Linux/Metal or arbitrary shader rendering.

Latest combined verification: [gpu raw tests](gpu-raw-tests.md).
Current function census: [api-coverage.md](api-coverage.md).
This page describes the checked subset. Full native pointers/arrays and scopes
are documented in [gpu-native-boost.md](gpu-native-boost.md); IDs and native
handles are separate. Other platforms and all hardware formats are not certified.
