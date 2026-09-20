# GPU packages 33–35: color targets, mipmaps and scaled blits

> Current error/lifetime contract: [error-handling.md](error-handling.md).
> SDL failures return values; scopes use defer. Earlier panic/protected-scope
> descriptions below are historical and no longer describe the public binding.

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
foreign/stale IDs, panic cleanup and ticket survival after source destruction.
Examples 33–35 demonstrate each package without a window. This does not verify
SRGB behavior, general float filtering, Linux/Metal or arbitrary shader rendering.

Combined verification on 2026-09-20:

- Main project: 118/118 CTest; parity/interpreter/strict AOT: 267/267.
- Standalone dasClangBind experiment: 4/4. Deterministic generated selection:
  60 functions, 10 records, 7 opaque types, 49 fields, 183 constants (2 new).
- Completed main/parity logs contain no VUID, Validation Error or D3D12 ERROR.
  The existing FPS Monitor layer filter remained process-local.
- GPU inventory: 7 generated / 57 adapted / 28 pending; total SDL API:
  60 generated / 66 adapted / 1100 pending. Adapted contracts remain partial.
- Examples 33–35 passed on both backends in the LLVM-free consumer build with
  generators and Clang/LLVM/Python package discovery disabled. build.ninja has
  no libclang/libLLVM or binding-generator commands.
- Developer generator configuration restored; final snapshot freshness,
  inventory and Clang preflight checks: 5/5 passed.
