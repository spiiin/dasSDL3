# Texture creation and state

Ten new generated functions: SDL_CreateTexture, SDL_CreateTextureWithProperties,
SDL_GetTextureProperties, SDL_GetRendererFromTexture, SDL_SetTextureColorModFloat,
SDL_GetTextureColorModFloat, SDL_SetTextureAlphaModFloat, SDL_GetTextureAlphaModFloat,
SDL_SetTextureScaleMode and SDL_GetTextureScaleMode. SDL_TextureAccess and
SDL_ScaleMode expose all values in pinned SDL 3.2.18, including invalid scale mode.
CreateTexture moves from partial adapted coverage to a general raw declaration.

`with_texture(renderer,format,access,w,h)` and `with_texture_properties(renderer,props)`
release only the newly created texture, using defer after successful acquisition.
The renderer must outlive the texture; blocks must not destroy/retain it or destroy
the renderer. A target must be deselected before its texture is destroyed. Creation
properties remain caller-owned, while GetTextureProperties and GetRendererFromTexture
return borrowed objects: do not destroy them. No ownership registry or error bridge.
Early block return cleans up; application panic is not covered by pinned defer.

Float/enum output adapters use explicit scalar references and preserve SDL's bool,
errors and default outputs on failure. Modulation remains native SDL behavior;
backend/format/HDR capabilities and valid values remain caller responsibilities.
The general raw creator does not expand upload_rgba8: that existing adapter still
accepts only RGBA32 streaming textures and checked byte arrays. Static texture updates, byte modulation, blend modes and lock scopes are now
available in [texture transfer](texture-transfer.md). YUV/NV whole-texture transfer is in [renderer YUV/blend](renderer-yuv-blend.md).

[Example 60](../examples/60_texture_state.das) uploads a small checker, selects
nearest sampling and applies color/alpha modulation through direct SDL calls.
[Tests](../tests/texture_state.das) execute every new raw function, all access modes,
property creation, borrowed identity, output references, early return and failed
acquisition. Full-image software pixels check color/alpha modulation (tolerance of two channel values for rounding); nearest/linear mode selection is queried, not a full filtering
quality or HDR conformance test. No cross-backend or all-format claim.

Local Windows x64 validation: main suite 136/136, including D3D12 raw execution;
package test/example in baseline, CppGenBind and AOT plus metadata 7/7;
generation/inventory/boundary gates 6/6 and standalone clangbind 4/4.
A consumer with LLVM/Clang/Python package discovery disabled built and ran the
fixture-free test, example and API boundary check. Full AOT runner rebuilt;
unrelated GPU parity runtime cases were not rerun. Task-local logs:
`work/texture-state-*.log` (not repo artifacts).
