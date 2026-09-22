# Texture byte state, updates and locks

Example 61 now uses a scoped RGBA32 pixel view and packed rows; see [pixel views](api-ergonomics.md#temporary-rgba32-pixels).

Ten generated functions: SDL_SetTextureColorMod, SDL_GetTextureColorMod,
SDL_SetTextureAlphaMod, SDL_GetTextureAlphaMod, SDL_SetTextureBlendMode,
SDL_GetTextureBlendMode, SDL_UpdateTexture, SDL_LockTexture, SDL_UnlockTexture,
SDL_LockTextureToSurface. All eight SDL_BLENDMODE constants are exposed as uint.
LockTexture and UnlockTexture move from adapted to raw coverage.

Byte setter scalar arguments use daScript uint (keep values in 0..255); output
reference adapters explicitly widen native Uint8 outputs into uint&, avoiding
narrow-reference ABI ambiguity. Blend mode also uses uint&. SDL bool/errors and
failure defaults remain intact; no panic or interception. Tests compare NONE and
BLEND pixels; other predefined modes and custom composition need further coverage.

`update_texture_rgba8` is a synchronous RGBA32 pointer/count adapter. It rejects
nonpositive/outside rectangles, non-RGBA32 formats, insufficient byte capacity,
short/negative pitch and overflowing byte layout. The first byte is the region's
first pixel; pitch includes optional row padding. The final row needs only its
pixel bytes. No input pointer is retained. General raw UpdateTexture retains
SDL's format/planar layout and pointer-capacity preconditions; YUV/NV whole-texture adapters are in [renderer YUV/blend](renderer-yuv-blend.md).

`with_texture_surface(texture,rect)` locks an in-bounds nonempty region and unlocks
with defer. Its temporary surface is borrowed and write-only: initialize the whole
region; do not read prior pixels, destroy/retain the surface, nest a second lock,
or render/destroy/unlock the texture inside the block. Texture/renderer must outlive
the block. The ref adapter rejects outside regions instead of native intersection.
Early return unlocks; application panic is not covered. Raw LockTexture pointers
are also write-only and invalid after unlock; respect returned pitch and region
capacity. SDL 3.2.18 raw LockTexture does not validate rectangle bounds.
No lock registry or automatic buffer ownership is introduced.

[Example 61](../examples/61_texture_transfer.das) initializes a mapped surface,
unlocks it, then draws with byte modulation and alpha blending without unsafe.
[Tests](../tests/texture_transfer.das) execute all ten raw functions, output refs,
static padded region updates, rejection cases, pointer/surface locks, early return
and CPU pixel checks. Local software pixels are not all-backend conformance.

Local Windows x64 validation: main suite 138/138; package test/example through
baseline, CppGenBind and AOT plus metadata 7/7; generation/inventory/boundary
gates 6/6 and standalone clangbind 4/4. Consumer with LLVM/Clang/Python package
discovery disabled built and ran the fixture-free test, example and API boundary
check. Full AOT runner rebuilt; unrelated GPU parity runtime cases were not rerun.
Task-local logs: `work/texture-transfer-*.log` (not repo artifacts).
