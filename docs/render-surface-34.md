# SDL 3.4 Surface and Renderer

Pinned SDL 3.4.16 adds seven Surface and thirteen Render functions to the binding.
Surface is now **65/65 raw**. Render is **101 raw + 1 fixed-text adapter / 102**;
SDL_RenderDebugTextFormat remains intentionally adapted, not a script C-varargs bridge.
Both generators include SDL_TextureAddressMode, SDL_GPURenderState and all fields
of SDL_GPURenderStateCreateInfo. Raw signatures are unchanged.

Import `dassdl3/sdl3_render_surface_34_boost` for the thin Result/defer helpers.

## Images and renderer settings

- `with_png(path|io)` and `with_loaded_surface(path|io)` own the decoded surface.
  SDL_LoadSurface detects SDL-supported formats (BMP/PNG), not SDL_image codecs.
- `with_rotated_surface(source, angle)` owns a new surface; the source is borrowed.
- `save_png(surface, path|io)` returns Result<Unit>. Boost IO overloads **never close
  the caller's stream**. Raw `_IO` retains its original closeio argument, including
  close on failure according to SDL. Use caller-owned IO scopes for early returns.
- `default_texture_scale_mode(renderer)` returns the enum by value; changes affect
  textures created later, not already-created textures.
- `render_texture_address_mode(renderer)` returns `{u,v}`. Raw getters still use out
  pointers. Settings apply to Renderer texture addressing, not SDL_GPU samplers.
- `texture_palette(texture)` returns Result<Option<SDL_Palette?>>. None is normal
  for a valid non-indexed texture; an invalid texture is Err. This ambiguous SDL
  getter requires clearing SDL's error before the call. The returned palette is
  borrowed; don't destroy it or keep it beyond the texture's palette change/destruction.
  Use move_unwrap for the nested mutable-pointer Option in the pinned daScript.
  SDL_SetTexturePalette retains its own palette reference; changing palette colors
  affects textures using it. No palette copy/owner registry is introduced.
- `render_texture_9grid_tiled` borrows explicit source/destination rectangles for one
  synchronous call. Raw nullable rectangles retain SDL defaults.

## SDL GPU Renderer

This is SDL's own 2D renderer over SDL_GPU, not an additional rendering framework.
`with_gpu_renderer(device,window)` matches SDL_CreateGPURenderer/SDL_DestroyRenderer.
Either argument can be null: a null device creates a renderer-owned device; a null
window creates an offscreen renderer that needs a render-target texture.
SDL_GetGPURendererDevice returns a **borrowed** pointer. A supplied device/window
must outlive the renderer. Do not destroy a renderer-owned device yourself.

`with_gpu_render_state(renderer,shader,samplers,textures,buffers,props)` creates a
native SDL_GPURenderState. SDL copies the three descriptor arrays. The shader,
samplers, textures and buffers themselves remain borrowed and must outlive the
state and their queued rendering. Counts are derived from arrays, bounded to Sint32.
State resources must belong to the renderer's GPU device. Raw SDL does not provide
cross-device alias tracking; neither does this adapter.

Set the state explicitly with `set_gpu_render_state(renderer,state)`. The ownership
scope always resets the renderer's state to null before destruction, including a
body Err/early return. It **does not restore an earlier state**; don't use nested
scopes expecting restoration. Destroy the state before its renderer. The raw destroy
call does not clear a renderer's selected state in the pinned implementation.

`set_gpu_render_state_fragment_uniforms(state,slot,bytes|floats)` passes copied data.
Empty input and byte-count overflow are rejected. Layout, slot and packing must
match the shader; the float overload does not invent std140 padding or serialize
arbitrary structures. The test shader uses exactly one float4 (16 bytes).
No panic/catch bridges; application panic retains the existing defer limitation.

[Example 86](../examples/86_gpu_renderer.das) uses sdl_scope/sdl_use and a custom
fragment uniform to color an SDL_RenderFillRect. SPIR-V and DXIL are checked-in
assets compiled from the original `render_state.frag.hlsl`, using the pinned
shadercross CLI with `-s HLSL -t fragment -d SPIRV|DXIL`. No runtime shader compiler
or shadercross module is required by this example.

## Validation scope

[Surface/Render test](../tests/render_surface_34.das): PNG file/IO round-trip pixel
oracles, auto-detection, rotation orientation/dimensions, non-consuming streams,
move-only block result, early error, invalid inputs, enum getters, inherited scale
mode and tiled nine-grid pixels.

[GPU Renderer test](../tests/gpu_renderer_34.das): offscreen GPU renderer, all six
new GPU-renderer/state raw calls, state selection, copied and updated uniforms,
readback pixels, palette references, early-error scope cleanup and explicit device
ownership. Runs on Vulkan and D3D12. Descriptor arrays in this fixture are empty;
nonempty storage/sampler layouts, other hardware and Metal are not certified.
Generation, call-site coverage, baseline/CppGenBind/strict-AOT and a no-LLVM consumer
are the package gates. Test-call presence is not a replacement for runtime tests.

Local Windows x64/MSVC validation, 2026-09-26:

- Main new/affected Surface/Renderer/texture, macro/boundary and generation tests:
  **45/45 passed**. This is a targeted regression selection, not the full suite.
- Baseline and CppGenBind package runtime tests: **10/10 passed**, plus metadata
  parity. Strict AOT package tests: **5/5 passed**, fallback disabled. The dedicated
  AOT target includes the required shared boost modules as separate generated units.
- No-LLVM/libclang/Python-discovery consumer, all companion modules disabled:
  build, Surface test, GPU test/example on Vulkan and D3D12, public API boundary passed.
- Both saved binding generators are deterministic/current; inventory, all 20 direct
  raw test call sites, updated documentation links and diff whitespace checked.
- Developer configuration/dasClangBind restored after the consumer check.
