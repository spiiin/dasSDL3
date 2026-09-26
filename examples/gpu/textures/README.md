# bgfx bump and HDR textures

Source files come from bgfx commit `7e3060ccb97959dcda3f091b96d82515197028e0`.
Exact URLs and input/output SHA-256 values are in `manifest.json`.

- `fieldstone-rgba.rgba8` and `fieldstone-n.rgba8`: 512x512 RGBA8, top-down,
  converted from the original 06-bump TGA source images (BGR24, bottom-up).
- `uffizi.rgba16f`: 512x512 RGBA16F little-endian, six consecutive cubemap faces
  (+X, -X, +Y, -Y, +Z, -Z), stripped from bgfx's runtime `uffizi.ktx` container.
  The Uffizi environment is the light-probe asset used by the original example.

Conversion is offline and reproducible using `tools/build_bgfx_next_assets.py`.
These are bundled example assets, not a general TGA/KTX loader or a new public
texture format. The runtime validates exact payload sizes before uploading.
